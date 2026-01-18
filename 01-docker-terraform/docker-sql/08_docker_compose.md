# Docker Compose for Multi-Container Setup

Docker Compose simplifies running multiple containers by defining everything in a single YAML file.

---

## docker-compose.yml

Create this file in the `docker-sql` directory:

```yaml
services:
  pgdatabase:
    image: postgres:18
    environment:
      POSTGRES_USER: "root"
      POSTGRES_PASSWORD: "root"
      POSTGRES_DB: "ny_taxi"
    volumes:
      - "ny_taxi_postgres_data:/var/lib/postgresql"
    ports:
      - "5432:5432"

  pgadmin:
    image: dpage/pgadmin4
    environment:
      PGADMIN_DEFAULT_EMAIL: "admin@admin.com"
      PGADMIN_DEFAULT_PASSWORD: "root"
    volumes:
      - "pgadmin_data:/var/lib/pgadmin"
    ports:
      - "8085:80"
    depends_on:
      - pgdatabase

volumes:
  ny_taxi_postgres_data:
  pgadmin_data:
```

---

## Start the Services

From the `docker-sql` directory:

```bash
docker compose up -d
```

**Flags:**
- `-d`: Run in detached mode (background)

**What happens:**
- Both containers start automatically
- A default network is created: `docker-sql_default`
- Named volumes are created if they don't exist
- Services can reach each other using service names as hostnames

---

## Understanding the Auto-Created Network

**Check the networks:**
```bash
docker network ls
```

You'll see a network called `docker-sql_default`.

**Network naming:**
- Docker Compose creates a default network named `<directory-name>_default`
- Since the YAML is in the `docker-sql` directory → `docker-sql_default`
- Both `pgdatabase` and `pgadmin` are on this network automatically

**Why no explicit network definition?**
- Docker Compose creates a default bridge network for you
- All services in the compose file join it automatically
- You can define custom networks if needed, but the default works perfectly

---

## Configure pgAdmin

### Access pgAdmin

1. **Open browser** → http://localhost:8085
2. **Login:**
   - Email: `admin@admin.com`
   - Password: `root`

### Register PostgreSQL Server

Since the `pgadmin_data` volume is fresh, you need to register the server:

3. **Right-click** `Servers` → `Register` → `Server`

4. **Configure:**
   
   **General tab:**
   - Name: `pg` (or any name you prefer)
   
   **Connection tab:**
   - Host name/address: `pgdatabase` *(service name from docker-compose.yml)*
   - Port: `5432`
   - Username: `root`
   - Password: `root`
   - Maintenance database: `postgres`

5. **Save**

> 💡 **Why reconfigure?** The `pgadmin_data` volume stores server connections, but since it's a fresh volume (or you recreated it), pgAdmin has no memory of the PostgreSQL server.

---

## Ingest Data

Run the ingestion script as a container on the **same network**:

```bash
docker run -it --network=docker-sql_default taxi_ingest:v001 \
  --pg-host=pgdatabase \
  --pg-user=root \
  --pg-pass=root \
  --pg-port=5432 \
  --pg-db=ny_taxi \
  --target-table=yellow_taxi_trips \
  --year=2021 --month=01 \
  --chunksize=100000
```

**Key points:**
- `--network=docker-sql_default`: Join the same network as PostgreSQL
- `--pg-host=pgdatabase`: Use the service name, not `localhost` or `host.docker.internal`
- The ingester container can now reach PostgreSQL via Docker DNS

---

## Verify Ingestion

**In pgAdmin:**
1. Navigate to: `Servers` → `pg` → `Databases` → `ny_taxi` → `Schemas` → `public` → `Tables`
2. Right-click `yellow_taxi_trips` → `View/Edit Data` → `First 100 Rows`

**Or via psql:**
```bash
docker exec -it pgdatabase psql -U root -d ny_taxi -c "SELECT COUNT(*) FROM yellow_taxi_trips;"
```

---

## Stop and Clean Up

**Stop services (keeps volumes):**
```bash
docker compose down
```

**Stop and remove volumes (clean slate):**
```bash
docker compose down -v
```

**View running services:**
```bash
docker compose ps
```

**View logs:**
```bash
docker compose logs pgdatabase
docker compose logs pgadmin
```

---

## Key Advantages of Docker Compose

| Manual Approach (06-07) | Docker Compose (08) |
|--------------------------|---------------------|
| Create network manually | Network auto-created |
| Start containers one-by-one | Start all with one command |
| Remember all flags/env vars | Defined in YAML file |
| Hard to share setup | Version-controlled YAML |
| No service dependencies | `depends_on` ensures order |

---

## Common Issues

**Issue: Network name doesn't match**
```bash
# Check actual network name
docker network ls | grep default

# It will be <directory-name>_default
# If you're in a different directory, the name changes!
```

