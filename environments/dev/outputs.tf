# =============================================================================
# DEV ENVIRONMENT - OUTPUTS
# =============================================================================

# -----------------------------------------------------------------------------
# VPC OUTPUTS (Story 3.1) ✅
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
  description = "NAT Gateway public IPs"
  value       = module.vpc.nat_public_ips
}

# -----------------------------------------------------------------------------
# EKS OUTPUTS (Story 4.1) ✅
# -----------------------------------------------------------------------------

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

# -----------------------------------------------------------------------------
# ECR OUTPUTS (Story 6.1) - UNCOMMENT WHEN ECR IS ENABLED
# -----------------------------------------------------------------------------

/*
output "ecr_repository_urls" {
  description = "ECR repository URLs"
  value       = module.ecr.repository_urls
}

output "ecr_login_command" {
  description = "Command to login to ECR"
  value       = module.ecr.login_command
}
*/
