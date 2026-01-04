# =============================================================================
# EKS MODULE - OUTPUTS
# =============================================================================
#
# PURPOSE:
# Expose EKS cluster details for use by:
# - kubectl configuration
# - ArgoCD connection
# - IRSA role creation
# - Monitoring setup
# =============================================================================

# -----------------------------------------------------------------------------
# CLUSTER OUTPUTS
# -----------------------------------------------------------------------------

# output "cluster_id" {
#   description = "EKS cluster ID"
#   value       = aws_eks_cluster.main.id
# }

# output "cluster_name" {
#   description = "EKS cluster name"
#   value       = aws_eks_cluster.main.name
# }

# output "cluster_endpoint" {
#   description = "EKS cluster API endpoint"
#   value       = aws_eks_cluster.main.endpoint
# }

# output "cluster_certificate_authority_data" {
#   description = "Base64 encoded certificate for cluster CA"
#   value       = aws_eks_cluster.main.certificate_authority[0].data
# }

# output "cluster_version" {
#   description = "Kubernetes version"
#   value       = aws_eks_cluster.main.version
# }

# -----------------------------------------------------------------------------
# OIDC OUTPUTS (for IRSA)
# -----------------------------------------------------------------------------

# output "cluster_oidc_issuer_url" {
#   description = "OIDC issuer URL (for IRSA role trust policies)"
#   value       = aws_eks_cluster.main.identity[0].oidc[0].issuer
# }

# output "oidc_provider_arn" {
#   description = "OIDC provider ARN"
#   value       = aws_iam_openid_connect_provider.cluster.arn
# }

# -----------------------------------------------------------------------------
# SECURITY GROUP OUTPUTS
# -----------------------------------------------------------------------------

# output "cluster_security_group_id" {
#   description = "Security group ID for cluster"
#   value       = aws_eks_cluster.main.vpc_config[0].cluster_security_group_id
# }

# output "node_security_group_id" {
#   description = "Security group ID for nodes"
#   value       = aws_eks_node_group.main.resources[0].remote_access_security_group_id
# }

# -----------------------------------------------------------------------------
# KUBECONFIG HELPER
# -----------------------------------------------------------------------------

# output "kubeconfig_command" {
#   description = "Command to update kubeconfig"
#   value       = "aws eks update-kubeconfig --name ${aws_eks_cluster.main.name} --region ${data.aws_region.current.name}"
# }
