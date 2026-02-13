#!/bin/bash

# ==============================================================================
# Green Taxi Data Loading Script
# ==============================================================================
# Downloads green taxi trip data for 2019-2020 from DataTalksClub repository,
# uploads to GCS, and creates BigQuery tables
#
# Prerequisites:
# - gcloud CLI, gsutil, and bq CLI installed
# - GCP project configured with active project set
# - Terraform infrastructure already deployed (datasets and bucket created)
# - Service account with BigQuery and Storage permissions
#
# Usage:
#   ./04-load-green-taxi.sh
# ==============================================================================

set -e # Exit on error

echo "=========================================="
echo "Green Taxi Data Loading (2019-2020)"
echo "=========================================="
echo

# Check required tools
for cmd in gcloud gsutil bq curl; do
    if ! command -v $cmd &> /dev/null; then
        echo "❌ Error: $cmd is not installed"
        exit 1
    fi
done

# Get configuration
PROJECT_ID=$(gcloud config get-value project 2>/dev/null)
if [ -z "$PROJECT_ID" ]; then
    echo "❌ Error: No active GCP project"
    exit 1
fi

echo "Active Project: $PROJECT_ID"
echo

# Prompt for bucket name
echo "Enter your GCS bucket name (from Terraform output):"
read -p "Bucket name: " BUCKET_NAME

if [ -z "$BUCKET_NAME" ]; then
    echo "❌ Error: Bucket name cannot be empty"
    exit 1
fi

# Configuration
DATASET_ID="nytaxi"
TABLE_NAME="green_tripdata"
EXTERNAL_TABLE_NAME="external_green_tripdata"
DATA_DIR="./green_taxi_data"
BASE_URL="https://github.com/DataTalksClub/nyc-tlc-data/releases/download/green"

# Create temporary directory for downloads
mkdir -p "$DATA_DIR"
cd "$DATA_DIR"

echo "----------------------------------------"
echo "Downloading green taxi data..."
echo "Years: 2019-2020 (24 months)"
echo "Source: DataTalksClub NYC TLC Data"
echo "----------------------------------------"
echo

# Download files for 2019 and 2020
for year in 2019 2020; do
    for month in {01..12}; do
        filename="green_tripdata_${year}-${month}.csv.gz"
        url="${BASE_URL}/${filename}"
        
        echo "Downloading: $filename"
        
        if curl -f -L -o "$filename" "$url" 2>/dev/null; then
            echo "✅ Downloaded: $filename"
        else
            echo "⚠️  Warning: Could not download $filename (file may not exist)"
        fi
    done
done

echo
echo "Download complete!"
echo

# Count downloaded files
FILE_COUNT=$(ls -1 green_tripdata_*.csv.gz 2>/dev/null | wc -l)
echo "Files downloaded: $FILE_COUNT"

if [ "$FILE_COUNT" -eq 0 ]; then
    echo "❌ Error: No files were downloaded"
    exit 1
fi

# Upload to GCS
echo
echo "----------------------------------------"
echo "Uploading to GCS..."
echo "Bucket: gs://$BUCKET_NAME/green/"
echo "----------------------------------------"
echo

gsutil -m cp green_tripdata_*.csv.gz "gs://$BUCKET_NAME/green/"

echo "✅ Upload complete"

# Verify upload
echo
echo "Verifying files in GCS..."
gsutil ls "gs://$BUCKET_NAME/green/" | head -5
FILE_COUNT_GCS=$(gsutil ls "gs://$BUCKET_NAME/green/*.csv.gz" | wc -l)
echo "Files in GCS: $FILE_COUNT_GCS"

# Create external table in BigQuery
echo
echo "----------------------------------------"
echo "Creating BigQuery external table..."
echo "Dataset: $DATASET_ID"
echo "Table: $EXTERNAL_TABLE_NAME"
echo "----------------------------------------"

bq query --use_legacy_sql=false "
CREATE OR REPLACE EXTERNAL TABLE \`${PROJECT_ID}.${DATASET_ID}.${EXTERNAL_TABLE_NAME}\`
OPTIONS (
  format = 'CSV',
  compression = 'GZIP',
  uris = ['gs://${BUCKET_NAME}/green/*.csv.gz'],
  skip_leading_rows = 1
);
"

echo "✅ External table created: ${DATASET_ID}.${EXTERNAL_TABLE_NAME}"

# Create materialized table
echo
echo "----------------------------------------"
echo "Creating materialized BigQuery table..."
echo "Table: $TABLE_NAME"
echo "This may take a few minutes..."
echo "----------------------------------------"

bq query --use_legacy_sql=false "
CREATE OR REPLACE TABLE \`${PROJECT_ID}.${DATASET_ID}.${TABLE_NAME}\`
AS SELECT * FROM \`${PROJECT_ID}.${DATASET_ID}.${EXTERNAL_TABLE_NAME}\`;
"

echo "✅ Materialized table created: ${DATASET_ID}.${TABLE_NAME}"

# Get row count
echo
echo "Counting records..."
ROW_COUNT=$(bq query --use_legacy_sql=false --format=csv "
SELECT COUNT(*) as count FROM \`${PROJECT_ID}.${DATASET_ID}.${TABLE_NAME}\`
" | tail -n 1)

echo "✅ Total records: $ROW_COUNT"

# Cleanup local files
cd ..
echo
read -p "Do you want to delete local parquet files? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    rm -rf "$DATA_DIR"
    echo "✅ Local files deleted"
else
    echo "Local files kept in: $DATA_DIR"
fi

# Summary
echo
echo "=========================================="
echo "✅ GREEN TAXI DATA LOADED"
echo "=========================================="
echo "Project: $PROJECT_ID"
echo "Dataset: $DATASET_ID"
echo "External Table: $EXTERNAL_TABLE_NAME"
echo "Materialized Table: $TABLE_NAME"
echo "Total Records: $ROW_COUNT"
echo "GCS Location: gs://$BUCKET_NAME/green/"
echo
echo "Next steps:"
echo "1. Verify complete setup: ./verify-setup.sh"
echo "2. Configure dbt Cloud or dbt Core"
echo "=========================================="
