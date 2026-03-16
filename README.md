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

### ✅ Module 4: Analytics Engineering
**Status:** Completed | **Folder:** [04-analytics-engineering/](04-analytics-engineering/)

**What I learned:**
- **dbt Core fundamentals** - Local CLI-based development with BigQuery adapter
- **Project structure** - Organizing models into staging, intermediate, and core layers
- **Data modeling** - Building dimensional models (facts and dimensions) from raw data
- **Data quality testing** - Implementing automated tests for uniqueness and referential integrity
- **Deduplication strategies** - 4-column composite key approach for handling duplicate records
- **SQL materialization types** - Views vs tables vs incremental models
- **Jinja templating** - Dynamic SQL with variables and macros (e.g., `is_test_run` flag)
- **dbt packages** - Using `dbt_utils` for surrogate keys and testing utilities
- **BigQuery optimization** - QUALIFY window functions for efficient deduplication
- **Data lineage** - Understanding upstream/downstream dependencies between models

**Key deliverables:**
- [Homework 04](04-analytics-engineering/homework04/homework04.md) - dbt modeling and transformation exercises ✅
- Complete dbt project with 8 models across 3 layers (staging, intermediate, core)
- Processed 130M+ raw records → 112M deduplicated trips
- Fact tables: `fct_trips` (112M records), `fct_monthly_zone_revenue` (11,662 aggregations)
- Data quality tests with 9 assertions covering uniqueness and relationships
- Terraform-managed GCP infrastructure (service account, BigQuery datasets)

**Technologies used:** dbt Core, BigQuery, SQL, Jinja, Python, GCP, Terraform, uv (package manager)

