# =============================================================================
# DEV ENVIRONMENT - MAIN CONFIGURATION
# =============================================================================
#
# DEPLOYMENT PHASES:
# - Story 3.1: VPC only (~$32/month) ✅ DONE
# - Story 4.1: Add EKS (+$147/month) ← CURRENT
# - Story 6.1: Add ECR (~free, storage costs only)
#
# CURRENT PHASE: VPC + EKS
# =============================================================================

terraform {
  required_version = ">= 1.6.0"

  # -------------------------------------------------------------------------
  # REMOTE BACKEND
  # -------------------------------------------------------------------------
  backend "s3" {
    bucket         = "techitfactory-tfstate-8bf605bd"
    key            = "environments/dev/terraform.tfstate"
    region         = "ap-south-1"
    encrypt        = true
    dynamodb_table = "techitfactory-tflock"
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
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
# VPC MODULE (Story 3.1) ✅
# =============================================================================

module "vpc" {
  source = "../../modules/vpc"

  project_name       = local.project_name
  environment        = local.environment
  vpc_cidr           = "10.0.0.0/16"
  single_nat_gateway = true # Cost optimization for dev
  enable_s3_endpoint = true # FREE - reduces NAT costs

  # OPTIONAL: Interface endpoints (cost ~$7.50/month each)
  # Uncomment these for production:
  # enable_ecr_endpoints = true  # ~$15/month (2 endpoints)
  # enable_logs_endpoint = true  # ~$7.50/month
  # enable_sts_endpoint  = true  # ~$7.50/month
}

# =============================================================================
# EKS MODULE (Story 4.1) ✅
# =============================================================================

module "eks" {
  source = "../../modules/eks"

  project_name = local.project_name
  environment  = local.environment

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnet_ids

  cluster_version = "1.31"

  # Node configuration
  node_desired_size   = 2
  node_min_size       = 1
  node_max_size       = 4
  node_instance_types = ["t3.medium"]
  node_capacity_type  = "ON_DEMAND"
  node_disk_size      = 50

  # Add-ons
  enable_ebs_csi_driver     = true
  enable_cluster_autoscaler = true
  enable_alb_controller     = true
}

# =============================================================================
# ECR MODULE (Story 6.1) - UNCOMMENT WHEN READY
# =============================================================================

/*
module "ecr" {
  source = "../../modules/ecr"

  project_name = local.project_name
  environment  = local.environment

  repositories = [
    "frontend",
    "api-gateway",
    "user-service",
    "order-service",
    "product-service",
    "cart-service"
  ]

  lifecycle_policy_count = 30
  scan_on_push           = true
}
*/
