#!/bin/bash

# ==============================================================================
# Verification Script for GCP Infrastructure Setup
# ==============================================================================
# Verifies that all components are properly configured:
# - Service account exists and has correct permissions
# - BigQuery datasets are created with correct location
# - BigQuery tables exist with data
# - GCS bucket exists with data
#
# Usage:
#   ./verify-setup.sh
# ==============================================================================

set -e # Exit on error

echo "=========================================="
echo "GCP Infrastructure Verification"
echo "=========================================="
echo

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check counters
PASSED=0
FAILED=0

# Helper functions
pass() {
    echo -e "${GREEN}✅ PASS:${NC} $1"
    ((PASSED++))
}

fail() {
    echo -e "${RED}❌ FAIL:${NC} $1"
    ((FAILED++))
}

warn() {
    echo -e "${YELLOW}⚠️  WARN:${NC} $1"
}

# Check if gcloud is installed
if ! command -v gcloud &> /dev/null; then
    fail "gcloud CLI is not installed"
    exit 1
fi

# Get active project
PROJECT_ID=$(gcloud config get-value project 2>/dev/null)

if [ -z "$PROJECT_ID" ]; then
    fail "No active GCP project set"
    echo "Run: gcloud config set project YOUR_PROJECT_ID"
    exit 1
fi

echo "Verifying project: $PROJECT_ID"
echo

# 1. Check Service Account
echo "=========================================="
echo "1. Service Account Verification"
echo "=========================================="

SA_EMAIL="dbt-bigquery-sa@${PROJECT_ID}.iam.gserviceaccount.com"

if gcloud iam service-accounts describe "$SA_EMAIL" &>/dev/null; then
    pass "Service account exists: $SA_EMAIL"
    
    # Check roles
    ROLES=$(gcloud projects get-iam-policy "$PROJECT_ID" \
        --flatten="bindings[].members" \
        --filter="bindings.members:serviceAccount:$SA_EMAIL" \
        --format="value(bindings.role)")
    
    if echo "$ROLES" | grep -q "roles/bigquery.dataEditor"; then
        pass "Has BigQuery Data Editor role"
    else
        fail "Missing BigQuery Data Editor role"
    fi
    
    if echo "$ROLES" | grep -q "roles/bigquery.jobUser"; then
        pass "Has BigQuery Job User role"
    else
        fail "Missing BigQuery Job User role"
    fi
    
    if echo "$ROLES" | grep -q "roles/bigquery.user"; then
        pass "Has BigQuery User role"
    else
        fail "Missing BigQuery User role"
    fi
    
    if echo "$ROLES" | grep -q "roles/storage.admin"; then
        pass "Has Storage Admin role"
    else
        warn "Missing Storage Admin role (needed for GCS access)"
    fi
else
    fail "Service account not found: $SA_EMAIL"
fi

# Check key file
KEY_FILE="../terraform/keys/dbt-sa-key.json"
if [ -f "$KEY_FILE" ]; then
    pass "Service account key file exists: $KEY_FILE"
else
    fail "Service account key file not found: $KEY_FILE"
fi

echo

# 2. Check BigQuery Datasets
echo "=========================================="
echo "2. BigQuery Datasets Verification"
echo "=========================================="

# Check nytaxi dataset
if bq show --format=prettyjson "${PROJECT_ID}:nytaxi" &>/dev/null; then
    pass "Dataset exists: nytaxi"
    
    # Check location
    LOCATION=$(bq show --format=prettyjson "${PROJECT_ID}:nytaxi" | grep -o '"location": "[^"]*"' | cut -d'"' -f4)
    if [ "$LOCATION" = "EU" ]; then
        pass "Dataset location is EU"
    else
        warn "Dataset location is $LOCATION (expected EU)"
    fi
else
    fail "Dataset not found: nytaxi"
fi

# Check dbt_prod dataset
if bq show --format=prettyjson "${PROJECT_ID}:dbt_prod" &>/dev/null; then
    pass "Dataset exists: dbt_prod"
    
    # Check location
    LOCATION=$(bq show --format=prettyjson "${PROJECT_ID}:dbt_prod" | grep -o '"location": "[^"]*"' | cut -d'"' -f4)
    if [ "$LOCATION" = "EU" ]; then
        pass "Dataset location is EU"
    else
        warn "Dataset location is $LOCATION (expected EU)"
    fi
