# =============================================================================
# PROD ENVIRONMENT - MAIN CONFIGURATION (SKELETON)
# =============================================================================
#
# PURPOSE:
# Production environment configuration.
# Key differences from dev:
# - Multiple NAT gateways (HA)
# - Larger instance types
# - More nodes
# - Manual sync in ArgoCD
#
# THIS IS A PLACEHOLDER - Will be implemented after dev is validated
# =============================================================================

terraform {
  required_version = ">= 1.6.0"

  # backend "s3" {
  #   bucket         = "<from-terraform-output>"
  #   key            = "environments/prod/terraform.tfstate"  # Different key!
  #   region         = "ap-south-1"
  #   encrypt        = true
  #   dynamodb_table = "<from-terraform-output>"
  # }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "ap-south-1"

  default_tags {
    tags = {
      Environment = "prod"
      Project     = "TechITFactory"
      ManagedBy   = "Terraform"
    }
  }
}

# =============================================================================
# PROD-SPECIFIC CONFIGURATION
# =============================================================================
# Key differences from dev:
#
# VPC:
#   single_nat_gateway = false  # NAT per AZ for HA
#
# EKS:
#   node_desired_size = 3
#   node_min_size     = 2
#   node_max_size     = 10
#   node_instance_types = ["m5.large"]  # Larger instances
#   node_capacity_type  = "ON_DEMAND"   # No spot for prod
#
# =============================================================================
