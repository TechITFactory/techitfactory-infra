# =============================================================================
# BOOTSTRAP BACKEND
# =============================================================================
# This bucket is the ONLY resource in this entire project that is NOT created
# by Terraform. It was created once with:
#
#   aws s3 mb s3://YOUR_BOOTSTRAP_BUCKET --region ap-south-1
#   aws s3api put-bucket-versioning \
#     --bucket YOUR_BOOTSTRAP_BUCKET \
#     --versioning-configuration Status=Enabled
#
# WHY NOT TERRAFORM?
#   Bootstrap creates the S3 bucket for all other workspaces. If we used
#   Terraform to create the bootstrap backend, we'd need a backend to store
#   that state — infinite regress. One manual bucket breaks the cycle.
#
# THIS BUCKET ONLY STORES:
#   bootstrap/terraform.tfstate  (~5 KB — KMS key, S3 bucket, DynamoDB table)
#
# COST: ~$0.00/month (near-zero storage, versioning on a tiny file)
# =============================================================================

terraform {
  backend "s3" {
    bucket = "YOUR_BOOTSTRAP_BUCKET"
    key    = "bootstrap/terraform.tfstate"
    region = "ap-south-1"
    # SSE-S3 (not KMS) — the KMS key doesn't exist yet when this backend is initialized
    encrypt = true
  }
}
