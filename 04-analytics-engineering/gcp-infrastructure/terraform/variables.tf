variable "project_id" {
  description = "GCP Project ID for dbt and BigQuery"
  type        = string
}

variable "region" {
  description = "GCP region for resources"
  type        = string
  default     = "europe-west2"
}

variable "location" {
  description = "BigQuery dataset location (must match across all datasets)"
  type        = string
  default     = "EU"
}

variable "bucket_name" {
  description = "GCS bucket name for taxi data staging"
  type        = string
}

variable "nytaxi_dataset_id" {
  description = "BigQuery dataset ID for NYC taxi data"
  type        = string
  default     = "nytaxi"
}

variable "dbt_prod_dataset_id" {
  description = "BigQuery dataset ID for dbt production models"
  type        = string
  default     = "dbt_prod"
}

variable "credentials_file_path" {
  description = "Path to the GCP service account credentials JSON file"
  type        = string
  sensitive   = true
  # No default - must be provided via dbt.tfvars
  # Example: "keys/dbt-sa-key.json"
}
