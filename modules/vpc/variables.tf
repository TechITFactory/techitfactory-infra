# =============================================================================
# VPC MODULE - VARIABLES
# =============================================================================
#
# PURPOSE:
# Define input variables for the VPC module.
# These allow customization per environment (dev/prod).
#
# USAGE:
# module "vpc" {
#   source       = "../../modules/vpc"
#   project_name = "techitfactory"
#   environment  = "dev"
# }
# =============================================================================

# -----------------------------------------------------------------------------
# NAMING VARIABLES
# -----------------------------------------------------------------------------

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "environment" {
  description = "Environment (dev/prod)"
  type        = string
}

# -----------------------------------------------------------------------------
# VPC CONFIGURATION
# -----------------------------------------------------------------------------

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"

  # WHY 10.0.0.0/16?
  # - Provides 65,536 IP addresses
  # - Private IP range (RFC 1918)
  # - Large enough for growth
}

variable "azs" {
  description = "Availability zones to use"
  type        = list(string)
  default     = ["ap-south-1a", "ap-south-1b"]

  # WHY 2 AZs?
  # - Minimum for high availability
  # - EKS requires at least 2 AZs
  # - More AZs = more NAT gateways = more cost
}

variable "public_subnets" {
  description = "CIDR blocks for public subnets (one per AZ)"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]

  # WHY /24?
  # - 256 IPs per subnet
  # - Public subnets only need IPs for ALB, NAT, bastion
}

variable "private_subnets" {
  description = "CIDR blocks for private subnets (one per AZ)"
  type        = list(string)
  default     = ["10.0.10.0/24", "10.0.20.0/24"]

  # WHY /24?
  # - 256 IPs per subnet
  # - Private subnets hold EKS nodes (plenty for 50+ nodes)
}

# -----------------------------------------------------------------------------
# COST OPTIMIZATION
# -----------------------------------------------------------------------------

variable "single_nat_gateway" {
  description = "Use single NAT gateway (cost optimization for non-prod)"
  type        = bool
  default     = true

  # COST IMPACT:
  # - Single NAT: ~$32/month
  # - NAT per AZ: ~$64/month (2 AZs)
  # - For dev/learning: single is fine
  # - For prod: set to false for HA
}

variable "enable_s3_endpoint" {
  description = "Enable S3 VPC endpoint (reduces NAT traffic)"
  type        = bool
  default     = true

  # WHY ENABLE?
  # - S3 Gateway endpoint is FREE
  # - Reduces NAT gateway data transfer costs
  # - ECR uses S3 for layers → saves money on image pulls
}

# -----------------------------------------------------------------------------
# TAGGING
# -----------------------------------------------------------------------------

variable "tags" {
  description = "Additional tags for resources"
  type        = map(string)
  default     = {}
}

# -----------------------------------------------------------------------------
# VPC INTERFACE ENDPOINTS (OPTIONAL)
# Cost: ~$7.50/month each. Enable for production or high traffic.
# -----------------------------------------------------------------------------

variable "enable_ecr_endpoints" {
  description = "Enable ECR VPC endpoints (reduces NAT costs for image pulls)"
  type        = bool
  default     = false

  # COST vs SAVINGS:
  # - ECR endpoints: ~$15/month (2 endpoints: api + dkr)
  # - NAT data transfer: ~$0.045/GB
  # - If pulling >330GB/month of images, endpoints save money
  # - For dev: keep false to save cost
  # - For prod: enable for security (traffic stays in AWS network)
}

variable "enable_logs_endpoint" {
  description = "Enable CloudWatch Logs VPC endpoint"
  type        = bool
  default     = false

  # Useful for container logs going to CloudWatch
  # Cost: ~$7.50/month
}

variable "enable_sts_endpoint" {
  description = "Enable STS VPC endpoint (for IRSA token exchange)"
  type        = bool
  default     = false

  # Required for IRSA to work without NAT Gateway
  # Cost: ~$7.50/month
}

