# Dockerizing Data Ingestion with Container Networking

We successfully dockerized the ingestion pipeline using container networking, which avoids password authentication issues and provides a cleaner setup for multi-container environments.

> 📚 **Learning Path**: This exercise shows running containers on the same network. While this is much better than host→container, manually starting each container is tedious. **Next**: Docker Compose will orchestrate all services automatically.

## The Problem: host.docker.internal Auth Failures

When running the ingester container from WSL using `host.docker.internal`:
```bash
docker run --rm taxi_ingest:v001 \
  --pg-host host.docker.internal \
  --pg-user root --pg-pass root \
  ...
```

You'd get `FATAL: password authentication failed for user "root"` even though credentials were correct. Why?

1. **Volume persistence issue**: If the Postgres volume already existed with a different initialization, new env vars don't override the stored password.
2. **Network boundary**: `host.docker.internal` requires crossing the WSL→Docker Desktop boundary, adding network/auth complexity.
3. **Port conflicts**: Multiple container starts on the same port created conflicts.

## The Solution: Container Networking

**Use Docker's internal network** to let containers communicate directly by hostname:
- Both containers run on the same custom network (`pg-network`).
- Postgres is named `pgdatabase`; ingester connects to it as `--pg-host=pgdatabase` (no `localhost` or `host.docker.internal` needed).
- Docker's internal DNS resolves `pgdatabase` to the container's IP.
- No port exposure, cleaner isolation, no password bridging complexity.

## Step-by-Step Setup

### 1. Clean up old containers/volumes
```bash
docker stop postgres_ny_taxi pgdatabase 2>/dev/null || true
docker rm postgres_ny_taxi pgdatabase 2>/dev/null || true
docker volume rm ny_taxi_postgres_data 2>/dev/null || true
```

### 2. Create the Docker network
```bash
docker network create pg-network
```

### 3. Run PostgreSQL on the network
```bash
docker run -d --name pgdatabase --network pg-network \
  -e POSTGRES_USER=root \
  -e POSTGRES_PASSWORD=root \
  -e POSTGRES_DB=ny_taxi \
  -v ny_taxi_postgres_data:/var/lib/postgresql \
  postgres:18
```

**Important notes:**
- `--name pgdatabase`: Container hostname for DNS resolution.
- `--network pg-network`: Attach to custom network.
- `-v ny_taxi_postgres_data:/var/lib/postgresql`: PostgreSQL 18 requires `/var/lib/postgresql`, not `/var/lib/postgresql/data`.
- No port mapping needed (containers on same network can reach each other internally).

Wait for init:
```bash
sleep 3
```

### 4. Build the ingestion image (once)
```bash
docker build -t taxi_ingest:v001 -f 01-docker-terraform/docker-sql/pipeline/Dockerfile .
```

### 5. Run the ingester on the same network
```bash
docker run -it --network=pg-network taxi_ingest:v001 \
  --pg-host=pgdatabase \
  --pg-user=root \
  --pg-pass=root \
  --pg-port=5432 \
  --pg-db=ny_taxi \
  --target-table=yellow_taxi_trips \
  --year=2021 --month=01 \
  --chunksize=100000
```

**Key differences from WSL approach:**
- `--pg-host=pgdatabase` (container name, not `host.docker.internal`)
- `--network=pg-network` (both containers on same network)
- No port binding needed (internal DNS handles routing)

## Why This Works (No Auth Issues)

1. **Fresh volume**: Cleaned up old data, so PostgreSQL initializes with `POSTGRES_PASSWORD=root` cleanly.
2. **Direct networking**: Both containers on `pg-network` → Docker DNS resolves `pgdatabase` directly.
3. **No boundary crossing**: No `host.docker.internal` bridging, no WSL←→Docker Desktop network complexity.
4. **Isolation**: Postgres runs as a named service; ingester connects by name; clean separation of concerns.

## The Real Problem: Stale Volume + Network Boundaries

Here's what was happening before (why it failed):

```
OLD APPROACH (Failed):
├─ WSL (uv run ingest_data.py)  → host.docker.internal:5432
└─ Docker Desktop
   ├─ postgres_ny_taxi (stale password from old init)
   └─ ny_taxi_postgres_data (volume with corrupted/old credentials)
```

**The password error root cause:**
- The volume `ny_taxi_postgres_data` persisted from earlier failed attempts.
- It was initialized with a different password (or PostgreSQL version conflict).
- When you restarted with `POSTGRES_PASSWORD=root`, the env var was **ignored** — PostgreSQL doesn't override an existing cluster's password.
- Ingester connected with `root:root`, but the stored password didn't match → `FATAL: password authentication failed`.

**The network solution:**

```
NEW APPROACH (Works):
pg-network (custom Docker bridge)
├─ postgres:18 (pgdatabase)
│  └─ Fresh volume: ny_taxi_postgres_data
│     └─ Initialized cleanly with POSTGRES_PASSWORD=root
│
└─ taxi_ingest:v001
   └─ Connects to pgdatabase:5432 (Docker DNS)
      No localhost confusion, no WSL boundary crossing
```

