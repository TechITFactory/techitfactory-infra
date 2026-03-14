# =============================================================================
# EKS MODULE - OUTPUTS
# =============================================================================

# -----------------------------------------------------------------------------
# CLUSTER OUTPUTS
# -----------------------------------------------------------------------------

output "cluster_id" {
  description = "EKS cluster ID"
  value       = aws_eks_cluster.main.id
}

output "cluster_name" {
  description = "EKS cluster name"
  value       = aws_eks_cluster.main.name
}

output "cluster_endpoint" {
  description = "EKS cluster API endpoint"
  value       = aws_eks_cluster.main.endpoint
}

output "cluster_certificate_authority_data" {
  description = "Base64 encoded certificate for cluster CA"
  value       = aws_eks_cluster.main.certificate_authority[0].data
}

output "cluster_version" {
  description = "Kubernetes version"
  value       = aws_eks_cluster.main.version
}

# -----------------------------------------------------------------------------
# OIDC OUTPUTS (for IRSA)
# -----------------------------------------------------------------------------

output "cluster_oidc_issuer_url" {
  description = "OIDC issuer URL (for IRSA role trust policies)"
  value       = aws_eks_cluster.main.identity[0].oidc[0].issuer
}

output "oidc_provider_arn" {
  description = "OIDC provider ARN"
  value       = aws_iam_openid_connect_provider.cluster.arn
}

output "oidc_issuer" {
  description = "OIDC issuer (without https://)"
  value       = local.oidc_issuer
}

# -----------------------------------------------------------------------------
# SECURITY OUTPUTS
# -----------------------------------------------------------------------------

output "cluster_security_group_id" {
  description = "Security group ID for cluster"
  value       = aws_security_group.cluster.id
}

# -----------------------------------------------------------------------------
# NODE GROUP OUTPUTS
# -----------------------------------------------------------------------------

output "node_group_name" {
  description = "Name of the node group"
  value       = aws_eks_node_group.main.node_group_name
}

output "node_role_arn" {
  description = "IAM role ARN for nodes"
  value       = aws_iam_role.node.arn
}

# -----------------------------------------------------------------------------
# IRSA ROLE OUTPUTS
# -----------------------------------------------------------------------------

output "ebs_csi_role_arn" {
  description = "IAM role ARN for EBS CSI driver"
  value       = var.enable_ebs_csi_driver ? aws_iam_role.ebs_csi[0].arn : null
}

output "cluster_autoscaler_role_arn" {
  description = "IAM role ARN for Cluster Autoscaler"
  value       = var.enable_cluster_autoscaler ? aws_iam_role.cluster_autoscaler[0].arn : null
}

# -----------------------------------------------------------------------------
# HELPER OUTPUTS
# -----------------------------------------------------------------------------

output "kubeconfig_command" {
  description = "Command to update kubeconfig"
  value       = "aws eks update-kubeconfig --name ${aws_eks_cluster.main.name} --region ${data.aws_region.current.name}"
}

output "alb_controller_role_arn" {
  description = "IAM role ARN for AWS Load Balancer Controller"
  value       = var.enable_alb_controller ? aws_iam_role.alb_controller[0].arn : null
}
