# Module 3 Homework: Data Warehousing & BigQuery

In this homework we'll practice working with BigQuery and Google Cloud Storage.

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
| Q1: Count of records for 2024 | **20,332,093** |
| Q2: Data read estimation | **0 MB for External Table and 155.12 MB for Materialized Table** |
| Q3: Understanding columnar storage | **BigQuery is a columnar database, and it only scans the specific columns requested** |
| Q4: Zero fare trips | **8,333** |
| Q5: Partitioning and clustering strategy | **Partition by tpep_dropoff_datetime and Cluster on VendorID** |
| Q6: Partition benefits | **310.24 MB for non-partitioned and 26.84 MB for partitioned** |
| Q7: External table storage | **GCP Bucket** |
| Q8: Clustering best practices | **False** |
| Q9: COUNT(*) bytes processed | **0 bytes** (uses metadata) |

---

## Prerequisites

Before starting the homework, ensure you have:

✅ GCP project configured with BigQuery access
✅ GCS bucket created (e.g., `kestra-sandbook-taxi-data`)
✅ Google Cloud SDK authenticated (`gcloud auth login` and `gsutil` working)
✅ BigQuery dataset created (e.g., `nytaxi`)

**Note about naming conventions in this homework:**
- **Project ID**: `kestra-sandbook` (used in this solution - replace with your own project ID)
- **Dataset**: `nytaxi` (replace with your dataset name)
- **GCS Bucket**: `kestra-sandbook-taxi-data` (replace with your bucket name)

All SQL examples show the generic pattern first (using `your-project.your-dataset.table_name`), followed by the actual command used in this solution.

---

## Data

For this homework we will be using the Yellow Taxi Trip Records for January 2024 - June 2024 (not the entire year of data).

Parquet files are downloaded directly from the NYC TLC CloudFront CDN:

https://d37ci6vzurychx.cloudfront.net/trip-data/

Files: `yellow_tripdata_2024-01.parquet` through `yellow_tripdata_2024-06.parquet`

## Loading the data

For this homework, we'll load the data using command-line tools (`curl` for downloading and `gsutil` for uploading to GCS).

You will need to be authenticated with the Google Cloud SDK (`gcloud auth login` and `gsutil` working).

Make sure that all 6 files show in your GCS bucket before beginning.

Note: You will need to use the PARQUET option when creating an external table.

### Data Ingestion Steps

**Step 1: Download the 2024 data (Jan-Jun)**

```bash
cd /path/to/homework03

# Download all 6 months
curl -o yellow_tripdata_2024-01.parquet https://d37ci6vzurychx.cloudfront.net/trip-data/yellow_tripdata_2024-01.parquet
curl -o yellow_tripdata_2024-02.parquet https://d37ci6vzurychx.cloudfront.net/trip-data/yellow_tripdata_2024-02.parquet
curl -o yellow_tripdata_2024-03.parquet https://d37ci6vzurychx.cloudfront.net/trip-data/yellow_tripdata_2024-03.parquet
curl -o yellow_tripdata_2024-04.parquet https://d37ci6vzurychx.cloudfront.net/trip-data/yellow_tripdata_2024-04.parquet
curl -o yellow_tripdata_2024-05.parquet https://d37ci6vzurychx.cloudfront.net/trip-data/yellow_tripdata_2024-05.parquet
curl -o yellow_tripdata_2024-06.parquet https://d37ci6vzurychx.cloudfront.net/trip-data/yellow_tripdata_2024-06.parquet
```

**Step 2: Upload to GCS**

```bash
# Upload all files to your GCS bucket (replace with your bucket name)
gsutil -m cp yellow_tripdata_2024-*.parquet gs://your-bucket-name/

# Verify upload
gsutil ls gs://your-bucket-name/yellow_tripdata_2024-*.parquet
```

**Example (using kestra-sandbook-taxi-data bucket):**
```bash
gsutil -m cp yellow_tripdata_2024-*.parquet gs://kestra-sandbook-taxi-data/
```

**Result:** 326.1 MiB uploaded (6 files)

---

## BigQuery Setup

Create an external table using the Yellow Taxi Trip Records. 

