# GCP Infrastructure Setup for dbt

This directory contains scripts and Terraform configuration to set up the complete GCP infrastructure needed for Module 4: Analytics Engineering with dbt.

<div align="center">

[![GCP](https://img.shields.io/badge/Google_Cloud-4285F4?style=for-the-badge&logo=google-cloud&logoColor=white)](https://cloud.google.com/)
[![BigQuery](https://img.shields.io/badge/BigQuery-4285F4?style=for-the-badge&logo=google-cloud&logoColor=white)](https://cloud.google.com/bigquery)
[![Terraform](https://img.shields.io/badge/Terraform-7B42BC?style=for-the-badge&logo=terraform&logoColor=white)](https://www.terraform.io/)

</div>

## 📋 Overview

This automated setup creates all prerequisites for working with dbt and BigQuery:

- ✅ GCP project with billing enabled
- ✅ Service account with BigQuery permissions
- ✅ BigQuery datasets (`nytaxi`, `dbt_prod`)
- ✅ GCS bucket for data staging
- ✅ NYC Taxi data (yellow and green, 2019-2020) loaded into BigQuery

All resources are configured to use the **EU** location by default.

## 🏗️ Infrastructure Architecture

```
GCP Project
├── Service Account (dbt-bigquery-sa)
│   ├── BigQuery Data Editor
│   ├── BigQuery Job User
│   ├── BigQuery User
│   └── Storage Admin
│
├── BigQuery Datasets (EU location)
│   ├── nytaxi
│   │   ├── yellow_tripdata (2019-2020, ~112M records)
│   │   ├── green_tripdata (2019-2020, ~15M records)
│   │   ├── external_yellow_tripdata (external table)
│   │   └── external_green_tripdata (external table)
│   │
│   └── dbt_prod (base schema for dbt models)
│       └── (dbt will create: dbt_prod_staging, dbt_prod_marts, etc.)
│
└── GCS Bucket
    ├── yellow/*.parquet (24 files)
    └── green/*.parquet (24 files)
```

## 📂 Directory Structure

```
gcp-infrastructure/
├── README.md                     # This file
├── terraform/                    # Terraform infrastructure
│   ├── main.tf                   # Resource definitions
│   ├── variables.tf              # Variable declarations
│   ├── dbt.tfvars.example        # Configuration template
│   ├── dbt.tfvars                # Your config (gitignored)
│   ├── .gitignore                # Security: ignore keys and tfvars
│   └── keys/
│       ├── .gitkeep
│       └── dbt-sa-key.json       # Service account key (gitignored)
│
└── scripts/                      # Setup automation
    ├── 01-setup-project.sh       # Create GCP project
    ├── 02-create-service-account.sh  # Create service account
    ├── 03-load-yellow-taxi.sh    # Load yellow taxi data
    ├── 04-load-green-taxi.sh     # Load green taxi data
    └── verify-setup.sh            # Verify complete setup
```

## 🚀 Quick Start

### Prerequisites

Before starting, install these tools:

```bash
# 1. Google Cloud SDK
# macOS: brew install google-cloud-sdk
# Linux: https://cloud.google.com/sdk/docs/install
gcloud --version

# 2. Terraform
# macOS: brew install terraform
# Linux: https://developer.hashicorp.com/terraform/install
terraform --version

# 3. Authenticate with GCP
gcloud auth login
gcloud auth application-default login
```

You'll also need:
- A GCP billing account (free tier is sufficient for learning)
- Permissions to create projects and service accounts

### Step-by-Step Setup

Navigate to the infrastructure directory:

```bash
cd 04-analytics-engineering/gcp-infrastructure
```

#### Step 1: Create GCP Project

```bash
cd scripts
./01-setup-project.sh
```

This script will:
- Create a new GCP project
- Enable BigQuery and Cloud Storage APIs
- Link your billing account
- Set the project as active

**What you'll provide:**
- Project ID (e.g., `my-dbt-analytics-2026`)
- Project Name (optional)
- Billing Account ID

#### Step 2: Create Service Account

```bash
./02-create-service-account.sh
```

This script will:
- Create service account: `dbt-bigquery-sa`
- Grant required IAM roles
- Generate JSON key file: `../terraform/keys/dbt-sa-key.json`

**Security note:** The key file is automatically added to `.gitignore`. Never commit it!

#### Step 3: Configure Terraform

```bash
cd ../terraform

# Copy the example configuration
cp dbt.tfvars.example dbt.tfvars

# Edit with your values
# Required changes:
#   - project_id: Your GCP project ID from Step 1
#   - bucket_name: Choose a globally unique name (e.g., "my-project-taxi-data")
nano dbt.tfvars  # or use your preferred editor
```

Example `dbt.tfvars`:

```hcl
project_id = "my-dbt-analytics-2026"
region     = "europe-west2"
location   = "EU"
bucket_name = "my-dbt-analytics-2026-taxi-data"
credentials_file_path = "keys/dbt-sa-key.json"
```

#### Step 4: Deploy Infrastructure with Terraform

```bash
# Initialize Terraform (downloads providers)
terraform init

# Preview changes
terraform plan -var-file="dbt.tfvars"

# Apply changes (creates BigQuery datasets and GCS bucket)
terraform apply -var-file="dbt.tfvars"
```

**What gets created:**
- BigQuery dataset: `nytaxi` (EU)
- BigQuery dataset: `dbt_prod` (EU)
- GCS bucket: `{your-bucket-name}` (EU)

#### Step 5: Load Yellow Taxi Data

```bash
cd ../scripts
./03-load-yellow-taxi.sh
```

This script will:
- Download 24 months of yellow taxi data (2019-2020)
- Upload to GCS bucket
- Create external BigQuery table
- Create materialized BigQuery table

**Duration:** ~10-15 minutes (depends on connection speed)

**When prompted:**
- Enter your bucket name (from Step 4)
- Choose whether to delete local files after upload

#### Step 6: Load Green Taxi Data

```bash
./04-load-green-taxi.sh
```

Same process as yellow taxi data, for green taxi trips.

**Duration:** ~5-10 minutes (smaller dataset)

#### Step 7: Verify Setup

```bash
./verify-setup.sh
```

This script checks:
- ✅ Service account exists with correct roles
- ✅ BigQuery datasets created with EU location
- ✅ Tables exist with data
- ✅ GCS bucket accessible with files

## ✅ Verification Checklist

After completing all steps, you should have:

- [ ] GCP project created and billing enabled
- [ ] Service account key file: `terraform/keys/dbt-sa-key.json`
- [ ] BigQuery dataset: `nytaxi` (location: EU)
- [ ] BigQuery dataset: `dbt_prod` (location: EU)
- [ ] BigQuery table: `nytaxi.yellow_tripdata` (~112M records)
- [ ] BigQuery table: `nytaxi.green_tripdata` (~15M records)
- [ ] GCS bucket with yellow and green parquet files

**Quick verification commands:**

```bash
# List datasets
bq ls --project_id=$(gcloud config get-value project)

# Count yellow taxi records
bq query --use_legacy_sql=false \
  'SELECT COUNT(*) FROM `nytaxi.yellow_tripdata`'

# Count green taxi records
bq query --use_legacy_sql=false \
  'SELECT COUNT(*) FROM `nytaxi.green_tripdata`'

# List files in GCS
gsutil ls gs://YOUR-BUCKET-NAME/
```

## 🎯 Next Steps

Now that your GCP infrastructure is ready, you can proceed with dbt setup:

### Option 1: dbt Cloud (Recommended for Beginners)

Follow the guide: [../dbt/setup/cloud_setup.md](../dbt/setup/cloud_setup.md)

**You'll need:**
- Service account key: `terraform/keys/dbt-sa-key.json`
- Project ID
- Dataset location: `EU`

### Option 2: dbt Core (Local Development)

Follow the guide: [../dbt/setup/local_setup.md](../dbt/setup/local_setup.md)

**Advantages:**
- Complete CLI control
- Works offline
- Git-based workflow
- Free (no cloud costs)

## 🧹 Cleanup

To delete all resources and avoid charges:

```bash
# Delete BigQuery tables
bq rm -r -f -d nytaxi
bq rm -r -f -d dbt_prod

# Delete GCS bucket
gsutil rm -r gs://YOUR-BUCKET-NAME/

# Destroy Terraform resources
cd terraform
terraform destroy -var-file="dbt.tfvars"

# Delete service account
gcloud iam service-accounts delete dbt-bigquery-sa@PROJECT_ID.iam.gserviceaccount.com

# Delete project (optional - removes everything)
gcloud projects delete PROJECT_ID
```

## 🔧 Troubleshooting

### "Permission denied" errors

**Solution:** Check that:
1. You're authenticated: `gcloud auth list`
2. Active project is set: `gcloud config get-value project`
3. Billing is enabled: Check GCP Console
4. APIs are enabled: `gcloud services list --enabled`

### "Bucket name already exists"

**Solution:** GCS bucket names are globally unique. Choose a different name in `dbt.tfvars`.

### "Dataset location mismatch"

**Solution:** All datasets must use the same location (EU). Check with:
```bash
bq show --format=prettyjson PROJECT_ID:nytaxi
```

### "File not found" during data loading

**Solution:** The DataTalksClub repository may not have all months. The scripts will warn but continue with available files.

### Terraform state issues

**Solution:** If Terraform gets out of sync:
```bash
cd terraform
terraform refresh -var-file="dbt.tfvars"
```

## 📚 Additional Resources

- [GCP Free Tier](https://cloud.google.com/free) - $300 free credits for new users
- [BigQuery Pricing](https://cloud.google.com/bigquery/pricing) - Understand costs
- [GCS Pricing](https://cloud.google.com/storage/pricing) - Storage costs
- [Terraform GCP Provider](https://registry.terraform.io/providers/hashicorp/google/latest/docs) - Full documentation
- [NYC TLC Data Dictionary](https://www.nyc.gov/assets/tlc/downloads/pdf/data_dictionary_trip_records_yellow.pdf) - Understanding the data

## 🔒 Security Best Practices

1. **Never commit credentials**
   - `terraform/keys/*.json` is gitignored
   - `terraform/dbt.tfvars` is gitignored
   - Always review before pushing to GitHub

2. **Rotate keys periodically**
   ```bash
   # Delete old keys
   gcloud iam service-accounts keys list --iam-account=SA_EMAIL
   gcloud iam service-accounts keys delete KEY_ID --iam-account=SA_EMAIL
   
   # Create new key
   cd scripts
   ./02-create-service-account.sh
   ```

3. **Use least privilege**
   - Service account has only required BigQuery roles
   - No broader permissions than necessary

4. **Monitor costs**
   - Set up billing alerts in GCP Console
   - Review BigQuery queries for efficiency
   - Delete resources when not in use

## 💡 Tips

- **Cost optimization:** BigQuery free tier includes 1 TB of queries per month
- **Data freshness:** The 2019-2020 data is static and won't change
- **Location:** Using EU location for GDPR compliance and European users
- **Terraform state:** Keep `terraform.tfstate` secure - it contains resource IDs

## 📝 License

This setup is part of the [DataTalks.Club Data Engineering Zoomcamp](https://github.com/DataTalksClub/data-engineering-zoomcamp).

---

**Need help?** Check the [dbt setup documentation](../dbt/setup/) or ask in the course Slack channel!
