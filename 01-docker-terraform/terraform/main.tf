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

