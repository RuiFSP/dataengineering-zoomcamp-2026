# Workshop Homework: Build Your Own dlt Pipeline (Solution)

In this homework, we build a custom dlt pipeline to ingest NYC Yellow Taxi trip data from a paginated REST API into DuckDB, then answer analytical questions from the loaded dataset.

---

## 📋 Homework Summary - Answers

| Question | Answer |
|----------|--------|
| Question 1 | **2009-06-01 to 2009-07-01** |
| Question 2 | **26.66%** |
| Question 3 | **$6,063.41** |

---

## Prerequisites

Before starting, ensure you have:

✅ Python virtual environment configured
✅ `dlt[workspace]` installed
✅ `duckdb` destination available through dlt
✅ Project workspace available locally

**Environment used in this solution:**
- Python: `3.13.11` (venv)
- Workspace root: `/home/ruifspinto/projects/dataengineering-zoomcamp-2026`
- Pipeline script: `workshop/dlt/taxi_pipeline.py`
- DuckDB output: `workshop/dlt/taxi_pipeline.duckdb`

---

## Data Source

| Property | Value |
|----------|-------|
| Base URL | `https://us-central1-dlthub-analytics.cloudfunctions.net/data_engineering_zoomcamp_api` |
| Format | Paginated JSON |
| Page Size | 1,000 records per page |
| Pagination rule | Stop when an empty page is returned |

---

## Setup & Pipeline Execution

### Step 1: Implement the pipeline

Created `workshop/dlt/taxi_pipeline.py` with:
- custom page-based ingestion (`page=1,2,3...`)
- explicit stop condition when API returns empty list
- dlt pipeline target:
  - `pipeline_name="taxi_pipeline"`
  - `destination="duckdb"`
  - `dataset_name="taxi_data"`

### Step 2: Run the pipeline

```bash
cd workshop/dlt
/home/ruifspinto/projects/dataengineering-zoomcamp-2026/.venv/bin/python taxi_pipeline.py
```

### Step 3: Confirm load

Pipeline run completed successfully with:
- `taxi_trips`: **10,000** rows loaded
- destination database: `workshop/dlt/taxi_pipeline.duckdb`

---

## Questions & Solutions

### Question 1. What is the start date and end date of the dataset?

**Answer:** **2009-06-01 to 2009-07-01** ✅

**SQL used:**

```sql
SELECT
  MIN(trip_pickup_date_time) AS min_pickup,
  MAX(trip_pickup_date_time) AS max_pickup
FROM taxi_trips;
```

**Result:**
- `min_pickup = 2009-06-01 11:33:00`
- `max_pickup = 2009-06-30 23:58:00`

**Interpretation:**
- Actual max timestamp is within June 30.
- The matching homework option is represented as **2009-06-01 to 2009-07-01**.

---

### Question 2. What proportion of trips are paid with credit card?

**Answer:** **26.66%** ✅

**SQL used:**

```sql
SELECT
  ROUND(
    100.0 * SUM(CASE WHEN lower(trim(payment_type)) = 'credit' THEN 1 ELSE 0 END) / COUNT(*),
    2
  ) AS credit_pct
FROM taxi_trips;
```

**Result:**
- `credit_pct = 26.66`

---

### Question 3. What is the total amount of money generated in tips?

**Answer:** **$6,063.41** ✅

**SQL used:**

```sql
SELECT ROUND(SUM(tip_amt), 2) AS total_tips
FROM taxi_trips;
```

**Result:**
- `total_tips = 6063.41`

---

## Validation Notes

- Table discovered in pipeline: `taxi_trips`
- Row count check:

```sql
SELECT COUNT(*) AS trip_count FROM taxi_trips;
```

- Result: `trip_count = 10000`

### Schema normalization detail

dlt normalized incoming field names to snake_case. Example mappings:
- `Trip_Pickup_DateTime` → `trip_pickup_date_time`
- `Payment_Type` → `payment_type`
- `Tip_Amt` → `tip_amt`

This is why analysis queries use normalized column names.

---

## Key Learnings

- Building a custom dlt pipeline for non-scaffolded APIs is straightforward with explicit pagination logic.
- Validating schema names after ingestion is critical because dlt normalizes column names.
- DuckDB + dlt gives a very fast local loop for ingestion, validation, and SQL-based homework analytics.