Create a (regular/materialized) table in BQ using the Yellow Taxi Trip Records (do not partition or cluster this table).

### Creating the Tables

**1. Create External Table**

```sql
CREATE OR REPLACE EXTERNAL TABLE `your-project.your-dataset.external_yellow_tripdata_2024`
OPTIONS (
  format = "PARQUET",
  uris = ["gs://your-bucket-name/yellow_tripdata_2024-*.parquet"]
);
```

**Actual command used (replace with your project/dataset/bucket):**
```bash
bq query --use_legacy_sql=false '
CREATE OR REPLACE EXTERNAL TABLE `kestra-sandbook.nytaxi.external_yellow_tripdata_2024`
OPTIONS (
  format = "PARQUET",
  uris = ["gs://kestra-sandbook-taxi-data/yellow_tripdata_2024-*.parquet"]
);'
```

**2. Create Materialized Table**

```sql
CREATE OR REPLACE TABLE `your-project.your-dataset.yellow_tripdata_2024_materialized` 
AS SELECT * FROM `your-project.your-dataset.external_yellow_tripdata_2024`;
```

**Actual command used (replace with your project/dataset):**
```bash
bq query --use_legacy_sql=false '
CREATE OR REPLACE TABLE `kestra-sandbook.nytaxi.yellow_tripdata_2024_materialized` 
AS SELECT * FROM `kestra-sandbook.nytaxi.external_yellow_tripdata_2024`;'
```

--- 



## Question 1. Counting records

What is count of records for the 2024 Yellow Taxi Data?
- 65,623
- 840,402
- ✅ 20,332,093
- 85,431,289

### Solution

**SQL Query:**
```sql
SELECT COUNT(*) as total_records
FROM `your-project.your-dataset.external_yellow_tripdata_2024`;
```

**Actual command used:**
```bash
bq query --use_legacy_sql=false '
SELECT COUNT(*) as total_records
FROM `kestra-sandbook.nytaxi.external_yellow_tripdata_2024`;'
```

**Result:**
```
+---------------+
| total_records |
+---------------+
|      20332093 |
+---------------+
```

**Answer: 20,332,093** ✅

---
## Question 2. Data read estimation

Write a query to count the distinct number of PULocationIDs for the entire dataset on both the tables.
 
What is the **estimated amount** of data that will be read when this query is executed on the External Table and the Table?

- 18.82 MB for the External Table and 47.60 MB for the Materialized Table
- ✅ 0 MB for the External Table and 155.12 MB for the Materialized Table
- 2.14 GB for the External Table and 0MB for the Materialized Table
- 0 MB for the External Table and 0MB for the Materialized Table

### Solution

To check the **estimated** bytes, use the `--dry_run` flag which validates the query without executing it.

**Query for External Table:**
```sql
SELECT DISTINCT PULocationID
FROM `your-project.your-dataset.external_yellow_tripdata_2024`;
```

**Actual command used:**
```bash
bq query --use_legacy_sql=false --dry_run '
SELECT DISTINCT PULocationID
FROM `kestra-sandbook.nytaxi.external_yellow_tripdata_2024`;'
```

**Result:**
```
Query successfully validated. Assuming the tables are not modified, running this
 query will process lower bound of 0 bytes of data.
```

**External Table: 0 bytes = 0 MB**

---

**Query for Materialized Table:**
```sql
SELECT DISTINCT PULocationID
FROM `your-project.your-dataset.yellow_tripdata_2024_materialized`;
```

**Actual command used:**
```bash
bq query --use_legacy_sql=false --dry_run '
SELECT DISTINCT PULocationID
FROM `kestra-sandbook.nytaxi.yellow_tripdata_2024_materialized`;'
```

**Result:**
```
Query successfully validated. Assuming the tables are not modified, running this
 query will process 162656744 bytes of data.
```

**Materialized Table: 162,656,744 bytes = 155.12 MB**

**Answer: 0 MB for the External Table and 155.12 MB for the Materialized Table** ✅

**Explanation:** 
External tables reference data in GCS, so BigQuery cannot accurately estimate bytes without reading file metadata. Materialized tables store data in BigQuery's native columnar format with statistics, enabling accurate size estimation.

---
## Question 3. Understanding columnar storage

