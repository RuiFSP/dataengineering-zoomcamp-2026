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

### 🔄 Module 2: Workflow Orchestration
**Status:** Not Started | **Folder:** [02-workflow-orchestration/](02-workflow-orchestration/)

*Coming soon...*
