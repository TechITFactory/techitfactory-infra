# =============================================================================
# TERRAFORM BOOTSTRAP - MAIN CONFIGURATION
# =============================================================================
# 
# PURPOSE:
# This file creates the foundational infrastructure for Terraform state management.
# Before we can safely use Terraform in a team, we need:
#   1. A place to store state (S3 bucket)
#   2. A way to prevent simultaneous edits (DynamoDB lock table)
#   3. Encryption for sensitive state data (KMS key)
#
# WHY REMOTE STATE?
# - Local state files can be lost, corrupted, or cause conflicts
# - Two engineers running "terraform apply" at the same time can corrupt state
# - Remote state with locking prevents these issues
#
# RESOURCES CREATED:
# - aws_kms_key: Encrypts the state file at rest
# - aws_s3_bucket: Stores the terraform.tfstate file
# - aws_dynamodb_table: Provides state locking (prevents concurrent modifications)
#
# COST ESTIMATE:
# - KMS: ~$1/month (1 key)
# - S3: ~$0.02/month (minimal storage)
# - DynamoDB: ~$0 (PAY_PER_REQUEST, only pay when locking)
# =============================================================================

# -----------------------------------------------------------------------------
# TERRAFORM CONFIGURATION
# -----------------------------------------------------------------------------
# Specifies required Terraform version and providers
# We pin versions to avoid unexpected breaking changes

terraform {
  required_version = ">= 1.6.0" # Minimum Terraform version required

  required_providers {
    # AWS Provider - for creating AWS resources
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0" # Use version 5.x (latest stable)
    }
    # Random Provider - for generating unique bucket names
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

# -----------------------------------------------------------------------------
# AWS PROVIDER CONFIGURATION
# -----------------------------------------------------------------------------
# Configures how Terraform connects to AWS
# Region comes from variables.tf (default: ap-south-1)
# Default tags are applied to ALL resources created by this provider

provider "aws" {
  region = var.aws_region # Mumbai region (ap-south-1)

  # These tags will be automatically added to every resource
  # Helps with cost tracking and resource identification
  default_tags {
    tags = var.tags
  }
}

# -----------------------------------------------------------------------------
# RANDOM SUFFIX FOR BUCKET NAME
# -----------------------------------------------------------------------------
# S3 bucket names must be GLOBALLY UNIQUE across all AWS accounts worldwide
# We generate a random 4-byte (8 character hex) suffix to ensure uniqueness
# Example: techitfactory-tfstate-a1b2c3d4

resource "random_id" "bucket_suffix" {
  byte_length = 4 # Produces 8 hex characters (e.g., "a1b2c3d4")
}

# -----------------------------------------------------------------------------
# LOCAL VARIABLES
# -----------------------------------------------------------------------------
# Computed values used throughout this configuration
# Using locals keeps our code DRY (Don't Repeat Yourself)

locals {
  # Bucket name: techitfactory-tfstate-<random>
  bucket_name = "${var.project_name}-tfstate-${random_id.bucket_suffix.hex}"

  # DynamoDB table name: techitfactory-tflock
  table_name = "${var.project_name}-tflock"
}

# =============================================================================
# KMS KEY FOR STATE ENCRYPTION
# =============================================================================
# WHY KMS?
# - Terraform state can contain sensitive data (passwords, API keys, etc.)
# - KMS provides AWS-managed encryption with automatic key rotation
# - Using customer-managed key (CMK) gives us full control over the encryption
#
# KEY ROTATION:
# - Enabled to automatically rotate the key annually (security best practice)
# - Old encrypted data remains accessible (AWS handles this transparently)

resource "aws_kms_key" "terraform_state" {
  description             = "KMS key for Terraform state encryption"
  deletion_window_in_days = 7    # Wait 7 days before permanent deletion
  enable_key_rotation     = true # Auto-rotate key annually

  tags = {
    Name = "${var.project_name}-tfstate-key"
  }
}

# KMS ALIAS - Human-readable name for the key
# Instead of using "arn:aws:kms:...:key/abc-123", we can use "alias/techitfactory-tfstate"
resource "aws_kms_alias" "terraform_state" {
  name          = "alias/${var.project_name}-tfstate"
  target_key_id = aws_kms_key.terraform_state.key_id
}

# =============================================================================
# S3 BUCKET FOR TERRAFORM STATE
# =============================================================================
# WHY S3?
# - Durable (99.999999999% durability)
# - Versioned (can recover previous state versions)
# - Encrypted (using our KMS key)
# - Accessible from anywhere (GitHub Actions, local dev, etc.)
#
# IMPORTANT: This bucket stores your infrastructure's "source of truth"
# Losing this bucket = losing track of what Terraform manages

resource "aws_s3_bucket" "terraform_state" {
  bucket = local.bucket_name # techitfactory-tfstate-<random>

  # LIFECYCLE PROTECTION
  # Set to 'true' in production to prevent accidental deletion
  # Set to 'false' for learning/course so we can easily cleanup
  lifecycle {
    prevent_destroy = false # CHANGE TO true IN PRODUCTION!
  }

  tags = {
    Name = local.bucket_name
  }
}

# S3 VERSIONING - Keep history of all state file changes
# WHY VERSIONING?
# - If something goes wrong, you can restore a previous state version
# - Acts as a backup for your infrastructure state
# - Required for Terraform state best practices
resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  versioning_configuration {
    status = "Enabled"
  }
}

# S3 ENCRYPTION - Encrypt state at rest using our KMS key
# WHY SERVER-SIDE ENCRYPTION?
# - State files may contain secrets (database passwords, API keys)
# - Encryption at rest protects data if storage is compromised
# - Using KMS gives us audit trail via CloudTrail
resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.terraform_state.arn # Our KMS key
      sse_algorithm     = "aws:kms"                       # Use KMS encryption
    }
    bucket_key_enabled = true # Reduces KMS API calls (cost optimization)
  }
}

# S3 PUBLIC ACCESS BLOCK - Prevent accidental public exposure
# CRITICAL SECURITY SETTING!
# - State files should NEVER be public
# - These settings block ALL public access paths
resource "aws_s3_bucket_public_access_block" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  block_public_acls       = true # Block public ACLs
  block_public_policy     = true # Block public bucket policies
  ignore_public_acls      = true # Ignore any public ACLs
  restrict_public_buckets = true # Restrict public bucket policies
}

# =============================================================================
# DYNAMODB TABLE FOR STATE LOCKING
# =============================================================================
# WHY STATE LOCKING?
# - Prevents two people from running "terraform apply" at the same time
# - Without locking, concurrent applies can corrupt state
# - DynamoDB provides fast, reliable locking mechanism
#
# HOW IT WORKS:
# 1. Before 'terraform apply', Terraform writes a lock record to this table
# 2. If another person tries to apply, they see "State is locked by..."
# 3. After apply completes, the lock is released
#
# BILLING:
# - PAY_PER_REQUEST means we only pay when locks are acquired/released
# - For Terraform usage, this is essentially free (~$0/month)

resource "aws_dynamodb_table" "terraform_lock" {
  name         = local.table_name  # techitfactory-tflock
  billing_mode = "PAY_PER_REQUEST" # No provisioned capacity, pay per use
  hash_key     = "LockID"          # Primary key used by Terraform

  # The LockID attribute - Terraform uses this to identify which state is locked
  attribute {
    name = "LockID"
    type = "S" # String type
  }

  tags = {
    Name = local.table_name
  }
}