Write a query to retrieve the PULocationID from the table (not the external table) in BigQuery. Now write a query to retrieve the PULocationID and DOLocationID on the same table.

Why are the estimated number of Bytes different?
- ✅ BigQuery is a columnar database, and it only scans the specific columns requested in the query. Querying two columns (PULocationID, DOLocationID) requires 
reading more data than querying one column (PULocationID), leading to a higher estimated number of bytes processed.
- BigQuery duplicates data across multiple storage partitions, so selecting two columns instead of one requires scanning the table twice, 
doubling the estimated bytes processed.
- BigQuery automatically caches the first queried column, so adding a second column increases processing time but does not affect the estimated bytes scanned.
- When selecting multiple columns, BigQuery performs an implicit join operation between them, increasing the estimated bytes processed

### Solution

**Query 1: Single Column (PULocationID)**
```sql
SELECT PULocationID
FROM `your-project.your-dataset.yellow_tripdata_2024_materialized`;
```

**Actual command used:**
```bash
bq query --use_legacy_sql=false --dry_run '
SELECT PULocationID
FROM `kestra-sandbook.nytaxi.yellow_tripdata_2024_materialized`
LIMIT 1;'
```

**Result:**
```
Query successfully validated. Assuming the tables are not modified, running this
 query will process 162656744 bytes of data.
```

**1 Column: 162,656,744 bytes = 155.12 MB**

---

**Query 2: Two Columns (PULocationID, DOLocationID)**
```sql
SELECT PULocationID, DOLocationID
FROM `your-project.your-dataset.yellow_tripdata_2024_materialized`;
```

**Actual command used:**
```bash
bq query --use_legacy_sql=false --dry_run '
SELECT PULocationID, DOLocationID
FROM `kestra-sandbook.nytaxi.yellow_tripdata_2024_materialized`
LIMIT 1;'
```

**Result:**
```
Query successfully validated. Assuming the tables are not modified, running this
 query will process 325313488 bytes of data.
```

**2 Columns: 325,313,488 bytes = 310.24 MB (exactly double!)**

---

**Answer:** ✅ **BigQuery is a columnar database, and it only scans the specific columns requested in the query. Querying two columns (PULocationID, DOLocationID) requires reading more data than querying one column (PULocationID), leading to a higher estimated number of bytes processed.**

**Explanation:**  
In columnar storage, each column is stored separately. When you query:
- **1 column** → reads only that column's data (~155 MB)
- **2 columns** → reads both columns' data (~310 MB, exactly 2x)

This demonstrates the efficiency of columnar storage for analytical queries where you typically select a subset of columns from tables with many columns.

---
## Question 4. Counting zero fare trips

How many records have a fare_amount of 0?
- 128,210
- 546,578
- 20,188,016
- ✅ 8,333

### Solution

**SQL Query:**
```sql
SELECT COUNT(*) as zero_fare_trips
FROM `your-project.your-dataset.external_yellow_tripdata_2024`
WHERE fare_amount = 0;
```

**Actual command used:**
```bash
bq query --use_legacy_sql=false '
SELECT COUNT(*) as zero_fare_trips
FROM `kestra-sandbook.nytaxi.external_yellow_tripdata_2024`
WHERE fare_amount = 0;'
```

**Result:**
```
+-----------------+
| zero_fare_trips |
+-----------------+
|            8333 |
+-----------------+
```

**Answer: 8,333** ✅

---
## Question 5. Partitioning and clustering

What is the best strategy to make an optimized table in Big Query if your query will always filter based on tpep_dropoff_datetime and order the results by VendorID (Create a new table with this strategy)

- ✅ Partition by tpep_dropoff_datetime and Cluster on VendorID
- Cluster on by tpep_dropoff_datetime and Cluster on VendorID
- Cluster on tpep_dropoff_datetime Partition by VendorID
- Partition by tpep_dropoff_datetime and Partition by VendorID

### Solution

**Answer:** ✅ **Partition by tpep_dropoff_datetime and Cluster on VendorID**

**Rationale:**
- **Partitioning** by `tpep_dropoff_datetime` allows BigQuery to skip entire partitions when filtering by date, drastically reducing data scanned
- **Clustering** by `VendorID` organizes data within each partition, making filtering and ordering by VendorID more efficient
- This combination optimizes both the WHERE clause (date filter) and ORDER BY clause (VendorID)

