# dataengineering-zoomcamp-2026
Datatalks homeworks and exercises for DE Zoomcamp 2026

## 📚 Course Progress

### ✅ Module 1: Containerization and Infrastructure as Code
**Status:** Completed | **Folder:** [01-docker-terraform/](01-docker-terraform/)

**What I learned:**
- **Docker fundamentals** - Container lifecycle, volumes, and data persistence
- **Docker networking** - Container communication and port mapping
- **Docker Compose** - Multi-service orchestration (PostgreSQL + pgAdmin)
- **Data pipelines** - NYC Taxi data ingestion using Python, pandas, and SQLAlchemy
- **SQL queries** - Data analysis on PostgreSQL databases
- **Terraform for GCP** - Infrastructure as Code for Google Cloud (Storage + BigQuery)
- **Terraform for AWS** - Equivalent AWS infrastructure (S3 + Glue Catalog)
- **Best practices** - Environment variables, `.gitignore` for credentials, and project structure

**Key deliverables:**
- [Homework 01](01-docker-terraform/homework01/homework01.md) - Docker, SQL, and Terraform exercises ✅
- Working PostgreSQL + pgAdmin environment via Docker Compose
- Python data ingestion scripts for parquet and CSV files
- Terraform configurations for [GCP](01-docker-terraform/terraform_gcp/) and [AWS](01-docker-terraform/terraform_aws/) resource provisioning

**Technologies used:** Docker, PostgreSQL, pgAdmin, Python, pandas, SQLAlchemy, Terraform, GCP, AWS

**Cloud Service Comparison - GCP vs AWS:**
| GCP Service | AWS Equivalent | Purpose |
|-------------|----------------|---------|
| Google Cloud Storage (GCS) | Amazon S3 | Data Lake storage |
| Uniform Bucket Level Access | S3 Public Access Block | Secure bucket access |
| Object Lifecycle Rules | S3 Lifecycle Configuration | Automatic data expiration |
| BigQuery Dataset | AWS Glue Catalog Database | Metadata & query layer |
| Service Account JSON Key | IAM User Profile (AWS CLI) | Authentication |

**Authentication Difference:**
- **GCP**: Requires `my-creds.json` service account key file
- **AWS**: Uses IAM profile from `~/.aws/credentials` (no separate file needed)

---

### ✅ Module 2: Workflow Orchestration
**Status:** Completed | **Folder:** [02-workflow-orchestration/](02-workflow-orchestration/)

**What I learned:**
- **Kestra fundamentals** - Modern declarative workflow orchestration platform
- **ETL pipeline orchestration** - Extract, transform, and load NYC taxi data to GCP
- **Variables and expressions** - Dynamic workflow configuration using Jinja templating
- **Backfill functionality** - Historical data processing for multiple time periods
- **Scheduled triggers** - Automated workflow execution with timezone support
- **GCP integration** - Cloud Storage and BigQuery data loading
- **Secrets management** - Secure credential handling with base64 encoding
- **Docker Compose orchestration** - Multi-service setup (Kestra + PostgreSQL + pgAdmin)

**Key deliverables:**
- [Homework 02](02-workflow-orchestration/homework02/homework02.md) - Workflow orchestration and data pipeline exercises ✅
- Working Kestra instance with PostgreSQL backend via Docker Compose
- Automated ETL flows processing millions of taxi trip records
- GCP bucket and BigQuery dataset created via Terraform-like flows
- Backfill executions for all 2020 data (Yellow: 24.6M rows, Green: 1.7M rows)

**Technologies used:** Kestra, Docker, PostgreSQL, Python, GCP (Cloud Storage + BigQuery), Gemini AI

**Kestra Workflow Highlights:**
| Flow | Purpose | Data Processed |
|------|---------|----------------|
| 08_gcp_taxi | Manual ETL execution | Single month of taxi data |
| 09_gcp_taxi_scheduled | Scheduled ETL with backfill | Multiple months via cron triggers |
| 06_gcp_kv | Configuration management | Stores GCP project settings |
| 07_gcp_setup | Infrastructure provisioning | Creates GCS bucket + BigQuery dataset |

**Data Pipeline Results:**
- **Yellow Taxi (2020):** 24,648,499 records across 12 months
- **Green Taxi (2020):** 1,734,051 records across 12 months
- **Yellow Taxi (March 2021):** 1,925,152 records
- **File size example:** 128.3 MiB uncompressed CSV for Dec 2020

---

### ✅ Module 3: Data Warehouse
**Status:** Completed | **Folder:** [03-data-warehouse/](03-data-warehouse/)

**What I learned:**
- **BigQuery fundamentals** - External tables, materialized tables, and native BigQuery storage
- **Partitioning strategies** - Date-based partitioning for query optimization (91% cost reduction)
- **Clustering techniques** - Organizing data within partitions for faster access
- **Columnar storage** - Understanding how BigQuery scans only requested columns
- **Query optimization** - Using `--dry_run` to estimate costs before execution
- **Cost management** - Cleanup strategies to avoid unnecessary GCP charges
- **GCS integration** - Creating external tables referencing Cloud Storage data
- **Data analysis at scale** - Working with 20.3M taxi trip records across 6 months

**Key deliverables:**
- [Homework 03](03-data-warehouse/homework03/homework03.md) - BigQuery & Data Warehousing exercises ✅
- External and materialized tables with 20.3M records (326.1 MiB parquet data)
- Partitioned and clustered table achieving 91% query cost reduction (310MB → 27MB)
- Complete cost analysis and GCP resource cleanup documentation
- SQL queries demonstrating columnar storage efficiency and metadata optimization

**Technologies used:** BigQuery, Google Cloud Storage, bq CLI, gsutil, SQL, Parquet

**BigQuery Optimization Results:**
| Optimization Technique | Before | After | Savings |
|------------------------|--------|-------|---------|
| Partitioning (date-range query) | 310.24 MB | 26.84 MB | 91% reduction |
| Columnar storage (2 cols vs 1) | 155 MB | 310 MB | Linear scaling |
| COUNT(*) metadata usage | N/A | 0 bytes | 100% (no scan) |
| External vs Materialized estimation | 0 MB | 155.12 MB | Accurate sizing |

**Key Learning:**
Partitioning by date (`tpep_dropoff_datetime`) + clustering by frequently filtered columns (`VendorID`) creates a powerful optimization strategy. For a 15-day query window on 6 months of data, partitioning achieved 91% reduction in data scanned (from 310 MB to 27 MB), translating directly to cost savings in production. Understanding the difference between external tables (data in GCS, no storage cost) and materialized tables (data in BigQuery, faster queries but storage cost) is crucial for cost optimization.

---
