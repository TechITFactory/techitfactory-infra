# =============================================================================
# EKS MODULE - MAIN CONFIGURATION
# =============================================================================
#
# PURPOSE:
# Creates a production-ready EKS cluster with managed node groups.
#
# ARCHITECTURE:
# ┌─────────────────────────────────────────────────────────────────┐
# │                         AWS Account                              │
# │  ┌─────────────────────────────────────────────────────────┐    │
# │  │                    EKS Control Plane                     │    │
# │  │                   (AWS Managed)                          │    │
# │  │  - API Server                                            │    │
# │  │  - etcd                                                  │    │
# │  │  - Scheduler                                             │    │
# │  └─────────────────────────────────────────────────────────┘    │
# │                              │                                   │
# │                              │ OIDC                              │
# │                              ▼                                   │
# │  ┌─────────────────────────────────────────────────────────┐    │
# │  │                  Managed Node Group                      │    │
# │  │  ┌─────────┐  ┌─────────┐  ┌─────────┐                  │    │
# │  │  │ t3.med  │  │ t3.med  │  │ t3.med  │  (Auto-scaled)   │    │
# │  │  │ Node 1  │  │ Node 2  │  │ Node 3  │                  │    │
# │  │  └─────────┘  └─────────┘  └─────────┘                  │    │
# │  └─────────────────────────────────────────────────────────┘    │
# │                                                                  │
# │  Add-ons:                                                        │
# │  ├── EBS CSI Driver (IRSA)                                      │
# │  ├── CoreDNS                                                     │
# │  ├── kube-proxy                                                  │
# │  └── VPC CNI                                                     │
# └─────────────────────────────────────────────────────────────────┘
#
# WHAT GETS CREATED:
# - EKS Cluster with OIDC provider
# - IAM Role for cluster
# - Managed Node Group
# - IAM Role for nodes
# - EBS CSI Driver (via IRSA)
# - OIDC provider for IRSA
#
# THIS IS A SKELETON - Full implementation comes in Story 4.1
# =============================================================================

locals {
  cluster_name = "${var.project_name}-${var.environment}"

  # Merge default tags with user-provided tags
  common_tags = merge(
    {
      Module      = "eks"
      Environment = var.environment
    },
    var.tags
  )
}

# =============================================================================
# TODO: STORY 4.1 - IMPLEMENT THE FOLLOWING RESOURCES
# =============================================================================

# -----------------------------------------------------------------------------
# IAM ROLE FOR EKS CLUSTER
# -----------------------------------------------------------------------------
# resource "aws_iam_role" "cluster" {
#   name = "${local.cluster_name}-cluster-role"
#
#   assume_role_policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [{
#       Action = "sts:AssumeRole"
#       Effect = "Allow"
#       Principal = {
#         Service = "eks.amazonaws.com"
#       }
#     }]
#   })
# }

# resource "aws_iam_role_policy_attachment" "cluster_policy" {
#   policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
#   role       = aws_iam_role.cluster.name
# }

# -----------------------------------------------------------------------------
# EKS CLUSTER
# -----------------------------------------------------------------------------
# resource "aws_eks_cluster" "main" {
#   name     = local.cluster_name
#   role_arn = aws_iam_role.cluster.arn
#   version  = var.cluster_version
#
#   vpc_config {
#     subnet_ids              = var.subnet_ids
#     endpoint_public_access  = var.cluster_endpoint_public_access
#     endpoint_private_access = var.cluster_endpoint_private_access
#   }
#
#   enabled_cluster_log_types = ["api", "audit", "authenticator"]
#
#   tags = merge(local.common_tags, {
#     Name = local.cluster_name
#   })
# }

# -----------------------------------------------------------------------------
# OIDC PROVIDER FOR IRSA
# -----------------------------------------------------------------------------
# data "tls_certificate" "cluster" {
#   url = aws_eks_cluster.main.identity[0].oidc[0].issuer
# }

# resource "aws_iam_openid_connect_provider" "cluster" {
#   url             = aws_eks_cluster.main.identity[0].oidc[0].issuer
#   client_id_list  = ["sts.amazonaws.com"]
#   thumbprint_list = [data.tls_certificate.cluster.certificates[0].sha1_fingerprint]
# }

# -----------------------------------------------------------------------------
# IAM ROLE FOR NODE GROUP
# -----------------------------------------------------------------------------
# resource "aws_iam_role" "node" {
#   name = "${local.cluster_name}-node-role"
#
#   assume_role_policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [{
#       Action = "sts:AssumeRole"
#       Effect = "Allow"
#       Principal = {
#         Service = "ec2.amazonaws.com"
#       }
#     }]
#   })
# }

# Attach required policies for nodes
# - AmazonEKSWorkerNodePolicy
# - AmazonEKS_CNI_Policy
# - AmazonEC2ContainerRegistryReadOnly

# -----------------------------------------------------------------------------
# MANAGED NODE GROUP
# -----------------------------------------------------------------------------
# resource "aws_eks_node_group" "main" {
#   cluster_name    = aws_eks_cluster.main.name
#   node_group_name = "${local.cluster_name}-nodes"
#   node_role_arn   = aws_iam_role.node.arn
#   subnet_ids      = var.subnet_ids
#
#   instance_types = var.node_instance_types
#   capacity_type  = var.node_capacity_type
#   disk_size      = var.node_disk_size
#
#   scaling_config {
#     desired_size = var.node_desired_size
#     max_size     = var.node_max_size
#     min_size     = var.node_min_size
#   }
#
#   tags = merge(local.common_tags, {
#     Name = "${local.cluster_name}-nodes"
#   })
# }

# -----------------------------------------------------------------------------
# EBS CSI DRIVER (IRSA)
# -----------------------------------------------------------------------------
# EBS CSI needs IRSA to manage EBS volumes

# -----------------------------------------------------------------------------
# CLUSTER AUTOSCALER IRSA
# -----------------------------------------------------------------------------
# Autoscaler needs IRSA to scale node groups

# -----------------------------------------------------------------------------
# AWS-AUTH CONFIGMAP
# -----------------------------------------------------------------------------
# Maps IAM roles to Kubernetes RBAC
