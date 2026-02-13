terraform {
  required_version = ">= 1.0"
  
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 7.0"
    }
  }
}

provider "google" {
  project     = var.project_id
  region      = var.region
  credentials = file(var.credentials_file_path)
}

# GCS bucket for staging taxi data parquet files
resource "google_storage_bucket" "taxi_data" {
  name          = var.bucket_name
  location      = upper(var.location)
  force_destroy = true

  uniform_bucket_level_access = true

  lifecycle_rule {
    condition {
      age = 7 # Delete files older than 7 days
    }
    action {
      type = "Delete"
    }
  }

  lifecycle_rule {
    condition {
      age = 1 # Abort incomplete multipart uploads after 1 day
    }
    action {
      type = "AbortIncompleteMultipartUpload"
    }
  }
}

# BigQuery dataset for NYC taxi data (yellow and green)
resource "google_bigquery_dataset" "nytaxi" {
  dataset_id    = var.nytaxi_dataset_id
  friendly_name = "NYC Taxi Trip Records"
  description   = "Yellow and green taxi trip records for 2019-2020 from DataTalksClub repository"
  location      = var.location

  # Allow data to be deleted when running terraform destroy
  delete_contents_on_destroy = true
}

# BigQuery dataset for dbt production models
resource "google_bigquery_dataset" "dbt_prod" {
  dataset_id    = var.dbt_prod_dataset_id
  friendly_name = "dbt Production Models"
  description   = "Production dbt models and transformations (base schema for staging, marts, etc.)"
  location      = var.location

  # Allow data to be deleted when running terraform destroy
  delete_contents_on_destroy = true
}

# Outputs for verification
output "bucket_name" {
  description = "GCS bucket name for taxi data"
  value       = google_storage_bucket.taxi_data.name
}

output "bucket_url" {
  description = "GCS bucket URL"
  value       = google_storage_bucket.taxi_data.url
}

output "nytaxi_dataset_id" {
  description = "BigQuery dataset ID for taxi data"
  value       = google_bigquery_dataset.nytaxi.dataset_id
}

output "dbt_prod_dataset_id" {
  description = "BigQuery dataset ID for dbt production"
  value       = google_bigquery_dataset.dbt_prod.dataset_id
}

output "dataset_location" {
  description = "Location of BigQuery datasets"
  value       = var.location
}