**Hybrid Approach (different from course guides):**
Instead of using dbt Cloud (the course's recommended web IDE), I opted for a **local-first hybrid setup**:
- **Local:** dbt Core CLI + VSCode for development, Git for version control
- **Cloud:** BigQuery for data warehouse and SQL execution
- **Infrastructure as Code:** Terraform for GCP resource provisioning (service accounts, BigQuery datasets, IAM roles)
- **Why:** Better IDE experience, full control over environment, reproducible infrastructure, and no vendor lock-in
- **Trade-off:** Manual setup (Terraform configs, service accounts, profiles.yml) vs dbt Cloud's one-click setup

This approach mirrors real-world production environments where teams prefer local development with cloud compute and infrastructure automation.

**dbt Model Architecture:**
| Layer | Model | Purpose | Record Count |
|-------|-------|---------|--------------|
| Staging | `stg_green_tripdata` | Clean & standardize green taxi data | ~2M records |
| Staging | `stg_yellow_tripdata` | Clean & standardize yellow taxi data | ~130M records |
| Staging | `stg_fhv_tripdata` | Clean & standardize FHV data | 43.2M records |
| Intermediate | `int_trips_unioned` | Union yellow + green taxi data | 114M records |
| Intermediate | `int_trips` | Deduplicate using 4-column key | 112M records |
| Core | `fct_trips` | Enriched trip facts with zone names | 112M records |
| Core | `fct_monthly_zone_revenue` | Monthly revenue aggregations | 11,662 records |

**Deduplication Strategy:**

**Key Learning:**
dbt transforms the data warehouse into a development environment with version control, testing, and documentation. The layered architecture (staging → intermediate → core) creates maintainable transformations: staging cleans raw data, intermediate handles business logic (like deduplication), and core creates analytics-ready tables. Using local dbt Core with a cloud data warehouse (BigQuery) provides the best of both worlds—powerful IDE experience locally with scalable compute in the cloud. The 4-column deduplication strategy proved critical: deduplicating only on `vendorid + pickup_datetime` wasn't enough; adding `pickup_locationid + service_type` captured the true uniqueness of trip records.

### ✅ Module 5: Data Platforms
**Status:** Completed | **Folder:** [05-data-platforms/](05-data-platforms/)

**What I learned:**
- **Bruin CLI fundamentals** – Unified tool for data ingestion, transformation, orchestration, and governance
- **Pipeline architecture** – Layered approach (ingestion, staging, reporting) for NYC Taxi data
- **Incremental processing** – Using `time_interval` materialization for efficient updates
- **Quality checks & lineage** – Built-in validation and visualization of data flows
- **Asset management** – Version-controlled assets (Python, SQL, YAML, CSV) for reproducible pipelines
- **AI agent integration** – Conversational pipeline development and troubleshooting with Bruin MCP
- **Cloud deployment** – Managed infrastructure and cloud-native workflows with Bruin Cloud
- **Quick feedback cycles** – Local-first development with rapid iteration

**Key deliverables:**
- [Homework 05](05-data-platforms/homework05/homework05.md) – Bruin CLI, pipeline, and platform exercises ✅
- Complete Bruin project structure: `.bruin.yml`, `pipeline/pipeline.yml`, and layered assets
- End-to-end NYC Taxi pipeline (ingestion, staging, reporting)
- Reference notes and video tutorials for Bruin and data platform concepts

**Technologies used:** Bruin CLI, VS Code extension, DuckDB, BigQuery, Python, SQL, YAML

**Bruin Platform Highlights:**
| Feature | Purpose | Result |
|--------|---------|--------|
| Unified CLI | Ingestion, transformation, orchestration, governance | One tool for all workflows |
| Layered pipeline | Modular asset structure | Reproducible, extensible pipelines |
| Incremental materialization | Efficient updates | Fast, scalable processing |
| Quality checks | Data validation | Reliable pipelines |
| Lineage visualization | Data flow tracking | Transparent dependencies |
| AI agent (MCP) | Conversational development | Fast troubleshooting & building |
| Cloud deployment | Managed infrastructure | Scalable, production-ready workflows |

**Unique Approaches:**
- AI-assisted pipeline development and troubleshooting (Bruin MCP)
- All pipeline configuration and assets are version-controlled text files (no UI lock-in)
- Mix-and-match asset types (Python, SQL, YAML, CSV) in a single pipeline
- Emphasis on quick feedback cycles and local development

**Key Learning:**
Module 5 demonstrates a modern, unified data platform workflow using Bruin CLI. The approach emphasizes reproducibility, quality, extensibility, and rapid iteration. AI integration and version-controlled assets enable flexible, scalable pipelines suitable for both local and cloud environments.

---

### ✅ Module 6: Batch Processing
**Status:** Completed | **Folder:** [06-batch/](06-batch/)

**What I learned:**
- **Batch processing fundamentals** - Why batch workloads matter and where Spark fits in modern data platforms
- **Spark setup and local development** - Installing Java/PySpark and creating local Spark sessions
- **Spark DataFrames and Spark SQL** - Reading parquet/CSV data, transformations, aggregations, and SQL-based analysis
- **Schema and storage handling** - Working with taxi schemas, parquet output, and partition/repartition strategies
- **Spark internals** - Cluster anatomy, execution behavior, and performance implications of groupBy and joins
- **RDD concepts (optional)** - Lower-level distributed operations including `mapPartitions`
- **Cloud execution patterns** - Spark with GCS, local clusters, Dataproc setup, and BigQuery connectivity
- **Validation through homework** - Applying class concepts on NYC Taxi November 2025 data to confirm understanding

**Key deliverables:**
- [Homework 06](06-batch/homework06/homework06.md) - Spark batch-processing exercises and validated answers ✅
- Reproducible solver script: [homework_queries.py](06-batch/homework06/homework_queries.py)
- Completed class materials and notebooks in [06-batch/class_materials/code/](06-batch/class_materials/code/)
- End-to-end analysis on Yellow Taxi November 2025 data using Spark DataFrames and joins

**Technologies used:** Apache Spark, PySpark, Spark SQL, Python, Parquet, CSV, Java, GCS, Dataproc, BigQuery

**Spark Learning Highlights:**
| Topic | What was practiced | Outcome |
|------|---------------------|---------|
| Spark setup | Local session, runtime verification, Spark UI | Working Spark 4.1.1 environment |
| DataFrames + SQL | Filters, aggregations, SQL queries on taxi data | Reproducible batch analysis |
| Partitioning strategy | `repartition(4)` and parquet output sizing | Controlled file layout and storage behavior |
| GroupBy + joins | Pickup zone frequency with lookup joins | Correct low-frequency zone identification |
| Duration calculations | Timestamp-based trip duration metrics | Accurate max duration computation |
| Cloud patterns | GCS/Dataproc/BigQuery integration concepts | Clear path from local to cloud execution |

**Key Learning:**
Module 6 reinforced that Spark is not only about writing transformations; it is about understanding execution patterns, partitioning behavior, and data layout decisions. The homework served as a practical validation layer for the class materials, confirming both conceptual understanding and implementation accuracy on a real dataset.

---

### ✅ Module 7: Stream Processing
**Status:** Completed | **Folder:** [07-streaming/](07-streaming/)

**What I learned:**
- **Streaming fundamentals** - Event-driven architecture and the role of message brokers in real-time data pipelines
- **Redpanda** - Kafka-compatible broker with simpler operational model; topic creation and management via `rpk` CLI
- **Kafka-Python producer/consumer** - Serializing records to JSON, batching, and consuming messages from topics
- **PyFlink Table API** - Defining schemas, creating Kafka source/PostgreSQL sink DDLs, and running streaming SQL jobs
- **Windowed aggregations** - TUMBLE windows (fixed 5-min intervals) for trip counts and SESSION windows (gap-based) for session analysis
- **Watermarks and event time** - Defining watermarks via computed columns to handle late-arriving events
- **JDBC sink connector** - Writing Flink results to PostgreSQL tables using the Flink JDBC connector
- **End-to-end streaming pipeline** - Producer → Redpanda → Flink job → PostgreSQL, all orchestrated with Docker Compose

**Key deliverables:**
- [Homework 07](07-streaming/homework07/homework07.md) - Streaming exercises with Redpanda, kafka-python, and PyFlink ✅
- Workshop stack: Docker Compose environment with Redpanda, Flink JobManager + TaskManager, and PostgreSQL
- Green Taxi October 2025 dataset (49,416 trips) streamed and windowed in real time

**Technologies used:** Redpanda, Apache Flink (PyFlink), Kafka-Python, PostgreSQL, Docker Compose, Python, Parquet

**Streaming Pipeline Highlights:**
| Component | Role | Key Detail |
|-----------|------|-----------|
| Redpanda | Message broker | Kafka-compatible, `v25.3.9`, `green-trips` topic |
| kafka-python KafkaProducer | Data ingestion | JSON-serialized rows, ~2.92 s for full dataset |
| PyFlink Table API | Stream processing | SQL-based windowed aggregations |
| TUMBLE(5 min) window | Trip count per zone | PULocationID 74 — 15 trips (top zone) |
| SESSION(5 min gap) window | Session analysis | Longest session: 81 trips for PULocationID 74 |
| PostgreSQL JDBC sink | Result storage | Flink writes aggregated results to DB tables |

**Key Learning:**
Module 7 demonstrated how real-time streaming pipelines differ from batch jobs: events are processed continuously as they arrive, windowing (TUMBLE and SESSION) replaces GROUP BY on static data, and watermarks control how late events are handled. Redpanda's Kafka-compatible API made it easy to reuse standard kafka-python clients while keeping the broker lightweight. PyFlink's Table API enables declarative SQL over streaming data, bridging the gap between familiar batch SQL and low-latency stream processing.
