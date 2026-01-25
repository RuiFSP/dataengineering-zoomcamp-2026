# AWS Infrastructure with Terraform

This Terraform configuration creates AWS infrastructure equivalent to the GCP setup, including:
- **Amazon S3 Bucket** for data lake storage (equivalent to Google Cloud Storage)
- **AWS Glue Catalog Database** for metadata and query layer (equivalent to BigQuery Dataset)

## Prerequisites

1. **AWS Account** with appropriate permissions
2. **AWS CLI** installed and configured with a profile
3. **Terraform** installed (version 1.0+)

## Required IAM Permissions

Your AWS IAM user or role needs the following permissions:

### S3 Permissions
- `s3:CreateBucket`
- `s3:DeleteBucket`
- `s3:PutObject`
- `s3:DeleteObject`
- `s3:GetObject`
- `s3:ListBucket`
- `s3:PutBucketVersioning`
- `s3:PutBucketPublicAccessBlock`
- `s3:PutLifecycleConfiguration`
- `s3:GetBucketPublicAccessBlock`
- `s3:GetBucketVersioning`
- `s3:GetLifecycleConfiguration`

### AWS Glue Permissions
- `glue:CreateDatabase`
- `glue:DeleteDatabase`
- `glue:GetDatabase`
- `glue:UpdateDatabase`
- `glue:TagResource`
- `glue:UntagResource`

**Recommended**: Use AWS managed policies:
- `AmazonS3FullAccess` (for S3 operations)
- `AWSGlueConsoleFullAccess` (for Glue operations)

Or create a custom policy with least-privilege permissions.

## Authentication Setup

### Method 1: AWS CLI Profile (Recommended)

1. Configure AWS CLI with your credentials:
   ```bash
   aws configure --profile your-profile-name
   ```

2. Enter your AWS Access Key ID, Secret Access Key, and default region

3. Use this profile name in your `terraform.tfvars`

### Method 2: Environment Variables

Set environment variables instead of using a profile:
```bash
export AWS_ACCESS_KEY_ID="your-access-key"
export AWS_SECRET_ACCESS_KEY="your-secret-key"
export AWS_DEFAULT_REGION="eu-west-2"
```

Then set `aws_profile = ""` in your `terraform.tfvars` (provider will use environment variables).

### Method 3: AWS SSO

If using AWS SSO, configure your profile with SSO:
```bash
aws configure sso --profile your-profile-name
aws sso login --profile your-profile-name
```

## Setup Instructions

1. **Copy the example variables file:**
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```

2. **Edit `terraform.tfvars` with your values:**
   ```hcl
   aws_profile   = "your-aws-profile-name"
   region        = "eu-west-2"
   bucket_name   = "your-unique-bucket-name-12345"
   database_name = "demo_database"
   ```

   **Important**: S3 bucket names must be globally unique across all AWS accounts.

3. **Initialize Terraform:**
   ```bash
   terraform init
   ```

4. **Format your configuration files:**
   ```bash
   terraform fmt
   ```

5. **Validate the configuration:**
   ```bash
   terraform validate
   ```

6. **Preview the changes:**
   ```bash
   terraform plan
   ```

7. **Apply the configuration:**
   ```bash
   terraform apply
   ```
   Type `yes` when prompted to confirm.

## Resources Created

After successful deployment, Terraform will create:

1. **S3 Bucket** with:
   - Versioning enabled
   - Public access blocked (secure by default)
   - Lifecycle rule to abort incomplete multipart uploads after 1 day
   - Force destroy enabled for easy cleanup

2. **AWS Glue Catalog Database** for managing table metadata

## Cleanup

To destroy all resources created by Terraform:

```bash
terraform destroy
```

Type `yes` when prompted. This will remove the S3 bucket (even if it contains objects) and the Glue database.

## Terraform Workflow Summary

```bash
# Initialize (first time only)
terraform init

# Check formatting
terraform fmt

# Validate configuration
terraform validate

# Preview changes
terraform plan

# Apply changes
terraform apply

# Destroy resources
terraform destroy
```

## GCP to AWS Service Mapping

| GCP Service | AWS Equivalent | Purpose |
|-------------|----------------|---------|
| Google Cloud Storage (GCS) | Amazon S3 | Data Lake storage |
| Uniform Bucket Level Access | S3 Public Access Block | Secure bucket access |
| Object Lifecycle Rules | S3 Lifecycle Configuration | Automatic data expiration |
| BigQuery Dataset | AWS Glue Catalog Database | Metadata & query layer |
| GCP Provider | AWS Provider | Infrastructure as Code |

## Security Best Practices

- ✅ Never commit `terraform.tfvars` to version control
- ✅ Use IAM profiles instead of hardcoding credentials
- ✅ Enable versioning on S3 buckets for data protection
- ✅ Block public access to S3 buckets by default
- ✅ Use least-privilege IAM permissions
- ✅ Rotate AWS access keys regularly
- ✅ Enable CloudTrail for audit logging (not included in this basic setup)

## Troubleshooting

### "Error: creating S3 Bucket: BucketAlreadyExists"
S3 bucket names are globally unique. Change your `bucket_name` to something unique.

### "Error: error creating Glue Catalog Database"
Check that your IAM user/role has Glue permissions.

### "Error: No valid credential sources found"
Ensure your AWS CLI profile is configured correctly or environment variables are set.

## Next Steps

After infrastructure is created, you can:
1. Upload data to S3: `aws s3 cp file.csv s3://your-bucket-name/`
2. Create Glue tables to query data with Athena
3. Set up ETL jobs using AWS Glue or other tools