**Create the optimized table:**

```sql
CREATE OR REPLACE TABLE `your-project.your-dataset.yellow_tripdata_2024_partitioned_clustered`
PARTITION BY DATE(tpep_dropoff_datetime)
CLUSTER BY VendorID
AS SELECT * FROM `your-project.your-dataset.yellow_tripdata_2024_materialized`;
```

**Actual command used:**
```bash
bq query --use_legacy_sql=false '
CREATE OR REPLACE TABLE `kestra-sandbook.nytaxi.yellow_tripdata_2024_partitioned_clustered`
PARTITION BY DATE(tpep_dropoff_datetime)
CLUSTER BY VendorID
AS SELECT * FROM `kestra-sandbook.nytaxi.yellow_tripdata_2024_materialized`;'
```

**Explanation:**
- **Partitioning**: Splits table into segments by date (e.g., one partition per day)
- **Clustering**: Within each partition, rows are sorted and grouped by VendorID
- **Cannot partition by VendorID**: Partition columns must be DATE, TIMESTAMP, or INTEGER ranges
- **Result**: Queries filtering by date ranges and ordering by VendorID are highly optimized

---

## Question 6. Partition benefits

Write a query to retrieve the distinct VendorIDs between tpep_dropoff_datetime
2024-03-01 and 2024-03-15 (inclusive)


Use the materialized table you created earlier in your from clause and note the estimated bytes. Now change the table in the from clause to the partitioned table you created for question 5 and note the estimated bytes processed. What are these values? 


Choose the answer which most closely matches.
 

- 12.47 MB for non-partitioned table and 326.42 MB for the partitioned table
- ✅ 310.24 MB for non-partitioned table and 26.84 MB for the partitioned table
- 5.87 MB for non-partitioned table and 0 MB for the partitioned table
- 310.31 MB for non-partitioned table and 285.64 MB for the partitioned table

### Solution

**Query on Non-Partitioned Table:**
```sql
SELECT DISTINCT VendorID
FROM `your-project.your-dataset.yellow_tripdata_2024_materialized`
WHERE DATE(tpep_dropoff_datetime) BETWEEN "2024-03-01" AND "2024-03-15";
```

**Actual command used:**
```bash
bq query --use_legacy_sql=false --dry_run '
SELECT DISTINCT VendorID
FROM `kestra-sandbook.nytaxi.yellow_tripdata_2024_materialized`
WHERE DATE(tpep_dropoff_datetime) BETWEEN "2024-03-01" AND "2024-03-15";'
```

**Result:**
```
Query successfully validated. Assuming the tables are not modified, running this
 query will process 325313488 bytes of data.
```

**Non-Partitioned: 325,313,488 bytes = 310.24 MB**

---

**Query on Partitioned Table:**
```sql
SELECT DISTINCT VendorID
FROM `your-project.your-dataset.yellow_tripdata_2024_partitioned_clustered`
WHERE DATE(tpep_dropoff_datetime) BETWEEN "2024-03-01" AND "2024-03-15";
```

**Actual command used:**
```bash
bq query --use_legacy_sql=false --dry_run '
SELECT DISTINCT VendorID
FROM `kestra-sandbook.nytaxi.yellow_tripdata_2024_partitioned_clustered`
WHERE DATE(tpep_dropoff_datetime) BETWEEN "2024-03-01" AND "2024-03-15";'
```

**Result:**
```
Query successfully validated. Assuming the tables are not modified, running this
 query will process upper bound of 28141776 bytes of data.
```

**Partitioned: 28,141,776 bytes = 26.84 MB**

---

**Answer: 310.24 MB for non-partitioned table and 26.84 MB for the partitioned table** ✅

**Savings:** ~91% reduction in data scanned! (310 MB → 27 MB)

**Explanation:**  
The **non-partitioned** table must scan all 6 months of data (Jan-Jun 2024) even though we only need March 1-15.

The **partitioned** table only scans the partitions for March 1-15 (15 days worth of data), completely skipping the other 5.5 months.