**Issue: Port conflicts**
```bash
# Error: port 5432 already in use
# Stop existing PostgreSQL containers first:
docker ps
docker stop <container-id>
```

**Issue: Volumes from previous runs**
```bash
# If you have stale data, remove volumes:
docker compose down -v
docker compose up -d
```

---

## What's Missing? Ingestion in Compose

You could add the ingestion service to the compose file:

```yaml
services:
  pgdatabase:
    # ... existing config ...

  pgadmin:
    # ... existing config ...

  ingester:
    build: ./pipeline
    command: [
      "--pg-host=pgdatabase",
      "--pg-user=root",
      "--pg-pass=root",
      "--pg-db=ny_taxi",
      "--target-table=yellow_taxi_trips",
      "--year=2021",
      "--month=01"
    ]
    depends_on:
      - pgdatabase
```

**Why we don't (yet):**
- Ingestion is a one-time job, not a long-running service
- Running it manually gives you more control over parameters
- Later, we'll use orchestration tools like Airflow for scheduled jobs

---

## Architecture: Services vs Jobs

### What's in Docker Compose?

This setup manages **long-running services** (infrastructure):

```yaml
services:
  pgdatabase:      # 🔄 Always running
  pgadmin:         # 🔄 Always running
```

**Characteristics:**
- Start once with `docker compose up`
- Stay running indefinitely
- Infrastructure/foundational services
- Version-controlled in YAML

### What's NOT in Docker Compose?

The ingestion script runs **separately as a manual job**:

```bash
docker run -it --network=docker-sql_default taxi_ingest:v001 \
  --year=2021 --month=01
```

**Characteristics:**
- 🏃 One-time execution
- 📊 Different parameters each run
- 🎛️ Manual control over when/what to ingest
- 📁 Defined in separate Dockerfile

---

## Why Separate Ingestion from Compose?

### ❌ Don't Mix Long-Running Services with Batch Jobs

**If we added ingestion to docker-compose.yml:**

```yaml
services:
  pgdatabase: { ... }
  pgadmin: { ... }
  ingester:          # ← Batch job in compose?
    build: ./pipeline
    command: ["--year=2021", "--month=01"]
```

**Problems:**
- ⚠️ Ingestion runs automatically on `docker compose up` (unintended)
- ⚠️ Hard to change year/month without editing YAML
- ⚠️ If ingestion fails, restart affects entire stack
- ⚠️ Mixes different service types in one file

### ✅ Separation of Concerns

**Better approach:**
- **docker-compose.yml**: Infrastructure (PostgreSQL + pgAdmin)
- **Dockerfile + manual docker run**: Data pipelines (ingestion)

This keeps concerns separate:
- 🏗️ Infrastructure → Compose (long-running, stable)
- 🔄 Data pipelines → Manual/orchestrated (jobs, parameters, scheduling)

---

## The Evolution: From Manual to Orchestrated

### Stage 1: Development (This Exercise)
```
docker compose up          # Start DB + UI
docker run ... ingest      # Manual ingestion when needed
```
✅ Simple, flexible, good for learning

### Stage 2: Scheduled Jobs (Future: Airflow/Prefect)
```
docker-compose.yml:
  - pgdatabase
  - pgadmin
  
Airflow DAG:
  - Task 1: Ingest 2021-01
  - Task 2: Ingest 2021-02
  - Task 3: Data quality checks
```
✅ Automated, scheduled, observable

### Stage 3: Production (Kubernetes/Cloud)
```
Infrastructure:
  - Managed PostgreSQL (RDS/CloudSQL)
  - Managed pgAdmin alternative (DBeaver Cloud)

Orchestration:
  - Cloud Composer / Apache Airflow
  - Prefect Cloud / Dagster
  - Scheduled pipelines with retries
```
✅ Scalable, managed, enterprise-grade

---

## When to Include Services in Compose

**Include in docker-compose.yml if:**
- 🔄 Long-running (API, database, UI, message queue)
- 🏗️ Part of infrastructure setup
- 🚀 Starts automatically with `docker compose up`
- 🔗 Other services depend on it

**Run separately if:**
- 🏃 One-time or periodic jobs
- 📊 Different parameters per run
- 🎛️ Manual control needed
- ⏰ Will be orchestrated later (Airflow, etc.)

---

## Best Practices

1. **docker-compose.yml** = Infrastructure only
   - Databases
   - Web servers / APIs
   - Message queues
   - Monitoring tools

2. **Separate Dockerfiles** = Jobs/Pipelines
   - Data ingestion
   - Data transformation
   - ML model training
   - Batch processing

3. **Orchestration tools** = Scheduling
   - Airflow
   - Prefect
   - Temporal
   - Kubernetes CronJob