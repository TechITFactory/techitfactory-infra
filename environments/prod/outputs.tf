# =============================================================================
# PROD ENVIRONMENT - OUTPUTS
# =============================================================================

# -----------------------------------------------------------------------------
# VPC OUTPUTS
# -----------------------------------------------------------------------------

output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "vpc_cidr" {
  description = "VPC CIDR block"
  value       = module.vpc.vpc_cidr
}

output "private_subnet_ids" {
  description = "Private subnet IDs (for EKS)"
  value       = module.vpc.private_subnet_ids
}

output "public_subnet_ids" {
  description = "Public subnet IDs (for ALB)"
  value       = module.vpc.public_subnet_ids
}

output "nat_public_ips" {
  description = "NAT Gateway public IPs (for allowlisting)"
  value       = module.vpc.nat_public_ips
}

# -----------------------------------------------------------------------------
# EKS OUTPUTS - UNCOMMENT WHEN EKS IS ENABLED
# -----------------------------------------------------------------------------

/*
output "cluster_name" {
  description = "EKS cluster name"
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "EKS cluster endpoint"
  value       = module.eks.cluster_endpoint
}

output "kubeconfig_command" {
  description = "Run this to configure kubectl"
  value       = module.eks.kubeconfig_command
}
*/

# -----------------------------------------------------------------------------
# ECR OUTPUTS - UNCOMMENT WHEN ECR IS ENABLED
# -----------------------------------------------------------------------------

/*
output "ecr_repository_urls" {
  description = "ECR repository URLs"
  value       = module.ecr.repository_urls
}
*/