This demonstrates the massive cost savings of partitioning for date-range queries in production environments.

---

## Question 7. External table storage

Where is the data stored in the External Table you created?

- Big Query
- Container Registry
- ✅ GCP Bucket
- Big Table

### Solution

**Answer:** ✅ **GCP Bucket**

**Explanation:**  
External tables in BigQuery **do not store data within BigQuery itself**. Instead, they reference data stored externally in:
- **Google Cloud Storage (GCS) buckets** ← Our case
- Google Drive
- Cloud Bigtable

The data remains in the parquet files in the GCS bucket (`gs://kestra-sandbook-taxi-data/yellow_tripdata_2024-*.parquet`), and BigQuery queries it directly from there on-demand.

**Key differences:**
- **External Table**: Data in GCS, metadata in BigQuery
- **Materialized/Regular Table**: Data stored in BigQuery's native format

**Verification:**
```bash
# Check your GCS bucket:
gsutil ls gs://your-bucket-name/yellow_tripdata_2024-*.parquet

# Example (kestra-sandbook-taxi-data):
gsutil ls gs://kestra-sandbook-taxi-data/yellow_tripdata_2024-*.parquet
```

---

## Question 8. Clustering best practices

It is best practice in Big Query to always cluster your data:
- True
- ✅ False

### Solution

**Answer:** ✅ **False**

**Explanation:**  
Clustering is **NOT always beneficial**. It depends on:

**When Clustering HELPS:**
- Tables larger than **1 GB**
- Frequently filter or aggregate on **specific columns**
- Query patterns **consistently use the same columns**
- High cardinality columns (many distinct values)

**When Clustering DOESN'T HELP:**
- **Small tables** (< 1 GB) see negligible improvement
- **Constantly changing query patterns** don't benefit from fixed clustering
- **High cardinality** clustering columns can be inefficient in some cases
- Clustering adds **overhead to data ingestion**

**Best Practice:**  
Analyze your query patterns first, then strategically cluster on columns frequently used in:
- `WHERE` clauses
- `GROUP BY` clauses
- `JOIN` conditions

**Example:**  
Our homework table uses `CLUSTER BY VendorID` because queries filter/order by VendorID. But clustering by `trip_distance` (continuous float) would be less effective.

---

## Question 9. Understanding table scans

No Points: Write a `SELECT count(*)` query FROM the materialized table you created. How many bytes does it estimate will be read? Why?

### Solution

**SQL Query:**
```sql
SELECT COUNT(*)
FROM `your-project.your-dataset.yellow_tripdata_2024_materialized`;
```

**Actual command used:**
```bash
bq query --use_legacy_sql=false --dry_run '
SELECT COUNT(*)
FROM `kestra-sandbook.nytaxi.yellow_tripdata_2024_materialized`;'
```

**Result:**
```
Query successfully validated. Assuming the tables are not modified, running this
 query will process 0 bytes of data.
```

**Bytes Processed: 0 bytes** 🎯

---

**Why 0 bytes?**

BigQuery can answer `SELECT COUNT(*)` queries **without scanning any data** because:

1. **Metadata Storage**: BigQuery stores table metadata including the total row count
2. **Column-Independent**: `COUNT(*)` doesn't require reading any column values
3. **Query Optimization**: The query engine recognizes this pattern and returns the metadata value directly

**Comparison:**
- `COUNT(*)` → **0 bytes** (uses metadata)
- `COUNT(column_name)` → **scans column** (needs to count non-NULL values)
- `COUNT(DISTINCT column_name)` → **scans column** (needs to identify unique values)

**Actual Execution (to get the result):**
```bash
bq query --use_legacy_sql=false '
SELECT COUNT(*) as total_records
FROM `kestra-sandbook.nytaxi.yellow_tripdata_2024_materialized`;'
```

**Result:**
```
+---------------+
| total_records |
+---------------+
|      20332093 |
+---------------+
```

The result is returned **instantly** without processing any data!

---

## Summary Statistics