**Why pg-network fixed it:**
1. **Volume cleanup**: You ran `docker volume rm ny_taxi_postgres_data`, destroying the stale volume.
2. **Fresh init**: PostgreSQL 18 initialized from scratch, cleanly applying `POSTGRES_PASSWORD=root`.
3. **Direct DNS**: Both containers on `pg-network` → `pgdatabase` resolves to the Postgres container's internal IP instantly (no `host.docker.internal` bridge needed).
4. **No WSL boundary**: No crossing WSL→Docker Desktop boundary, so no auth/socket issues.

### Architecture Diagram

![Docker pg-network Architecture](images/networks.PNG)

The diagram above shows:
- **Left**: `postgres:18` container (named `pgdatabase`) on `pg-network`.
- **Right**: `taxi_ingest:v001` container running `ingest_data.py` on the same `pg-network`.
- **Connection**: Direct internal bridge (blue line) via Docker DNS; ingester resolves `pgdatabase` to Postgres's internal IP.
- **No exposure**: Port 5432 is internal to the network (no need to expose it to host).
- **Contrast**: The `localhost:5432` shown at bottom represents what **didn't work** — crossing WSL→Docker Desktop with a stale volume.

## Verification

After ingestion completes, verify data was written:

```bash
# Run psql inside the Postgres container (on the network)
docker exec -it pgdatabase psql -U root -d ny_taxi -c "SELECT COUNT(*) FROM yellow_taxi_trips;"
```

## Key Takeaway: Container Networking > host.docker.internal

For multi-container applications:
- **Use custom Docker networks** for clean, isolated service communication.
- **Avoid `host.docker.internal`** unless you need external (WSL/host) access.
- **Named containers** simplify configuration: just use the container name as hostname.
- **Volume paths matter**: PostgreSQL 18 uses `/var/lib/postgresql`, not `/var/lib/postgresql/data`.

---

## What's Next? Docker Compose 🚀

In this exercise, we manually:
1. Created a network: `docker network create pg-network`
2. Started PostgreSQL: `docker run --network=pg-network --name pgdatabase ...`
3. Started pgAdmin: `docker run --network=pg-network --name pgadmin ...` (from 07_pgadmin.md)
4. Started ingester: `docker run --network=pg-network taxi_ingest:v001 ...`

**This works, but it's repetitive!** Imagine doing this for 10+ services.

**Docker Compose solves this:**
```yaml
# docker-compose.yml
services:
  postgres:
    image: postgres:18
    environment:
      POSTGRES_USER: root
      POSTGRES_PASSWORD: root
      POSTGRES_DB: ny_taxi
    volumes:
      - ny_taxi_postgres_data:/var/lib/postgresql
    networks:
      - pg-network
  
  pgadmin:
    image: dpage/pgadmin4
    environment:
      PGADMIN_DEFAULT_EMAIL: admin@admin.com
      PGADMIN_DEFAULT_PASSWORD: root
    ports:
      - "8085:80"
    networks:
      - pg-network
  
  ingester:
    build: ./pipeline
    command: [
      "--pg-host=postgres",
      "--pg-user=root",
      "--pg-pass=root",
      "--pg-db=ny_taxi"
    ]
    networks:
      - pg-network
    depends_on:
      - postgres

networks:
  pg-network:
    driver: bridge

volumes:
  ny_taxi_postgres_data:
```

**Start everything with one command:**
```bash
docker-compose up
```

**Benefits:**
- 🎯 One file defines entire infrastructure
- 🔄 Start/stop all services together
- 📦 Automatic network creation
- 🔗 Built-in service dependencies (`depends_on`)
- 🛠️ Easy to version control and share

Docker Compose is the natural evolution from manually orchestrating containers!

## Understanding Docker DNS: localhost vs Container Names

This is the critical concept that makes container networking work:

**On a custom Docker network (`pg-network`):**
- `localhost` = **the container itself** (useless for reaching other containers)
- `pgdatabase` = **Docker's internal DNS resolves this to Postgres's internal IP**
- No `host.docker.internal` needed (that's WSL↔Docker Desktop bridging, not container↔container)

**Example connection strings:**

```python
# ✅ CORRECT: Use container name on the network
engine = create_engine("postgresql://root:root@pgdatabase:5432/ny_taxi")

# ❌ WRONG: localhost points to the ingester itself, not Postgres
engine = create_engine("postgresql://root:root@localhost:5432/ny_taxi")

# ❌ WRONG: host.docker.internal only for WSL→Docker Desktop, not container↔container
engine = create_engine("postgresql://root:root@host.docker.internal:5432/ny_taxi")
```

**How Docker DNS works:**
1. When ingester starts on `pg-network`, it joins that network.
2. Docker embeds a DNS server in the network.
3. When ingester tries to reach `pgdatabase:5432`, Docker DNS resolves `pgdatabase` to Postgres's internal IP (e.g., `172.20.0.2`).
4. Connection succeeds—no need for port exposure, no WSL boundaries.

**Summary of the three approaches:**

| Approach | Hostname | Use Case | Works? |
|----------|----------|----------|--------|
| Custom Network | `pgdatabase` | Container↔Container | ✅ Yes (best) |
| WSL→Docker Desktop | `host.docker.internal` | WSL script→Docker container | ⚠️ Yes (but auth issues from stale volumes) |
| Default Bridge | `localhost` | Within same container only | ❌ No (reaches itself, not other containers) |
