#!/bin/bash

# ==============================================================================
# GCP Project Setup Script
# ==============================================================================
# This script creates a new GCP project, enables required APIs, and links billing
# 
# Prerequisites:
# - gcloud CLI installed and authenticated (run: gcloud auth login)
# - Access to a GCP billing account
#
# Usage:
#   ./01-setup-project.sh
# ==============================================================================

set -e # Exit on error

echo "=========================================="
echo "GCP Project Setup for dbt + BigQuery"
echo "=========================================="
echo

# Check if gcloud is installed
if ! command -v gcloud &> /dev/null; then
    echo "❌ Error: gcloud CLI is not installed"
    echo "Install it from: https://cloud.google.com/sdk/docs/install"
    exit 1
fi

# Check if user is authenticated
if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" &> /dev/null; then
    echo "❌ Error: Not authenticated with gcloud"
    echo "Run: gcloud auth login"
    exit 1
fi

echo "✅ gcloud CLI is installed and authenticated"
echo

# Prompt for project ID
echo "Enter a unique GCP project ID:"
echo "(Use lowercase letters, numbers, and hyphens. Must be 6-30 characters)"
read -p "Project ID: " PROJECT_ID

if [ -z "$PROJECT_ID" ]; then
    echo "❌ Error: Project ID cannot be empty"
    exit 1
fi

echo
echo "Enter a display name for the project (optional, press Enter to use project ID):"
read -p "Project Name: " PROJECT_NAME

if [ -z "$PROJECT_NAME" ]; then
    PROJECT_NAME="$PROJECT_ID"
fi

echo
echo "----------------------------------------"
echo "Creating GCP project..."
echo "Project ID: $PROJECT_ID"
echo "Project Name: $PROJECT_NAME"
echo "----------------------------------------"

# Create the project
if gcloud projects create "$PROJECT_ID" --name="$PROJECT_NAME"; then
    echo "✅ Project created successfully"
else
    echo "❌ Failed to create project"
    echo "Possible reasons:"
    echo "  - Project ID already exists"
    echo "  - Invalid project ID format"
    echo "  - Insufficient permissions"
    exit 1
fi

# Set the project as active
echo
echo "Setting project as active configuration..."
gcloud config set project "$PROJECT_ID"
echo "✅ Project set as active"

# Enable required APIs
echo
echo "----------------------------------------"
echo "Enabling required APIs..."
echo "This may take 1-2 minutes..."
echo "----------------------------------------"

echo "Enabling BigQuery API..."
gcloud services enable bigquery.googleapis.com

echo "Enabling Cloud Storage API..."
gcloud services enable storage.googleapis.com

echo "Enabling IAM API..."
gcloud services enable iam.googleapis.com

echo "✅ All APIs enabled successfully"

# Link billing account
echo
echo "----------------------------------------"
echo "Billing Account Setup"
echo "----------------------------------------"
echo "Listing your available billing accounts..."
echo

gcloud billing accounts list

echo
echo "Enter the Billing Account ID from the list above:"
echo "(Format: XXXXXX-YYYYYY-ZZZZZZ)"
read -p "Billing Account ID: " BILLING_ACCOUNT_ID

if [ -z "$BILLING_ACCOUNT_ID" ]; then
    echo "⚠️  Warning: No billing account provided"
    echo "You'll need to link a billing account manually later"
    echo "Run: gcloud billing projects link $PROJECT_ID --billing-account=BILLING_ACCOUNT_ID"
else
    echo
    echo "Linking billing account to project..."
    if gcloud billing projects link "$PROJECT_ID" --billing-account="$BILLING_ACCOUNT_ID"; then
        echo "✅ Billing account linked successfully"
    else
        echo "❌ Failed to link billing account"
        echo "You may need to link it manually through the GCP Console"
    fi
fi

# Summary
echo
echo "=========================================="
echo "✅ PROJECT SETUP COMPLETE"
echo "=========================================="
echo "Project ID: $PROJECT_ID"
echo "Project Name: $PROJECT_NAME"
echo "Active Project: $(gcloud config get-value project)"
echo
echo "Next steps:"
echo "1. Run: ./02-create-service-account.sh"
echo "2. Configure Terraform: cd ../terraform && cp dbt.tfvars.example dbt.tfvars"
echo "3. Edit dbt.tfvars with your project_id: $PROJECT_ID"
echo "=========================================="
