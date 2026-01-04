# =============================================================================
# DEV ENVIRONMENT - MAIN CONFIGURATION
# =============================================================================
#
# PURPOSE:
# Orchestrates all modules to create the dev environment.
# This is the entry point for: terraform init/plan/apply
#
# COST ESTIMATE:
# - VPC (NAT Gateway): ~$32/month
# - EKS Control Plane: ~$72/month (when added)
# - EKS Nodes (2x t3.medium): ~$60/month (when added)
# - Total: ~$165/month
# =============================================================================

terraform {
  required_version = ">= 1.6.0"

  # -------------------------------------------------------------------------
  # REMOTE BACKEND
  # -------------------------------------------------------------------------
  # Uncomment after bootstrap is applied and replace placeholders
  # Get values from: cd ../bootstrap && terraform output
  #
  # backend "s3" {
  #   bucket         = "<BUCKET_NAME_FROM_BOOTSTRAP>"
  #   key            = "environments/dev/terraform.tfstate"
  #   region         = "ap-south-1"
  #   encrypt        = true
  #   dynamodb_table = "<TABLE_NAME_FROM_BOOTSTRAP>"
  # }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# -----------------------------------------------------------------------------
# PROVIDER CONFIGURATION
# -----------------------------------------------------------------------------

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Environment = "dev"
      Project     = "TechITFactory"
      ManagedBy   = "Terraform"
    }
  }
}

# -----------------------------------------------------------------------------
# LOCAL VARIABLES
# -----------------------------------------------------------------------------

locals {
  project_name = "techitfactory"
  environment  = "dev"
}

# =============================================================================
# VPC MODULE
# =============================================================================

module "vpc" {
  source = "../../modules/vpc"

  project_name       = local.project_name
  environment        = local.environment
  vpc_cidr           = "10.0.0.0/16"
  single_nat_gateway = true # Cost optimization for dev
  enable_s3_endpoint = true # FREE - reduces NAT costs
}

# =============================================================================
# EKS MODULE (Coming in Epic 4)
# =============================================================================
# Uncomment after EKS module is implemented

# module "eks" {
#   source = "../../modules/eks"
#
#   project_name = local.project_name
#   environment  = local.environment
#
#   vpc_id     = module.vpc.vpc_id
#   subnet_ids = module.vpc.private_subnet_ids
#
#   cluster_version   = "1.28"
#   node_desired_size = 2
#   node_min_size     = 1
#   node_max_size     = 4
#
#   node_instance_types = ["t3.medium"]
#   node_capacity_type  = "ON_DEMAND"
# }

# =============================================================================
# OUTPUTS
# =============================================================================

output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "vpc_cidr" {
  description = "VPC CIDR block"
  value       = module.vpc.vpc_cidr
}

output "private_subnet_ids" {
  description = "Private subnet IDs (for EKS nodes)"
  value       = module.vpc.private_subnet_ids
}

output "public_subnet_ids" {
  description = "Public subnet IDs (for ALB)"
  value       = module.vpc.public_subnet_ids
}

output "nat_public_ips" {
  description = "NAT Gateway public IPs"
  value       = module.vpc.nat_public_ips
}

# output "cluster_endpoint" {
#   description = "EKS cluster endpoint"
#   value       = module.eks.cluster_endpoint
# }

# output "kubeconfig_command" {
#   description = "Run this to configure kubectl"
#   value       = module.eks.kubeconfig_command
# }
