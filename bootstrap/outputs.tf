# =============================================================================
# TERRAFORM BOOTSTRAP - OUTPUTS
# =============================================================================
#
# PURPOSE:
# Outputs expose values from this Terraform configuration that:
# 1. Other Terraform configurations need (bucket name for backend config)
# 2. Users need to know (for documentation, debugging)
# 3. Scripts/automation can consume (terraform output -json)
#
# HOW TO USE:
# - View all outputs: terraform output
# - Get specific value: terraform output state_bucket_name
# - Get raw value (no quotes): terraform output -raw state_bucket_name
# - Get as JSON: terraform output -json
# =============================================================================

# -----------------------------------------------------------------------------
# S3 BUCKET OUTPUTS
# -----------------------------------------------------------------------------
# These values are needed to configure the backend in other Terraform configs

output "state_bucket_name" {
  description = "S3 bucket for Terraform state"
  value       = aws_s3_bucket.terraform_state.id
  
  # USAGE: Copy this value to backend.tf in your environment configs:
  # bucket = "<this-value>"
}

output "state_bucket_arn" {
  description = "S3 bucket ARN"
  value       = aws_s3_bucket.terraform_state.arn
  
  # USAGE: Use this ARN when creating IAM policies that need S3 access
  # For example, the GitHub Actions OIDC role needs this
}

# -----------------------------------------------------------------------------
# DYNAMODB TABLE OUTPUT
# -----------------------------------------------------------------------------
# The lock table name is needed for backend configuration

output "lock_table_name" {
  description = "DynamoDB table for state locking"
  value       = aws_dynamodb_table.terraform_lock.name
  
  # USAGE: Copy this value to backend.tf in your environment configs:
  # dynamodb_table = "<this-value>"
}

# -----------------------------------------------------------------------------
# KMS KEY OUTPUTS
# -----------------------------------------------------------------------------
# The KMS key ARN is needed for backend encryption configuration

output "kms_key_arn" {
  description = "KMS key ARN for state encryption"
  value       = aws_kms_key.terraform_state.arn
  
  # USAGE: Use this in backend.tf for explicit encryption:
  # kms_key_id = "<this-value>"
  # Also needed for IAM policies granting decrypt permissions
}

output "kms_key_alias" {
  description = "KMS key alias"
  value       = aws_kms_alias.terraform_state.name
  
  # USAGE: Human-readable key name for documentation
  # Can also be used in policies: alias/techitfactory-tfstate
}

# -----------------------------------------------------------------------------
# COMPLETE BACKEND CONFIGURATION
# -----------------------------------------------------------------------------
# This output provides a ready-to-use backend configuration block
# Copy this to your environment configs (environments/dev/backend.tf)

output "backend_config" {
  description = "Backend configuration for other Terraform configs"
  value = <<-EOT
    # =================================================================
    # COPY THIS TO: environments/dev/backend.tf (or prod)
    # =================================================================
    terraform {
      backend "s3" {
        bucket         = "${aws_s3_bucket.terraform_state.id}"
        key            = "environments/dev/terraform.tfstate"  # Change for prod
        region         = "${var.aws_region}"
        encrypt        = true
        kms_key_id     = "${aws_kms_key.terraform_state.arn}"
        dynamodb_table = "${aws_dynamodb_table.terraform_lock.name}"
      }
    }
  EOT
  
  # USAGE:
  # 1. Run: terraform output backend_config
  # 2. Copy the output to environments/dev/backend.tf
  # 3. Change the 'key' for different environments (dev vs prod)
}
