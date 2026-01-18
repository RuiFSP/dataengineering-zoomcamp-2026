# Complete Rebuild: From Zero to Running Pipeline

This guide shows how to rebuild the entire data pipeline from scratch, demonstrating that everything is reproducible with Docker Compose and containerization.

---

## Overview

We'll rebuild:
1. 🗑️ Delete all containers, volumes, networks, and images
2. 🏗️ Build the ingestion Docker image
3. 🚀 Start infrastructure with Docker Compose
4. ⚙️ Configure pgAdmin
5. 📊 Run data ingestion
6. ✅ Verify everything works

**Time estimate:** ~10-15 minutes (depending on download speeds)

---

## Step 1: Cleanup 🗑️

Choose your cleanup approach based on your needs:

### Option A: Project-Specific Cleanup (Recommended)

Delete only this project's resources:

```bash
# Stop and remove all compose services + volumes
cd 01-docker-terraform/docker-sql
docker compose down -v

# Remove the ingestion image (separate step!)
docker rmi taxi_ingest:v001

# Optional: Clean up unused networks
docker network prune -f
```

**What this does:**
- ✅ Stops PostgreSQL and pgAdmin containers (defined in compose)
- ✅ Deletes `ny_taxi_postgres_data` and `pgadmin_data` volumes
- ✅ Removes `docker-sql_default` network
- ✅ Deletes the `taxi_ingest:v001` image (NOT removed by compose!)

**Important note:**
`docker compose down` only affects services in `docker-compose.yml`. Since `taxi_ingest:v001` is built separately, you must remove it explicitly with `docker rmi`.

### Option B: Aggressive Volume Cleanup

Remove all unused volumes across all projects:

```bash
# Stop compose first
docker compose down

# Remove ALL unused volumes
docker volume prune -f
```

**Warning:** This removes volumes from other Docker projects too!

### Option C: Nuclear Option (Complete Docker Reset)

Remove ALL Docker resources (images, containers, volumes, networks):

```bash
# ⚠️ Warning: This removes ALL Docker resources!
docker system prune -a --volumes
```

**What this does:**
- 🗑️ All stopped containers
- 🗑️ All unused networks
- 🗑️ All unused images (not just dangling)
- 🗑️ All unused volumes
- 🗑️ All build cache

**Use when:** You want a completely fresh Docker slate.

---

### Verify Cleanup

```bash
docker ps -a                         # Should show no related containers
docker images | grep taxi            # Should show no taxi_ingest image
docker network ls | grep docker-sql  # Should show no docker-sql_default
docker volume ls                     # Should show no ny_taxi volumes
```

---

## Step 2: Build the Ingestion Image 🏗️

Build the Docker image for data ingestion:

```bash
# IMPORTANT: Start from project root!
cd /home/ruifspinto/projects/dataengineering-zoomcamp-2026

# Build the image
docker build -t taxi_ingest:v001 \
  -f 01-docker-terraform/docker-sql/pipeline/Dockerfile .
```

**Critical requirements:**
- ✅ Run from **project root** (where `pyproject.toml` is located)
- ✅ The `-f` flag specifies the Dockerfile path
- ✅ The `.` at the end sets the build context (entire project)
- ❌ Don't run from `docker-sql` directory - build will fail!

**Verify the image:**
```bash
docker images | grep taxi_ingest
# Should show: taxi_ingest   v001   <image-id>   <time>   <size>
```

**Build time:** ~2-5 minutes (installs Python dependencies)

---

## Step 3: Start Infrastructure with Docker Compose 🚀

Start PostgreSQL and pgAdmin:

```bash
# Navigate to docker-sql directory
cd 01-docker-terraform/docker-sql

# Start services in detached mode
docker compose up -d
```

**What happens:**
- ✅ Pulls `postgres:18` image (if not cached)
- ✅ Pulls `dpage/pgadmin4` image (if not cached)
- ✅ Creates `docker-sql_default` network
- ✅ Creates volumes: `ny_taxi_postgres_data`, `pgadmin_data`
- ✅ Starts containers: `pgdatabase`, `pgadmin`

**Verify services are running:**
```bash
docker compose ps

# Should show:
# NAME        IMAGE              STATUS    PORTS
# pgadmin     dpage/pgadmin4     Up        0.0.0.0:8085->80/tcp
# pgdatabase  postgres:18        Up        0.0.0.0:5432->5432/tcp
```

