#!/bin/bash

# ==============================================================================
# Service Account Setup Script for dbt + BigQuery
# ==============================================================================
# This script creates a service account with BigQuery permissions and generates
# a JSON key file for authentication
#
# Prerequisites:
# - gcloud CLI installed and authenticated
# - GCP project already created (run 01-setup-project.sh first)
# - Active project set: gcloud config set project PROJECT_ID
#
# Usage:
#   ./02-create-service-account.sh
# ==============================================================================

set -e # Exit on error

echo "=========================================="
echo "Service Account Setup for dbt + BigQuery"
echo "=========================================="
echo

# Check if gcloud is installed
if ! command -v gcloud &> /dev/null; then
    echo "❌ Error: gcloud CLI is not installed"
    exit 1
fi

# Get the active project
PROJECT_ID=$(gcloud config get-value project 2>/dev/null)

if [ -z "$PROJECT_ID" ]; then
    echo "❌ Error: No active GCP project"
    echo "Run: gcloud config set project YOUR_PROJECT_ID"
    exit 1
fi

echo "Active GCP Project: $PROJECT_ID"
echo

# Service account configuration
SA_NAME="dbt-bigquery-sa"
SA_DISPLAY_NAME="dbt BigQuery Service Account"
SA_EMAIL="${SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"
KEY_FILE="../terraform/keys/dbt-sa-key.json"

# Check if service account already exists
if gcloud iam service-accounts describe "$SA_EMAIL" &> /dev/null; then
    echo "⚠️  Service account already exists: $SA_EMAIL"
    read -p "Do you want to continue and create a new key? (y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Exiting..."
        exit 0
    fi
else
    echo "----------------------------------------"
    echo "Creating service account..."
    echo "Name: $SA_NAME"
    echo "Email: $SA_EMAIL"
    echo "----------------------------------------"
    
    gcloud iam service-accounts create "$SA_NAME" \
        --display-name="$SA_DISPLAY_NAME" \
        --description="Service account for dbt to access BigQuery"
    
    echo "✅ Service account created"
fi

# Grant BigQuery permissions
echo
echo "----------------------------------------"
echo "Granting BigQuery IAM roles..."
echo "----------------------------------------"

echo "Granting BigQuery Data Editor role..."
gcloud projects add-iam-policy-binding "$PROJECT_ID" \
    --member="serviceAccount:$SA_EMAIL" \
    --role="roles/bigquery.dataEditor" \
    --quiet

echo "Granting BigQuery Job User role..."
gcloud projects add-iam-policy-binding "$PROJECT_ID" \
    --member="serviceAccount:$SA_EMAIL" \
    --role="roles/bigquery.jobUser" \
    --quiet

echo "Granting BigQuery User role..."
gcloud projects add-iam-policy-binding "$PROJECT_ID" \
    --member="serviceAccount:$SA_EMAIL" \
    --role="roles/bigquery.user" \
    --quiet

echo "Granting Storage Admin role (for GCS bucket access)..."
gcloud projects add-iam-policy-binding "$PROJECT_ID" \
    --member="serviceAccount:$SA_EMAIL" \
    --role="roles/storage.admin" \
    --quiet

echo "✅ All IAM roles granted successfully"

# Generate and download key
echo
echo "----------------------------------------"
echo "Generating JSON key file..."
echo "----------------------------------------"

# Create keys directory if it doesn't exist
mkdir -p "$(dirname "$KEY_FILE")"

# Check if key file already exists
if [ -f "$KEY_FILE" ]; then
    echo "⚠️  Key file already exists: $KEY_FILE"
    read -p "Do you want to overwrite it? (y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Keeping existing key file"
        KEY_FILE="${KEY_FILE%.json}-$(date +%Y%m%d-%H%M%S).json"
        echo "New key will be saved as: $KEY_FILE"
    fi
fi

# Create the key
gcloud iam service-accounts keys create "$KEY_FILE" \
    --iam-account="$SA_EMAIL"

echo "✅ Key file created: $KEY_FILE"

# Set appropriate permissions on key file
chmod 600 "$KEY_FILE"

# Summary
echo
echo "=========================================="
echo "✅ SERVICE ACCOUNT SETUP COMPLETE"
echo "=========================================="
echo "Service Account: $SA_EMAIL"
echo "Key File: $KEY_FILE"
echo
echo "IAM Roles Granted:"
echo "  - roles/bigquery.dataEditor"
echo "  - roles/bigquery.jobUser"
echo "  - roles/bigquery.user"
echo "  - roles/storage.admin"
echo
echo "⚠️  SECURITY REMINDER:"
echo "  - Never commit the key file to Git (it's in .gitignore)"
echo "  - Keep the key file secure"
echo "  - Rotate keys periodically"
echo "  - Consider using Workload Identity for production"
echo
echo "Next steps:"
echo "1. Configure Terraform:"
echo "   cd ../terraform"
echo "   cp dbt.tfvars.example dbt.tfvars"
echo "   # Edit dbt.tfvars with your values"
echo "2. Initialize and apply Terraform:"
echo "   terraform init"
echo "   terraform plan -var-file=\"dbt.tfvars\""
echo "   terraform apply -var-file=\"dbt.tfvars\""
echo "=========================================="
