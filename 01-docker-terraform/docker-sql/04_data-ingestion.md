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

## Step 3: Connect to PostgreSQL

Create a connection engine using SQLAlchemy:

```python
from sqlalchemy import create_engine

# For WSL, use host.docker.internal (see 03_postgres-docker.md for details)
engine = create_engine("postgresql://root:root@host.docker.internal:5432/ny_taxi")
```

**Important for WSL users:** Always use `host.docker.internal` instead of `localhost` when connecting from WSL to Docker containers.

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
7. **WSL networking** - Use `host.docker.internal` for container connections
8. **Verify after ingestion** - Always check row counts and data quality

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
# Wrong: localhost doesn't work on WSL
engine = create_engine("postgresql://root:root@localhost:5432/ny_taxi")

# Correct: Use host.docker.internal
engine = create_engine("postgresql://root:root@host.docker.internal:5432/ny_taxi")
```

**Issue: Type errors during ingestion**
- Always specify `dtype` parameter to avoid pandas guessing wrong types
- Use `Int64` (nullable) instead of `int64` for integer columns with potential nulls
- Use `string` instead of `object` for text columns

## Next Steps

- Learn about indexing for query performance
- Explore partitioning for large tables
- Implement error handling and retry logic
- Set up logging for production pipelines