**Check logs if needed:**
```bash
docker compose logs pgdatabase
docker compose logs pgadmin
```

**Wait time:** ~10-20 seconds for services to fully initialize

---

## Step 4: Configure pgAdmin ⚙️

Register PostgreSQL server in pgAdmin:

### 4.1 Access pgAdmin

1. Open browser → **http://localhost:8085**

2. **Login:**
   - Email: `admin@admin.com`
   - Password: `root`

### 4.2 Register PostgreSQL Server

3. **Right-click** `Servers` (left sidebar) → `Register` → `Server`

4. **General tab:**
   - Name: `pg` (or `Local Docker`)

5. **Connection tab:**
   - Host name/address: `pgdatabase`
   - Port: `5432`
   - Maintenance database: `postgres`
   - Username: `root`
   - Password: `root`

6. **Click Save**

7. **Verify connection:**
   - Expand `Servers` → `pg` → `Databases`
   - You should see `ny_taxi` database

---

## Step 5: Run Data Ingestion 📊

Ingest NYC Taxi data into PostgreSQL:

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

**What happens:**
1. Container starts and joins `docker-sql_default` network
2. Connects to PostgreSQL via `pgdatabase:5432`
3. Downloads `yellow_tripdata_2021-01.csv.gz` from GitHub
4. Creates `yellow_taxi_trips` table
5. Streams data in 100k row chunks
6. Shows progress bar with `tqdm`
7. Container exits when complete

**Expected output:**
```
Downloading data...
Creating table yellow_taxi_trips...
Ingesting data...
100%|████████████████████| 13/13 [00:45<00:00,  3.50s/chunk]
Ingestion complete: 1,369,765 rows
```

**Ingestion time:** ~1-2 minutes (depending on network speed)

---

## Step 6: Verify Everything Works ✅

### 6.1 Check Row Count via psql

> 💡 **Important**: Docker Compose adds prefixes to container names!

**Find the actual container name:**
```bash
docker ps --format "table {{.Names}}\t{{.Image}}"
```

You'll see containers named like:
- `docker-sql-pgdatabase-1` (not just `pgdatabase`)
- `docker-sql-pgadmin-1`

**Option 1: Use Docker Compose exec (must be in docker-sql directory)**

```bash
# IMPORTANT: Run from the docker-sql directory!
cd 01-docker-terraform/docker-sql

docker compose exec pgdatabase psql -U root -d ny_taxi \
  -c "SELECT COUNT(*) FROM yellow_taxi_trips;"
```

**Option 2: Use full container name (works from anywhere)**
```bash
# Works from any directory
docker exec -it docker-sql-pgdatabase-1 psql -U root -d ny_taxi \
  -c "SELECT COUNT(*) FROM yellow_taxi_trips;"
```

**Expected output:**
```
  count
---------
 1369765
(1 row)
```

### 6.2 Check Data in pgAdmin

1. In pgAdmin, navigate to:
   - `Servers` → `pg` → `Databases` → `ny_taxi` → `Schemas` → `public` → `Tables`

2. Right-click `yellow_taxi_trips` → `View/Edit Data` → `First 100 Rows`

3. **Verify columns:**
   - `vendorid`, `tpep_pickup_datetime`, `tpep_dropoff_datetime`
   - `passenger_count`, `trip_distance`, `fare_amount`, etc.

### 6.3 Run Sample Queries

```sql
-- Average trip distance
SELECT AVG(trip_distance) FROM yellow_taxi_trips;

-- Trips by day
SELECT 
  DATE(tpep_pickup_datetime) as trip_date,
  COUNT(*) as num_trips
FROM yellow_taxi_trips
GROUP BY trip_date
ORDER BY trip_date
LIMIT 10;

-- Top 10 pickup locations
SELECT 
  "PULocationID",
  COUNT(*) as num_trips
FROM yellow_taxi_trips
GROUP BY "PULocationID"
ORDER BY num_trips DESC
LIMIT 10;
```

---

## Quick Reference: All Commands