else
    fail "Dataset not found: dbt_prod"
fi

echo

# 3. Check BigQuery Tables
echo "=========================================="
echo "3. BigQuery Tables Verification"
echo "=========================================="

# Check yellow_tripdata table
if bq show "${PROJECT_ID}:nytaxi.yellow_tripdata" &>/dev/null; then
    pass "Table exists: nytaxi.yellow_tripdata"
    
    # Get row count
    YELLOW_COUNT=$(bq query --use_legacy_sql=false --format=csv \
        "SELECT COUNT(*) as count FROM \`${PROJECT_ID}.nytaxi.yellow_tripdata\`" 2>/dev/null | tail -n 1)
    
    if [ ! -z "$YELLOW_COUNT" ] && [ "$YELLOW_COUNT" -gt 0 ]; then
        pass "Yellow taxi data loaded: $YELLOW_COUNT records"
    else
        fail "Yellow taxi table is empty"
    fi
else
    fail "Table not found: nytaxi.yellow_tripdata"
fi

# Check green_tripdata table
if bq show "${PROJECT_ID}:nytaxi.green_tripdata" &>/dev/null; then
    pass "Table exists: nytaxi.green_tripdata"
    
    # Get row count
    GREEN_COUNT=$(bq query --use_legacy_sql=false --format=csv \
        "SELECT COUNT(*) as count FROM \`${PROJECT_ID}.nytaxi.green_tripdata\`" 2>/dev/null | tail -n 1)
    
    if [ ! -z "$GREEN_COUNT" ] && [ "$GREEN_COUNT" -gt 0 ]; then
        pass "Green taxi data loaded: $GREEN_COUNT records"
    else
        fail "Green taxi table is empty"
    fi
else
    fail "Table not found: nytaxi.green_tripdata"
fi

echo

# 4. Check GCS Bucket (optional - requires bucket name)
echo "=========================================="
echo "4. GCS Bucket Verification (Optional)"
echo "=========================================="

echo "Enter your GCS bucket name (or press Enter to skip):"
read -p "Bucket name: " BUCKET_NAME

if [ ! -z "$BUCKET_NAME" ]; then
    if gsutil ls "gs://$BUCKET_NAME" &>/dev/null; then
        pass "Bucket exists: gs://$BUCKET_NAME"
        
        # Check yellow data
        YELLOW_FILES=$(gsutil ls "gs://$BUCKET_NAME/yellow/*.parquet" 2>/dev/null | wc -l)
        if [ "$YELLOW_FILES" -gt 0 ]; then
            pass "Yellow taxi files in GCS: $YELLOW_FILES files"
        else
            warn "No yellow taxi files found in GCS"
        fi
        
        # Check green data
        GREEN_FILES=$(gsutil ls "gs://$BUCKET_NAME/green/*.parquet" 2>/dev/null | wc -l)
        if [ "$GREEN_FILES" -gt 0 ]; then
            pass "Green taxi files in GCS: $GREEN_FILES files"
        else
            warn "No green taxi files found in GCS"
        fi
    else
        fail "Bucket not found or no access: gs://$BUCKET_NAME"
    fi
else
    warn "GCS bucket verification skipped"
fi

echo

# Summary
echo "=========================================="
echo "VERIFICATION SUMMARY"
echo "=========================================="
echo -e "${GREEN}Passed: $PASSED${NC}"
echo -e "${RED}Failed: $FAILED${NC}"
echo

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}✅ ALL CHECKS PASSED${NC}"
    echo
    echo "Your GCP infrastructure is ready for dbt!"
    echo
    echo "Next steps:"
    echo "1. Set up dbt Cloud (see: ../dbt/setup/cloud_setup.md)"
    echo "2. Or set up dbt Core locally (see: ../dbt/setup/local_setup.md)"
    echo "3. Use service account key: $KEY_FILE"
else
    echo -e "${RED}❌ SOME CHECKS FAILED${NC}"
    echo
    echo "Please review the failed checks above and:"
    echo "1. Re-run the appropriate setup scripts"
    echo "2. Check for error messages during setup"
    echo "3. Verify your GCP permissions"
fi

echo "=========================================="
