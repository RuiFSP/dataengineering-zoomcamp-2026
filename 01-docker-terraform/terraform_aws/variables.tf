variable "region" {
  description = "AWS region for resources"
  type        = string
  default     = "eu-west-2"
}

variable "aws_profile" {
  description = "AWS CLI profile to use for authentication"
  type        = string
}

variable "bucket_name" {
  description = "Name for the S3 bucket (must be globally unique)"
  type        = string
}

variable "database_name" {
  description = "Name for the AWS Glue Catalog Database"
  type        = string
  default     = "demo_database"
}

variable "force_destroy" {
  description = "Allow deletion of bucket even if it contains objects"
  type        = bool
  default     = true
}
