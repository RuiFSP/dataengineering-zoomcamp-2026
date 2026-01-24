# Module 1 Homework: Docker & SQL

In this homework we'll prepare the environment and practice
Docker and SQL

When submitting your homework, you will also need to include
a link to your GitHub repository or other public code-hosting
site.

This repository should contain the code for solving the homework.

When your solution has SQL or shell commands and not code
(e.g. python files) file format, include them directly in
the README file of your repository.

---

## 📋 Homework Summary - Answers

| Question | Answer |
|----------|--------|
| Q1: pip version in python:3.13 | **25.3** |
| Q2: pgAdmin connection to postgres | **db:5432** or **postgres:5432** |
| Q3: Trips ≤ 1 mile | **8,007** |
| Q4: Day with longest trip | **2025-11-14** |
| Q5: Biggest pickup zone (Nov 18) | **East Harlem North** |
| Q6: Largest tip dropoff zone | **Yorkville West** |
| Q7: Terraform workflow | **terraform init, terraform apply -auto-approve, terraform destroy** |

---

## Question 1. Understanding Docker images

Run docker with the `python:3.13` image. Use an entrypoint `bash` to interact with the container.

What's the version of `pip` in the image?

- ✅ 25.3
- 24.3.1
- 24.2.1
- 23.3.1

### Solution

**Command used:**
```bash
docker run -it --entrypoint bash python:3.13
```

Inside the container:
```bash
pip --version
```

**Response:**
```
pip 25.3 from /usr/local/lib/python3.13/site-packages/pip (python 3.13)
```

**Answer: 25.3**


## Question 2. Understanding Docker networking and docker-compose

Given the following `docker-compose.yaml`, what is the `hostname` and `port` that pgadmin should use to connect to the postgres database?

```yaml
services:
  db:
    container_name: postgres
    image: postgres:17-alpine
    environment:
      POSTGRES_USER: 'postgres'
      POSTGRES_PASSWORD: 'postgres'
      POSTGRES_DB: 'ny_taxi'
    ports:
      - '5433:5432'
    volumes:
      - vol-pgdata:/var/lib/postgresql/data

  pgadmin:
    container_name: pgadmin
    image: dpage/pgadmin4:latest
    environment:
      PGADMIN_DEFAULT_EMAIL: "pgadmin@pgadmin.com"
      PGADMIN_DEFAULT_PASSWORD: "pgadmin"
    ports:
      - "8080:80"
    volumes:
      - vol-pgadmin_data:/var/lib/pgadmin

volumes:
  vol-pgdata:
    name: vol-pgdata
  vol-pgadmin_data:
    name: vol-pgadmin_data
```

- postgres:5433
- localhost:5432
- db:5433
- postgres:5432
- ✅ db:5432

If multiple answers are correct, select any 

### Solution

**Explanation:**

In Docker Compose, containers on the same network communicate using **service names** as hostnames and **internal container ports**.

From the docker-compose.yaml:
- **Service name**: `db`
- **Container name**: `postgres`
- **Port mapping**: `5433:5432` (host:container)

pgAdmin runs inside a container on the same Docker network, so it uses:
- **Hostname**: `db` (service name) or `postgres` (container name)
- **Port**: `5432` (internal container port, NOT the host-mapped 5433)

The port `5433` is only for external access from the host machine. Inside the Docker network, containers always communicate on their internal ports.

**Answer: db:5432** (or postgres:5432 - both are correct)


## Prepare the Data

Download the green taxi trips data for November 2025:

```bash
wget https://d37ci6vzurychx.cloudfront.net/trip-data/green_tripdata_2025-11.parquet
```

You will also need the dataset with zones:

```bash
wget https://github.com/DataTalksClub/nyc-tlc-data/releases/download/misc/taxi_zone_lookup.csv
```

### Data Ingestion

Run the ingestion script to load data into PostgreSQL:

```bash
python ingest_homework_data.py
```

This will create two tables:
- `green_taxi_data` - 46,912 trips for November 2025
- `zones` - 265 taxi zones

### Connecting to pgAdmin

1. **Open pgAdmin** at http://localhost:8080
   - Email: `pgadmin@pgadmin.com`
   - Password: `pgadmin`

2. **Register PostgreSQL Server:**
   - Right-click "Servers" → "Register" → "Server..."
   
3. **General tab:**
   - Name: `homework-postgres` (or any name)

4. **Connection tab:**
   - Host: `db` (or `postgres`)
   - Port: `5432` (internal port, NOT 5433)
   - Maintenance database: `ny_taxi`
   - Username: `postgres`
   - Password: `postgres`
   - ✓ Save password

5. **Click "Save"**

You should now see both tables under:
**Servers → homework-postgres → Databases → ny_taxi → Schemas → public → Tables**

---

## Question 3. Counting short trips

