# =============================================================================
# DEV ENVIRONMENT - MAIN CONFIGURATION
# =============================================================================
#
# COST ESTIMATE:
# - VPC (NAT Gateway): ~$32/month
# - EKS Control Plane: ~$72/month
# - EKS Nodes (2x t3.medium): ~$60/month
# - CloudWatch Logs: ~$5/month
# - Total: ~$170/month
# =============================================================================

terraform {
  required_version = ">= 1.6.0"

  # -------------------------------------------------------------------------
  # REMOTE BACKEND
  # -------------------------------------------------------------------------
  # Uncomment after bootstrap is applied
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
# EKS MODULE
# =============================================================================

module "eks" {
  source = "../../modules/eks"

  project_name = local.project_name
  environment  = local.environment

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnet_ids

  cluster_version = "1.28"

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
# OUTPUTS
# =============================================================================

# VPC Outputs
output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "vpc_cidr" {
  description = "VPC CIDR block"
  value       = module.vpc.vpc_cidr
}

output "private_subnet_ids" {
  description = "Private subnet IDs"
  value       = module.vpc.private_subnet_ids
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = module.vpc.public_subnet_ids
}

output "nat_public_ips" {
  description = "NAT Gateway public IPs"
  value       = module.vpc.nat_public_ips
}

# EKS Outputs
output "cluster_name" {
  description = "EKS cluster name"
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "EKS cluster endpoint"
  value       = module.eks.cluster_endpoint
}

output "cluster_version" {
  description = "Kubernetes version"
  value       = module.eks.cluster_version
}

output "kubeconfig_command" {
  description = "Run this to configure kubectl"
  value       = module.eks.kubeconfig_command
}

output "cluster_autoscaler_role_arn" {
  description = "IAM role ARN for Cluster Autoscaler"
  value       = module.eks.cluster_autoscaler_role_arn
}

output "oidc_provider_arn" {
  description = "OIDC provider ARN for IRSA"
  value       = module.eks.oidc_provider_arn
}

output "alb_controller_role_arn" {
  description = "IAM role ARN for AWS Load Balancer Controller"
  value       = module.eks.alb_controller_role_arn
}

# =============================================================================
# ECR MODULE
# =============================================================================

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

# ECR Outputs
output "ecr_repository_urls" {
  description = "ECR repository URLs"
  value       = module.ecr.repository_urls
}

output "ecr_login_command" {
  description = "Command to login to ECR"
  value       = module.ecr.login_command
}

