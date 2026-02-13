#!/bin/bash

# Script to load FHV (For-Hire Vehicle) taxi data for 2019 into BigQuery
# This script downloads CSV.GZ files from DataTalksClub and loads them into the nytaxi.fhv_tripdata table

set -e

PROJECT_ID="ny-taxi-dbt-zoomcamp"
DATASET="nytaxi"
TABLE="fhv_tripdata"
YEAR="2019"
BASE_URL="https://github.com/DataTalksClub/nyc-tlc-data/releases/download/fhv"

echo "======================================"
echo "Loading FHV Taxi Data into BigQuery"
echo "======================================"
echo "Project: $PROJECT_ID"
echo "Dataset: $DATASET"
echo "Table: $TABLE"
echo "Year: $YEAR"
echo ""

# Create table if it doesn't exist (will use auto-detect on first load)
echo "Step 1: Creating/checking table $DATASET.$TABLE"

# Load data for each month
for MONTH in {01..12}; do
    FILE="fhv_tripdata_2019-${MONTH}.csv.gz"
    URL="${BASE_URL}/${FILE}"
    
    echo ""
    echo "Step 2.$MONTH: Loading $FILE"
    echo "URL: $URL"
    
    # Download file
    echo "Downloading..."
    curl -L -o "/tmp/$FILE" "$URL"
    
    # Load to BigQuery
    # First month creates the table with schema auto-detection
    if [ "$MONTH" = "01" ]; then
        bq load \
            --project_id="$PROJECT_ID" \
            --location=EU \
            --source_format=CSV \
            --skip_leading_rows=1 \
            --autodetect \
            --replace \
            "${DATASET}.${TABLE}" \
            "/tmp/$FILE"
    else
        # Subsequent months append to existing table
        bq load \
            --project_id="$PROJECT_ID" \
            --location=EU \
            --source_format=CSV \
            --skip_leading_rows=1 \
            --noreplace \
            "${DATASET}.${TABLE}" \
            "/tmp/$FILE"
    fi
    
    # Clean up
    rm "/tmp/$FILE"
    
    echo "✓ Loaded $FILE"
done

echo ""
echo "======================================"
echo "Data Load Complete!"
echo "======================================"
echo ""
echo "Verifying row count..."
bq query --use_legacy_sql=false --format=prettyjson \
    "SELECT COUNT(*) as total_rows FROM \`${PROJECT_ID}.${DATASET}.${TABLE}\`"

echo ""
echo "Sample of 5 rows:"
bq query --use_legacy_sql=false --format=pretty \
    "SELECT * FROM \`${PROJECT_ID}.${DATASET}.${TABLE}\` LIMIT 5"

echo ""
echo "Schema:"
bq show --format=prettyjson "${PROJECT_ID}:${DATASET}.${TABLE}"

echo ""
echo "Done!"
