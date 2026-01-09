# =============================================================================
# PROD ENVIRONMENT - MAIN CONFIGURATION
# =============================================================================
#
# PRODUCTION DIFFERENCES FROM DEV:
# - NAT Gateway per AZ (high availability)
# - All VPC endpoints enabled (security + performance)
# - Larger node groups
# - Multi-AZ node placement
#
# COST ESTIMATE:
# - VPC (2x NAT Gateway): ~$64/month
# - VPC Endpoints: ~$30/month
# - EKS Control Plane: ~$72/month
# - EKS Nodes (3x t3.large): ~$180/month
# - Total: ~$350/month
# =============================================================================

terraform {
  required_version = ">= 1.6.0"

  # -------------------------------------------------------------------------
  # REMOTE BACKEND - UNCOMMENT AND UPDATE AFTER BOOTSTRAP
  # -------------------------------------------------------------------------
  /*
  backend "s3" {
    bucket         = "techitfactory-terraform-state-ACCOUNT_ID"
    key            = "environments/prod/terraform.tfstate"
    region         = "ap-south-1"
    encrypt        = true
    dynamodb_table = "techitfactory-terraform-locks"
  }
  */

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
      Environment = "prod"
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
  environment  = "prod"
}

# =============================================================================
# VPC MODULE - PRODUCTION CONFIGURATION
# =============================================================================

module "vpc" {
  source = "../../modules/vpc"

  project_name = local.project_name
  environment  = local.environment
  vpc_cidr     = "10.1.0.0/16" # Different CIDR from dev for VPC peering

  # PRODUCTION: NAT Gateway per AZ for high availability
  single_nat_gateway = false # ~$64/month (2 NAT Gateways)

  # PRODUCTION: All endpoints enabled for security
  enable_s3_endpoint   = true # FREE
  enable_ecr_endpoints = true # ~$15/month - traffic stays in AWS
  enable_logs_endpoint = true # ~$7.50/month
  enable_sts_endpoint  = true # ~$7.50/month
}

# =============================================================================
# EKS MODULE - PRODUCTION CONFIGURATION (UNCOMMENT WHEN READY)
# =============================================================================

/*
module "eks" {
  source = "../../modules/eks"

  project_name = local.project_name
  environment  = local.environment

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnet_ids

  cluster_version = "1.28"

  # PRODUCTION: Larger nodes, more capacity
  node_desired_size   = 3
  node_min_size       = 3
  node_max_size       = 10
  node_instance_types = ["t3.large"]  # Larger than dev
  node_capacity_type  = "ON_DEMAND"   # No spot for prod
  node_disk_size      = 100           # More storage

  # Add-ons
  enable_ebs_csi_driver     = true
  enable_cluster_autoscaler = true
  enable_alb_controller     = true
}
*/

# =============================================================================
# ECR MODULE - PRODUCTION (UNCOMMENT WHEN READY)
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

  lifecycle_policy_count = 50  # Keep more images in prod
  scan_on_push           = true
}
*/