```bash
# 1. Cleanup (choose one approach)

# Option A: Project-specific
cd 01-docker-terraform/docker-sql
docker compose down -v
docker rmi taxi_ingest:v001
docker network prune -f

# Option B: Aggressive volume cleanup
docker compose down
docker volume prune -f

# Option C: Nuclear option (ALL Docker resources)
docker system prune -a --volumes

# 2. Build ingestion image
cd ../..  # Back to project root
docker build -t taxi_ingest:v001 -f 01-docker-terraform/docker-sql/pipeline/Dockerfile .

# 3. Start infrastructure
cd 01-docker-terraform/docker-sql
docker compose up -d

# 4. Configure pgAdmin (manual steps in browser)
# http://localhost:8085

# 5. Ingest data
docker run -it --network=docker-sql_default taxi_ingest:v001 \
  --pg-host=pgdatabase \
  --pg-user=root --pg-pass=root --pg-port=5432 --pg-db=ny_taxi \
  --target-table=yellow_taxi_trips \
  --year=2021 --month=01 --chunksize=100000

# 6. Verify
docker compose exec pgdatabase psql -U root -d ny_taxi -c "SELECT COUNT(*) FROM yellow_taxi_trips;"
# Or use full container name:
docker exec -it docker-sql-pgdatabase-1 psql -U root -d ny_taxi -c "SELECT COUNT(*) FROM yellow_taxi_trips;"
```

---

## Docker Compose Container Naming 📛

**Important difference:**

| Approach | Container Name | Why |
|----------|----------------|-----|
| `docker run --name pgdatabase` | `pgdatabase` | You explicitly set the name |
| `docker compose` | `docker-sql-pgdatabase-1` | Compose adds `<directory>-<service>-<replica>` |

**Docker Compose naming pattern:**
```
<directory-name>-<service-name>-<replica-number>
```

Examples:
- Directory: `docker-sql` → Prefix: `docker-sql-`
- Service: `pgdatabase` → Full name: `docker-sql-pgdatabase-1`
- Service: `pgadmin` → Full name: `docker-sql-pgadmin-1`

**Best practice with Compose:**
```bash
# ✅ MUST be in docker-sql directory!
cd 01-docker-terraform/docker-sql
docker compose exec pgdatabase psql -U root -d ny_taxi

# ❌ Won't work from project root (compose file not found)
cd /home/ruifspinto/projects/dataengineering-zoomcamp-2026
docker compose exec pgdatabase psql ...  # Error: docker-compose.yaml not found

# ✅ Works from any directory (uses full container name)
docker exec -it docker-sql-pgdatabase-1 psql -U root -d ny_taxi
```

---

## Troubleshooting

### Issue: "network docker-sql_default not found"

**Cause:** Docker Compose not running or network name mismatch

**Solution:**
```bash
# Check if compose is running
docker compose ps

# Verify network name
docker network ls | grep default

# If network has different name, use it in docker run --network=<actual-name>
```

### Issue: "port 5432 already in use"

**Cause:** Another PostgreSQL instance is running

**Solution:**
```bash
# Find conflicting container
docker ps | grep 5432

# Stop it
docker stop <container-id>

# Or change port in docker-compose.yml to 5433:5432
```

### Issue: "password authentication failed"

**Cause:** Stale volume with old credentials

**Solution:**
```bash
# Delete volumes and restart
docker compose down -v
docker compose up -d
```

### Issue: "unable to remove repository reference" when removing image

**Cause:** A container (even if stopped) is still using the image

**Solution:**
```bash
# Find all containers using the image (including stopped ones)
docker ps -a | grep taxi_ingest

# Remove the container (stop is not enough!)
docker rm 3158c14ee28d

# Now remove the image
docker rmi taxi_ingest:v001
```

**Key difference:**
- `docker stop` = Pauses container (still exists, still references image)
- `docker rm` = Deletes container (no longer exists, releases image)

**Or do it in one command:**
```bash
# Stop and remove in one go
docker rm -f 3158c14ee28d && docker rmi taxi_ingest:v001
```

---

## Future Ingestions: Keep It Simple 🔄

Once you have the infrastructure running, **don't tear it down**! Reuse it for future ingestions.

### Stable Infrastructure (Docker Compose)

```bash
# Once running, keep these going indefinitely
docker compose up -d

# They stay running:
# - pgdatabase (PostgreSQL)
# - pgadmin (pgAdmin web UI)
# - docker-sql_default (network)
# - volumes (data persists)
```

**Leave these running!** You only need to rebuild when you need new data.

### One-Time Jobs (Ingestion)

Each time you need to ingest different data:

