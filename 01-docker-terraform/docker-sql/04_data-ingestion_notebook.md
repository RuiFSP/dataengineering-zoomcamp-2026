# Data Ingestion to PostgreSQL

This guide covers how to ingest data from CSV files into a PostgreSQL database using Python and pandas, with practical examples using NYC Taxi data.

## Overview

We'll be ingesting NYC Yellow Taxi trip data from a remote CSV file into our PostgreSQL database. The key challenges we'll address:
- Handling large datasets that don't fit in memory
- Ensuring correct data types
- Creating appropriate database schemas
- Monitoring ingestion progress

## Prerequisites

Make sure you have:
- PostgreSQL container running (see [03_postgres-docker.md](03_postgres-docker.md))
- Required Python packages installed

Install dependencies:
```bash
uv add pandas sqlalchemy psycopg2-binary tqdm
```

## Step 1: Explore the Data

Before ingesting, always explore a sample of your data:

```python
import pandas as pd

# Read a small sample first
prefix = 'https://github.com/DataTalksClub/nyc-tlc-data/releases/download/yellow/'
df = pd.read_csv(prefix + 'yellow_tripdata_2021-01.csv.gz', nrows=100)

# Display first rows
df.head()

# Check data types
df.dtypes

# Check data shape
df.shape
```

**Why this matters:** Understanding the data structure helps you define proper data types and avoid type inference issues.

## Step 2: Define Data Types

Define explicit data types to ensure data quality and prevent pandas from making incorrect assumptions:

```python
dtype = {
	"VendorID": "Int64",
	"passenger_count": "Int64",
	"trip_distance": "float64",
	"RatecodeID": "Int64",
	"store_and_fwd_flag": "string",
	"PULocationID": "Int64",
	"DOLocationID": "Int64",
	"payment_type": "Int64",
	"fare_amount": "float64",
	"extra": "float64",
	"mta_tax": "float64",
	"tip_amount": "float64",
	"tolls_amount": "float64",
	"improvement_surcharge": "float64",
	"total_amount": "float64",
	"congestion_surcharge": "float64"
}

parse_dates = [
	"tpep_pickup_datetime",
	"tpep_dropoff_datetime"
]

# Load data with explicit types
df = pd.read_csv(
	prefix + 'yellow_tripdata_2021-01.csv.gz',
	dtype=dtype,
	parse_dates=parse_dates
)
```

**Important notes:**
- Use `Int64` (capital I) instead of `int64` to allow nullable integers
- Use `string` dtype instead of `object` for text columns
- Parse date columns explicitly with `parse_dates`

Verify the data types:
```python
df.info()
```

## Understanding Docker Networking 🌐

Before connecting to PostgreSQL, it's crucial to understand Docker networking, especially on WSL.

### Container-to-Container Communication (Recommended!)

When both your application and database are **containers on the same Docker network**, they can communicate using container names:

```python
# ✅ Both containers on pg-network
engine = create_engine("postgresql://root:root@pgdatabase:5432/ny_taxi")
```

**Benefits:**
- Clean and simple
- No localhost confusion
- No WSL networking issues
- Containers discover each other by `--name`
- This is how pgAdmin connects to PostgreSQL!

### Host-to-Container Communication (More Complex)

When your **Python script runs on your WSL/host machine** and needs to connect to a **container**:

```python
# Option 1: Use host.docker.internal (may work on WSL)
engine = create_engine("postgresql://root:root@host.docker.internal:5432/ny_taxi")

# Option 2: Use localhost (if port is mapped with -p 5432:5432)
engine = create_engine("postgresql://root:root@localhost:5432/ny_taxi")
```

### Why Networking is Tricky on WSL

**The Problem:**
- Your WSL environment has its own `localhost`
- Docker containers have their own `localhost`
- Windows host has its own `localhost`
- These are **three different network namespaces!**

**Why `localhost` often fails:**
```
WSL localhost ≠ Container localhost ≠ Windows localhost
```

**Why `host.docker.internal` can be unreliable on WSL:**
- It's designed for Docker Desktop on Mac/Windows
- WSL has nested virtualization (WSL → Docker → Container)
- Sometimes it works, sometimes it doesn't depending on your Docker setup

### Which Connection String Should You Use?

| Scenario | Connection String | Notes |
|----------|-------------------|-------|
| **Containers on same network** | `pgdatabase:5432` | ✅ Best option - simple and reliable |
| **WSL → Container (port mapped)** | `localhost:5432` | ⚠️ Only if `-p 5432:5432` is used |
| **WSL → Container (no port map)** | `host.docker.internal:5432` | ⚠️ May not work on all WSL setups |
| **Container IP directly** | `172.17.0.2:5432` | ⚠️ IP changes on restart |

### Best Practice

**If possible, run your ingestion script as a container** on the same network:
```bash
docker run --network=pg-network my-ingestion-script
```

This eliminates all WSL networking issues!

---

## Step 3: Connect to PostgreSQL

For this tutorial, we're running the Python script on WSL (host), so we use:

```python
from sqlalchemy import create_engine

# From WSL host to container
engine = create_engine("postgresql://root:root@host.docker.internal:5432/ny_taxi")
```

**Alternative for WSL if `host.docker.internal` doesn't work:**
```python
# Use localhost if you exposed the port with -p 5432:5432
engine = create_engine("postgresql://root:root@localhost:5432/ny_taxi")
```

