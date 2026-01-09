# =============================================================================
# EKS ACCESS CONFIGURATION (SSO Integration)
# =============================================================================
#
# This file configures EKS access for IAM Identity Center (SSO) groups.
#
# SSO Groups → Permission Sets → IAM Roles → EKS Access Entries
#
# | SSO Group          | Permission Set     | EKS Access         |
# |--------------------|--------------------|--------------------|
# | Platform-Admins    | EKS-Platform-Admin | Cluster Admin      |
# | Developers         | EKS-Developer      | Namespace Admin    |
# | Developers-ReadOnly| EKS-ReadOnly       | View Only          |
# =============================================================================

# Get current AWS account
data "aws_caller_identity" "current" {}

# =============================================================================
# EKS ACCESS ENTRIES FOR SSO ROLES
# =============================================================================

# Platform Admins - Full cluster admin access
resource "aws_eks_access_entry" "platform_admins" {
  cluster_name  = module.eks.cluster_name
  principal_arn = "arn:aws:iam::535002890483:role/aws-reserved/sso.amazonaws.com/ap-south-1/AWSReservedSSO_EKS-Platform-Admin_36f4fb8141d4c59c"
  type          = "STANDARD"
}

resource "aws_eks_access_policy_association" "platform_admins" {
  cluster_name  = module.eks.cluster_name
  principal_arn = aws_eks_access_entry.platform_admins.principal_arn
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

  access_scope {
    type = "cluster"
  }
}

# Developers - Namespace admin access via Kubernetes RBAC
resource "aws_eks_access_entry" "developers" {
  cluster_name      = module.eks.cluster_name
  principal_arn     = "arn:aws:iam::535002890483:role/aws-reserved/sso.amazonaws.com/ap-south-1/AWSReservedSSO_EKS-Developer_140c6c9dd333ba83"
  type              = "STANDARD"
  kubernetes_groups = ["developers"] # Maps to K8s group for RBAC
}

# Developers ReadOnly - View only access
resource "aws_eks_access_entry" "developers_readonly" {
  cluster_name      = module.eks.cluster_name
  principal_arn     = "arn:aws:iam::535002890483:role/aws-reserved/sso.amazonaws.com/ap-south-1/AWSReservedSSO_EKS-ReadOnly_a1192e55b25ede2e"
  type              = "STANDARD"
  kubernetes_groups = ["developers-readonly"]
}

resource "aws_eks_access_policy_association" "developers_readonly" {
  cluster_name  = module.eks.cluster_name
  principal_arn = aws_eks_access_entry.developers_readonly.principal_arn
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSViewPolicy"

  access_scope {
    type = "cluster"
  }
}