For the trips in November 2025 (lpep_pickup_datetime between '2025-11-01' and '2025-12-01', exclusive of the upper bound), how many trips had a `trip_distance` of less than or equal to 1 mile?

- 7,853
- ✅ 8,007
- 8,254
- 8,421

### Solution

**SQL Query:**
```sql
SELECT COUNT(*) as trip_count
FROM green_taxi_data
WHERE lpep_pickup_datetime >= '2025-11-01'
  AND lpep_pickup_datetime < '2025-12-01'
  AND trip_distance <= 1;
```

**Result:** 8,007 trips

**Answer: 8,007**


## Question 4. Longest trip for each day

Which was the pick up day with the longest trip distance? Only consider trips with `trip_distance` less than 100 miles (to exclude data errors).

Use the pick up time for your calculations.

- ✅ 2025-11-14
- 2025-11-20
- 2025-11-23
- 2025-11-25

### Solution

**SQL Query:**
```sql
SELECT DATE(lpep_pickup_datetime) as pickup_date,
       MAX(trip_distance) as max_distance
FROM green_taxi_data
WHERE trip_distance < 100
GROUP BY DATE(lpep_pickup_datetime)
ORDER BY max_distance DESC
LIMIT 1;
```

**Result:** 2025-11-14 with max distance of 88.03 miles

**Answer: 2025-11-14**


## Question 5. Biggest pickup zone

Which was the pickup zone with the largest `total_amount` (sum of all trips) on November 18th, 2025?

- ✅ East Harlem North
- East Harlem South
- Morningside Heights
- Forest Hills

### Solution

**SQL Query:**
```sql
SELECT z."Zone",
       SUM(g.total_amount) as total_sum
FROM green_taxi_data g
JOIN zones z ON g."PULocationID" = z."LocationID"
WHERE DATE(g.lpep_pickup_datetime) = '2025-11-18'
GROUP BY z."Zone"
ORDER BY total_sum DESC
LIMIT 5;
```

**Result:**
- East Harlem North: $9,281.92
- East Harlem South: $6,696.13
- Central Park: $2,378.79

**Answer: East Harlem North**


## Question 6. Largest tip

For the passengers picked up in the zone named "East Harlem North" in November 2025, which was the drop off zone that had the largest tip?

Note: it's `tip` , not `trip`. We need the name of the zone, not the ID.

- JFK Airport
- ✅ Yorkville West
- East Harlem North
- LaGuardia Airport

### Solution

**SQL Query:**
```sql
SELECT do_zone."Zone" as dropoff_zone,
       MAX(g.tip_amount) as max_tip
FROM green_taxi_data g
JOIN zones pu_zone ON g."PULocationID" = pu_zone."LocationID"
JOIN zones do_zone ON g."DOLocationID" = do_zone."LocationID"
WHERE pu_zone."Zone" = 'East Harlem North'
  AND DATE(g.lpep_pickup_datetime) >= '2025-11-01'
  AND DATE(g.lpep_pickup_datetime) < '2025-12-01'
GROUP BY do_zone."Zone"
ORDER BY max_tip DESC
LIMIT 5;
```

**Result:**
- Yorkville West: $81.89
- LaGuardia Airport: $50.00
- East Harlem North: $45.00

**Answer: Yorkville West**


## Terraform

In this section homework we'll prepare the environment by creating resources in GCP with Terraform.

In your VM on GCP/Laptop/GitHub Codespace install Terraform.
Copy the files from the course repo
[here](../../../01-docker-terraform/terraform/terraform) to your VM/Laptop/GitHub Codespace.

Modify the files as necessary to create a GCP Bucket and Big Query Dataset.


## Question 7. Terraform Workflow

Which of the following sequences, respectively, describes the workflow for:
1. Downloading the provider plugins and setting up backend,
2. Generating proposed changes and auto-executing the plan
3. Remove all resources managed by terraform`

Answers:
- terraform import, terraform apply -y, terraform destroy
- teraform init, terraform plan -auto-apply, terraform rm
- terraform init, terraform run -auto-approve, terraform destroy
- ✅ terraform init, terraform apply -auto-approve, terraform destroy
- terraform import, terraform apply -y, terraform rm

### Solution

**Terraform Workflow Commands:**

1. **`terraform init`** - Downloads provider plugins and sets up the backend
   - This initializes the working directory
   - Downloads required providers (like Google Cloud provider)
   - Sets up state management

2. **`terraform apply -auto-approve`** - Generates plan and auto-executes it
   - Creates an execution plan showing what will be created/modified/destroyed
   - The `-auto-approve` flag skips the manual confirmation step
   - Applies the changes automatically

3. **`terraform destroy`** - Removes all resources managed by Terraform
   - Destroys all infrastructure defined in the Terraform files
   - Asks for confirmation (or use `-auto-approve` to skip)

**Answer: terraform init, terraform apply -auto-approve, terraform destroy**