## Step 4: Generate and Create Database Schema

Preview the SQL schema that pandas will generate:

```python
print(pd.io.sql.get_schema(df, name='yellow_taxi_data', con=engine))
```

This shows you the `CREATE TABLE` statement with column types that will be used.

Create the table schema (without data):

```python
# Create table with just the schema (no data)
df.head(n=0).to_sql(name='yellow_taxi_data', con=engine, if_exists='replace')
```

**Why `head(n=0)`?** This creates an empty DataFrame with just the columns and types, allowing you to create the table structure without inserting any rows yet.

## Step 5: Verify Table Creation

Connect to the database to verify:

```bash
# From WSL
PGPASSWORD=root uv run pgcli -h host.docker.internal -p 5432 -u root -d ny_taxi
```

Inside pgcli:
```sql
-- List tables
\dt

-- Describe the table structure
\d yellow_taxi_data

-- Check row count (should be 0)
SELECT COUNT(*) FROM yellow_taxi_data;
```

## Step 6: Ingest Data in Chunks

For large datasets, use chunked reading to avoid memory issues:

```python
# Create an iterator that reads data in chunks
df_iter = pd.read_csv(
	prefix + 'yellow_tripdata_2021-01.csv.gz',
	dtype=dtype,
	parse_dates=parse_dates,
	iterator=True,
	chunksize=100000,  # Read 100k rows at a time
)
```

**Important:** Iterators can only be consumed once. If you need to use it multiple times, recreate it.

```python
# This exhausts the iterator
for df_chunk in df_iter:
	print(len(df_chunk))

# Need to recreate it to use again
df_iter = pd.read_csv(
	prefix + 'yellow_tripdata_2021-01.csv.gz',
	dtype=dtype,
	parse_dates=parse_dates,
	iterator=True,
	chunksize=100000,
)
```

## Step 7: Ingest with Progress Bar

Use `tqdm` to monitor ingestion progress:

```python
from tqdm.auto import tqdm

# Recreate the iterator
df_iter = pd.read_csv(
	prefix + 'yellow_tripdata_2021-01.csv.gz',
	dtype=dtype,
	parse_dates=parse_dates,
	iterator=True,
	chunksize=100000,
)

# Ingest chunks with progress bar
for df_chunk in tqdm(df_iter):
	df_chunk.to_sql(name='yellow_taxi_data', con=engine, if_exists='append')
```

**Key parameters:**
- `if_exists='append'`: Adds rows to existing table (use `'replace'` to drop and recreate)
- `chunksize=100000`: Adjust based on your memory constraints and network speed

## Verification

After ingestion, verify the data:

```sql
-- Check total row count
SELECT COUNT(*) FROM yellow_taxi_data;

-- View sample data
SELECT * FROM yellow_taxi_data LIMIT 10;

-- Check date range
SELECT MIN(tpep_pickup_datetime), MAX(tpep_pickup_datetime) 
FROM yellow_taxi_data;
```

## Best Practices Summary

1. **Always explore data first** - Use `nrows` parameter to read a sample
2. **Define explicit data types** - Prevents type inference issues
3. **Use chunks for large files** - Avoids memory overflow
4. **Create schema separately** - Use `head(n=0).to_sql()` first, then append data
5. **Monitor progress** - Use `tqdm` for long-running ingestions
6. **Remember iterator behavior** - Iterators can only be consumed once
7. **Understand Docker networking** - Container-to-container is simpler than host-to-container
8. **Dockerize production scripts** - Run ingestion as container on same network for reliability
9. **Verify after ingestion** - Always check row counts and data quality

## Common Issues

**Issue: Iterator exhausted**
```python
# Problem: Iterator used twice
for chunk in df_iter:
	print(len(chunk))
    
for chunk in df_iter:  # This won't work - iterator is exhausted
	chunk.to_sql(...)

# Solution: Recreate the iterator
df_iter = pd.read_csv(..., iterator=True, chunksize=100000)
for chunk in df_iter:
	chunk.to_sql(...)
```

**Issue: Connection refused (WSL)**
```python
# Problem: localhost doesn't work from WSL to container
engine = create_engine("postgresql://root:root@localhost:5432/ny_taxi")
# Error: could not connect to server: Connection refused

# Solution 1: Use host.docker.internal (if supported)
engine = create_engine("postgresql://root:root@host.docker.internal:5432/ny_taxi")

# Solution 2: Use localhost only if port is mapped with -p 5432:5432
engine = create_engine("postgresql://root:root@localhost:5432/ny_taxi")

# Solution 3: Run ingestion script as container on same network (best!)
# Use container name: pgdatabase
engine = create_engine("postgresql://root:root@pgdatabase:5432/ny_taxi")
```

**Pro tip:** For production pipelines, dockerize your ingestion script and run it on the same Docker network as your database. This eliminates all host-to-container networking issues!

**Issue: Type errors during ingestion**
- Always specify `dtype` parameter to avoid pandas guessing wrong types
- Use `Int64` (nullable) instead of `int64` for integer columns with potential nulls
- Use `string` instead of `object` for text columns

## Next Steps

- Learn about indexing for query performance
- Explore partitioning for large tables
- Implement error handling and retry logic
- Set up logging for production pipelines
