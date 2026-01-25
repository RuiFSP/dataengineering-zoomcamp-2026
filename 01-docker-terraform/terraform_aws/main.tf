terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  profile = var.aws_profile
  region  = var.region
}

# S3 Bucket for Data Lake Storage (equivalent to GCS bucket)
resource "aws_s3_bucket" "demo_bucket" {
  bucket        = var.bucket_name
  force_destroy = var.force_destroy

  tags = {
    Name        = "Data Lake Demo Bucket"
    Environment = "Demo"
    ManagedBy   = "Terraform"
  }
}

# Block all public access to the S3 bucket (equivalent to GCS Uniform Bucket Level Access)
resource "aws_s3_bucket_public_access_block" "demo_bucket_pab" {
  bucket = aws_s3_bucket.demo_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Enable versioning on the S3 bucket
resource "aws_s3_bucket_versioning" "demo_bucket_versioning" {
  bucket = aws_s3_bucket.demo_bucket.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Lifecycle configuration for incomplete multipart uploads (equivalent to GCS lifecycle rule)
resource "aws_s3_bucket_lifecycle_configuration" "demo_bucket_lifecycle" {
  bucket = aws_s3_bucket.demo_bucket.id

  rule {
    id     = "abort-incomplete-multipart-upload"
    status = "Enabled"

    filter {}

    abort_incomplete_multipart_upload {
      days_after_initiation = 1
    }
  }
}

# AWS Glue Catalog Database (equivalent to BigQuery Dataset)
resource "aws_glue_catalog_database" "demo_database" {
  name        = var.database_name
  description = "Demo database for data engineering zoomcamp - equivalent to BigQuery dataset"

  tags = {
    Name        = "Data Lake Demo Database"
    Environment = "Demo"
    ManagedBy   = "Terraform"
  }
}
