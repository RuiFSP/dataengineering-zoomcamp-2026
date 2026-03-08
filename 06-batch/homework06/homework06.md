# Module 6 Homework: Batch Processing with Spark

This document contains the solved homework for Module 6 using PySpark and the November 2025 Yellow Taxi dataset.

## Homework Summary - Answers

| Question | Answer |
|----------|--------|
| Q1. Spark version | `4.1.1` |
| Q2. Avg parquet file size after `repartition(4)` | **25MB** (actual avg: `24.41 MB`) |
| Q3. Trips starting on 2025-11-15 | **162,604** |
| Q4. Longest trip duration | **90.6 hours** (actual max: `90.65`) |
| Q5. Spark UI local port | **4040** |
| Q6. Least frequent pickup zone | **Arden Heights** |

## Prerequisites

1. Java installed (Spark runtime dependency).
2. Python virtual environment available at project root (`.venv`).
3. `pyspark` installed in the virtual environment.
4. Input files downloaded in `06-batch/homework06/`.

## Data Download

From `06-batch/homework06/`:

```bash
wget -nc https://d37ci6vzurychx.cloudfront.net/trip-data/yellow_tripdata_2025-11.parquet
wget -nc https://d37ci6vzurychx.cloudfront.net/misc/taxi_zone_lookup.csv
```

## Question 1: Install Spark and PySpark

Create a local Spark session and print `spark.version`.

```python
from pyspark.sql import SparkSession

spark = SparkSession.builder.master("local[*]").appName("homework06").getOrCreate()
print(spark.version)
```

Result from this environment: `4.1.1`.

Final answer: `4.1.1`

## Question 2: Yellow November 2025

Read `yellow_tripdata_2025-11.parquet`, repartition to 4, and write parquet output.

```python
df = spark.read.parquet("yellow_tripdata_2025-11.parquet")
df.repartition(4).write.mode("overwrite").parquet("yellow_2025_11_repartitioned_4")
```

Then average only parquet part-file sizes (`*.parquet`):

- Part sizes (MB): `24.39`, `24.42`, `24.42`, `24.41`
- Average size (MB): `24.41`

Closest option: **25MB**.

Final answer: `25MB`

## Question 3: Count records

Count records where pickup date is `2025-11-15`:

```python
from pyspark.sql import functions as F

count_1511 = (
    df.filter(F.to_date(F.col("tpep_pickup_datetime")) == F.lit("2025-11-15"))
    .count()
)
```

Exact result: `162,604`.

Final answer: `162,604`

## Question 4: Longest trip

Compute maximum trip duration in hours:

```python
duration_hours = (
    (F.unix_timestamp(F.col("tpep_dropoff_datetime")) - F.unix_timestamp(F.col("tpep_pickup_datetime")))
    / F.lit(3600.0)
)

max_hours = (
    df.select(duration_hours.alias("duration_hours"))
    .agg(F.max("duration_hours").alias("max_duration_hours"))
    .collect()[0]["max_duration_hours"]
)
```

Exact result: `90.65` hours.

Closest option: **90.6**.

Final answer: `90.6`

## Question 5: User Interface

Spark UI default local port is **4040**.

Note: if port `4040` is already occupied, Spark may auto-increment (e.g., `4041`).

Final answer: `4040`

## Question 6: Least frequent pickup location zone

Load zone lookup CSV and join with pickup location IDs:

```python
zones_df = spark.read.option("header", True).option("inferSchema", True).csv("taxi_zone_lookup.csv")

zone_counts = (
    df.groupBy("PULocationID")
    .count()
    .join(zones_df, df.PULocationID == zones_df.LocationID, "left")
    .filter(F.col("Zone").isNotNull())
    .select("Zone", "count")
)
```

Minimum pickup count was `1`, with multiple tied zones including:

1. `Arden Heights`
2. `Governor's Island/Ellis Island/Liberty Island`
3. `Eltingville/Annadale/Prince's Bay` (not in the answer options)

Since multiple are valid and the homework allows any tied answer, selected answer is:

Final answer: `Arden Heights`
