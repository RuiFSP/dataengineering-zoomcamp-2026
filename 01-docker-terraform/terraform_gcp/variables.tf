variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "GCP region"
  type        = string
  default     = "europe-west2"
}

variable "bucket_name" {
  description = "GCS bucket name"
  type        = string
}

variable "dataset_id" {
  description = "BigQuery Dataset ID"
  type        = string
  default     = "demo_dataset"
}

variable "location" {
  description = "BigQuery Dataset location"
  type        = string
  default     = "EU"
}

variable "credentials_file_path" {
  description = "Path to the GCP service account credentials JSON file"
  type        = string
  sensitive   = true
  # No default - must be provided via terraform.tfvars or environment variable
}