```bash
# 1. Build the ingestion image (from project root)
cd /home/ruifspinto/projects/dataengineering-zoomcamp-2026
docker build -t taxi_ingest:v001 -f 01-docker-terraform/docker-sql/pipeline/Dockerfile .

# 2. Run ingestion with different parameters (from docker-sql directory)
cd 01-docker-terraform/docker-sql
docker run -it --network=docker-sql_default taxi_ingest:v001 \
  --pg-host=pgdatabase \
  --pg-user=root --pg-pass=root \
  --pg-db=ny_taxi \
  --target-table=yellow_taxi_trips \
  --year=2021 --month=02 \
  --chunksize=100000

# 3. Optionally remove the image after ingestion (to free space)
docker rmi taxi_ingest:v001
```

### Example: Add More Months

```bash
# Ingest January (already done, but example)
docker run -it --network=docker-sql_default taxi_ingest:v001 \
  --year=2021 --month=01

# Add February
docker run -it --network=docker-sql_default taxi_ingest:v001 \
  --year=2021 --month=02

# Add March
docker run -it --network=docker-sql_default taxi_ingest:v001 \
  --year=2021 --month=03

# Data accumulates in the same yellow_taxi_trips table!
```

**Verify growth:**
```bash
docker compose exec pgdatabase psql -U root -d ny_taxi \
  -c "SELECT COUNT(*) FROM yellow_taxi_trips;"
```

### Key Principles

| Component | What To Do | Why |
|-----------|-----------|-----|
| **Infrastructure** (Compose) | Keep running | Stable, reusable |
| **Ingestion Image** | Rebuild each time | Parameters differ |
| **Ingestion Container** | Remove after use | One-time job |
| **Data** | Never delete! | Persists in PostgreSQL volume |

---

## Architecture Overview 🏗️

```
Your Laptop / WSL
│
├─ Docker Compose (Running)
│  ├─ PostgreSQL (pgdatabase)
│  │  └─ Volume: ny_taxi_postgres_data
│  │     └─ Tables: yellow_taxi_trips (grows with each ingestion)
│  │
│  └─ pgAdmin (web UI)
│     └─ Volume: pgadmin_data
│
├─ Docker Image (Built as needed)
│  └─ taxi_ingest:v001
│     └─ Temporary container for each ingestion job
│
└─ Network
   └─ docker-sql_default (connects all services)
```

**The magic:** Compose manages long-running services (PostgreSQL + pgAdmin). When you need data, build the ingestion image, run it on the same network, and it writes to PostgreSQL. The data stays forever in the volume!

---

## Common Workflows

### Workflow 1: One-Time Setup + Ingestion

```bash
# Day 1: Setup everything
docker compose up -d
docker build -t taxi_ingest:v001 -f 01-docker-terraform/docker-sql/pipeline/Dockerfile .
docker run -it --network=docker-sql_default taxi_ingest:v001 --year=2021 --month=01
```

### Workflow 2: Daily/Weekly Ingestions (Keep Compose Running)

```bash
# Already running from Day 1
docker compose ps  # Verify still running

# New data arrives, ingest it
docker build -t taxi_ingest:v001 -f 01-docker-terraform/docker-sql/pipeline/Dockerfile .
docker run -it --network=docker-sql_default taxi_ingest:v001 --year=2021 --month=02

# Docker Compose still running, PostgreSQL still has all data
# View in pgAdmin or query: docker compose exec pgdatabase psql ...
```

### Workflow 3: Long-Running Analysis

```bash
# Keep infrastructure for weeks
docker compose up -d  # Once, never touch again
docker compose logs pgdatabase  # Check health occasionally
docker compose ps  # Verify still running

# Each week, ingest new data
# (repeat build + run steps)

# Query anytime
docker compose exec pgdatabase psql -U root -d ny_taxi \
  -c "SELECT * FROM yellow_taxi_trips WHERE DATE(tpep_pickup_datetime) = '2021-02-15';"
```

---



By rebuilding from scratch, we demonstrated:

✅ **Reproducibility** - Anyone can rebuild this with the same files  
✅ **Containerization** - Everything runs in isolated containers  
✅ **Infrastructure as Code** - `docker-compose.yml` defines the stack  
✅ **Separation of Concerns** - Infrastructure (compose) vs jobs (manual run)  
✅ **Portability** - Works on any machine with Docker installed  

This is the foundation of modern data engineering! 🚀

---

## Next Steps

- **Different datasets**: Change `--year` and `--month` parameters
- **Multiple ingestions**: Run ingester multiple times for different months
- **Query optimization**: Add indexes to `yellow_taxi_trips` table
- **Orchestration**: Move to Airflow/Prefect for scheduled pipelines
- **Cloud deployment**: Deploy this to AWS/GCP/Azure
