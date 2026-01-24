terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "7.16.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
  # Use service account JSON key file contents (path provided by variable)
  credentials = file(var.credentials_file_path)
}

# Create a Google Cloud Storage bucket with lifecycle rules
resource "google_storage_bucket" "demo-bucket" {
  name          = var.bucket_name
  location      = upper(var.region)
  force_destroy = true

  lifecycle_rule {
    condition {
      age = 1 # Abort multipart uploads older than 1 day
    }
    action {
      type = "AbortIncompleteMultipartUpload"
    }
  }
}

resource "google_bigquery_dataset" "demo-dataset" {
  dataset_id = var.dataset_id
  location   = var.location
}
