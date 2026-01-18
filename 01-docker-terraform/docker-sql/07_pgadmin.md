# pgAdmin Setup Guide

## Overview

**pgcli** is handy for quick queries, but **pgAdmin** is a more powerful web-based interface for complex database management. It provides a user-friendly UI to manage PostgreSQL databases visually.

> ⚠️ **Important**: Both pgAdmin and PostgreSQL containers need to be on the same Docker network to communicate with each other.

---

## Understanding Container Networking 🌐

### Why Same Network?

When containers are on the same Docker network, they can communicate using **container names as hostnames**. This is much cleaner than using `localhost` or `host.docker.internal`, especially on WSL.

**Container-to-container communication:**
```
pgAdmin container → pgdatabase:5432 → PostgreSQL container
✅ Simple, reliable, no WSL issues
```

**Why this is better than alternatives:**

| Approach | Issues |
|----------|--------|
| `localhost` | Each container has its own localhost - won't reach other containers |
| `host.docker.internal` | Designed for host→container, unreliable on WSL, crosses network boundaries |
| Container name (`pgdatabase`) | ✅ Clean, reliable, Docker DNS handles resolution automatically |

### The Three-Localhost Problem (WSL)

```
WSL localhost       ≠ Container localhost      ≠ Windows localhost
(Your terminal)       (Inside pgAdmin/Postgres)   (Windows host)
```

These are **three different network namespaces**! This is why:
- `localhost` doesn't work for container-to-container communication
- `host.docker.internal` is needed for WSL→Container but has auth issues
- Container names on the same network just work™

### How Docker DNS Works

1. Both containers join `pg-network`
2. Docker embeds a DNS server in the network
3. When pgAdmin tries to connect to `pgdatabase:5432`:
   - Docker DNS resolves `pgdatabase` → PostgreSQL's internal IP (e.g., `172.20.0.2`)
   - Connection succeeds instantly
4. No port exposure needed, no WSL boundaries to cross!

---

## Step 1: Create a Docker Network

To enable communication between containers, create a shared Docker network:

```bash
docker network create pg-network
```

**Useful network commands:**
```bash
docker network ls                      # List all networks
docker network rm pg-network           # Remove the network when done
docker network inspect pg-network      # View network details
```

---

## Step 2: Run PostgreSQL Container

```bash
docker run -it \
  -e POSTGRES_USER="root" \
  -e POSTGRES_PASSWORD="root" \
  -e POSTGRES_DB="ny_taxi" \
  -v ny_taxi_postgres_data:/var/lib/postgresql \
  -p 5432:5432 \
  --network=pg-network \
  --name pgdatabase \
  postgres:18
```

---

## Step 3: Run pgAdmin Container

```bash
docker run -it \
  -e PGADMIN_DEFAULT_EMAIL="admin@admin.com" \
  -e PGADMIN_DEFAULT_PASSWORD="root" \
  -v pgadmin_data:/var/lib/pgadmin \
  -p 8085:80 \
  --network=pg-network \
  --name pgadmin \
  dpage/pgadmin4
```

### Container Parameters Explained

| Parameter | Purpose |
|-----------|---------|
| `-e PGADMIN_DEFAULT_EMAIL` | Login email for pgAdmin web interface |
| `-e PGADMIN_DEFAULT_PASSWORD` | Login password for pgAdmin web interface |
| `-v pgadmin_data:/var/lib/pgadmin` | Persists pgAdmin settings, server connections, and preferences |
| `-p 8085:80` | Maps port 80 (pgAdmin default) to localhost port 8085 |
| `--network=pg-network` | Connects to the shared Docker network |
| `--name pgadmin` | Container name used for inter-container communication |

> 💡 **Key Concept**: The `--name` flags create hostnames that Docker DNS resolves automatically within the network. pgAdmin connects to `pgdatabase` (not `localhost` or `host.docker.internal`), and Docker routes the connection internally.

**Why no `-p 5432:5432` on PostgreSQL?**  
Port mapping is only needed when your **host machine** needs to access the container. Since pgAdmin runs as a container on the same network, it can reach PostgreSQL directly via Docker's internal networking—no port exposure required!

---

## Step 4: Connect pgAdmin to PostgreSQL

### Access pgAdmin

1. **Open your browser** → http://localhost:8085

2. **Login** with these credentials:
   - Email: `admin@admin.com`
   - Password: `root`

### Register the PostgreSQL Server

3. **Right-click** `Servers` in the left panel → `Register` → `Server`

4. **Configure the connection**:
   
   **General tab:**
   - Name: `Local Docker` (or any descriptive name)
   
   **Connection tab:**
   - Host name/address: `pgdatabase` *(container name)*
   - Port: `5432`
   - Maintenance database: `postgres`
   - Username: `root`
   - Password: `root`

5. **Click Save**

---

## Why This Avoids Password/Networking Issues 🎯

### The Problem with `host.docker.internal` on WSL

If you tried connecting from WSL (host) to containers using `host.docker.internal`, you might encounter:
- **Password authentication failures** (even with correct credentials)
- **Connection timeouts**
- **Inconsistent behavior** depending on Docker Desktop settings

**Root causes:**
1. WSL has nested virtualization (WSL → Docker Desktop → Container)
2. Stale Docker volumes can cache old passwords
3. Network boundaries between WSL and Docker Desktop add complexity

### The Solution: Container Networking

**By running both on `pg-network`:**
- ✅ No password bridging issues (direct internal connection)
- ✅ No `localhost` confusion (each container's localhost is isolated)
- ✅ No WSL networking complexity (Docker handles routing internally)
- ✅ Clean and predictable (Docker DNS just works)

### Connection Comparison

```python
# ❌ From WSL to container (complex, can fail on WSL)
engine = create_engine("postgresql://root:root@host.docker.internal:5432/ny_taxi")
# Issues: password auth failures, WSL boundary crossing

# ❌ Using localhost (wrong - reaches container's own localhost)
engine = create_engine("postgresql://root:root@localhost:5432/ny_taxi")
# Issue: localhost in pgAdmin container ≠ PostgreSQL container

# ✅ Container-to-container via Docker network (best!)
engine = create_engine("postgresql://root:root@pgdatabase:5432/ny_taxi")
# Benefits: simple, reliable, no WSL issues
```

---

## ✨ You're All Set!

You now have a fully functional pgAdmin interface connected to your PostgreSQL container. You can:

- 📊 Browse tables, schemas, and databases
- 🔍 Run SQL queries in the Query Tool
- 📈 View results visually
- ⚙️ Manage databases, users, and permissions
- 💾 Create backups and restore data