| Metric | Value |
|--------|-------|
| **Total Records** | 20,332,093 |
| **Zero Fare Trips** | 8,333 (0.041%) |
| **Data Size (GCS)** | 326.1 MiB (6 parquet files) |
| **Date Range** | Jan-Jun 2024 (6 months) |
| **External Table** | 0 MB estimate (metadata unavailable) |
| **Materialized Table (1 col)** | ~155 MB |
| **Materialized Table (2 cols)** | ~310 MB (2x!) |
| **Partitioning Savings** | 91% (310 MB → 27 MB) |

---

## Key Learnings

### 1. External vs Materialized Tables
- **External**: Data stays in GCS, no byte estimates, slower queries
- **Materialized**: Data in BigQuery, accurate estimates, faster queries, costs storage

### 2. Columnar Storage Power
- Only requested columns are scanned
- 1 column = 155 MB, 2 columns = 310 MB (linear scaling)
- Perfect for analytical workloads (select few columns from wide tables)

### 3. Partitioning Strategy
- Date/timestamp partitioning enables **partition pruning**
- Reduced 310 MB → 27 MB for 15-day query (91% savings!)
- Essential for time-series data at scale
- Translates directly to **cost savings** in production

### 4. Clustering Benefits
- Organizes data **within partitions** for faster access
- Best for columns used in WHERE, GROUP BY, ORDER BY
- Works synergistically with partitioning
- Most effective on high-cardinality columns

### 5. Query Optimization Patterns
- `COUNT(*)` uses metadata → **0 bytes**
- Column selection matters → **155 MB vs 310 MB**
- Date filters need partitioning → **91% reduction**
- Use `--dry_run` to estimate costs before executing

### 6. Data Engineering Best Practices
- Always check estimated bytes with `--dry_run` flag
- Partition by date for time-series data
- Cluster by frequently filtered/sorted columns
- External tables for data in GCS/Drive (no duplication)
- Materialized tables for frequently accessed data (better performance)

---

## Cleaning Up GCP Resources

**⚠️ Important:** After completing the homework, clean up your GCP resources to avoid unnecessary costs.

### Resources Created

This homework created the following billable resources:

**BigQuery Dataset: `nytaxi`**
- `external_yellow_tripdata_2024` (external table - no storage cost)
- `yellow_tripdata_2024_materialized` (~310 MB)
- `yellow_tripdata_2024_partitioned_clustered` (~310 MB)

**Cloud Storage Bucket: `kestra-sandbook-taxi-data`**
- 6 parquet files (326.1 MiB total)
- `yellow_tripdata_2024-01.parquet` through `yellow_tripdata_2024-06.parquet`

### Cleanup Commands

**Option 1: Delete Entire Dataset (Recommended)**

Deletes all tables and models in one command:

```bash
# Generic pattern:
bq rm -r -f -d your-project:your-dataset

# Example (kestra-sandbook):
bq rm -r -f -d kestra-sandbook:nytaxi
```

**Option 2: Delete GCS Bucket**

Deletes bucket and all files:

```bash
# Generic pattern:
gsutil rm -r gs://your-bucket-name/

# Example (kestra-sandbook-taxi-data):
gsutil rm -r gs://kestra-sandbook-taxi-data/
```

**Option 3: Delete Individual Tables (if you want to keep the dataset)**

```bash
# Generic pattern:
bq rm -f -t your-project:your-dataset.table_name

# Examples:
bq rm -f -t kestra-sandbook:nytaxi.yellow_tripdata_2024_materialized
bq rm -f -t kestra-sandbook:nytaxi.yellow_tripdata_2024_partitioned_clustered
bq rm -f -t kestra-sandbook:nytaxi.external_yellow_tripdata_2024
```

### Verify Deletion

Check that resources are deleted:

```bash
# Check BigQuery datasets
bq ls --project_id=your-project

# Check GCS buckets
gsutil ls

# Check specific bucket (should return error if deleted)
gsutil ls gs://your-bucket-name/
```

### Cost Impact

**Before cleanup:**
- BigQuery storage: ~620 MB materialized tables → ~$0.012/month
- GCS storage: ~326 MB parquet files → ~$0.008/month
- **Total: ~$0.02/month**

**After cleanup:**
- $0/month ✅

While the monthly cost is minimal, cleaning up is good practice for:
- Avoiding accumulation of test data across multiple projects
- Maintaining organized GCP projects
- Learning proper resource lifecycle management