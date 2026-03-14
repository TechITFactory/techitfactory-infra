# =============================================================================
# EKS MODULE - VARIABLES
# =============================================================================
#
# PURPOSE:
# Define input variables for the EKS module.
# These allow customization per environment (dev/prod).
#
# USAGE:
# module "eks" {
#   source       = "../../modules/eks"
#   project_name = "techitfactory"
#   environment  = "dev"
#   vpc_id       = module.vpc.vpc_id
#   subnet_ids   = module.vpc.private_subnet_ids
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
# NETWORK CONFIGURATION
# -----------------------------------------------------------------------------

variable "vpc_id" {
  description = "VPC ID for EKS cluster"
  type        = string
}

variable "subnet_ids" {
  description = "Subnet IDs for EKS nodes (private subnets)"
  type        = list(string)
}

# -----------------------------------------------------------------------------
# CLUSTER CONFIGURATION
# -----------------------------------------------------------------------------

variable "cluster_version" {
  description = "Kubernetes version"
  type        = string
  default     = "1.28"

  # WHY 1.28?
  # - Latest stable version as of course creation
  # - EKS supports n-3 versions (update regularly)
  # - Check: aws eks describe-addon-versions --kubernetes-version 1.28
}

variable "cluster_endpoint_public_access" {
  description = "Enable public access to cluster API"
  type        = bool
  default     = true

  # WHY PUBLIC ACCESS?
  # - Needed for kubectl access from local machine
  # - For production: set to false and use VPN/bastion
}

variable "cluster_endpoint_private_access" {
  description = "Enable private access to cluster API"
  type        = bool
  default     = true

  # WHY PRIVATE ACCESS?
  # - Allows nodes to communicate with control plane privately
  # - Required for nodes in private subnets
}

# -----------------------------------------------------------------------------
# NODE GROUP CONFIGURATION
# -----------------------------------------------------------------------------

variable "node_instance_types" {
  description = "Instance types for managed node group"
  type        = list(string)
  default     = ["t3.medium"]

  # WHY t3.medium?
  # - 2 vCPU, 4GB RAM - good balance for learning
  # - ~$0.0416/hour (~$30/month per node)
  # - For production: use m5.large or larger
}

variable "node_capacity_type" {
  description = "Capacity type: ON_DEMAND or SPOT"
  type        = string
  default     = "ON_DEMAND"

  # SPOT INSTANCES:
  # - 60-90% cheaper but can be interrupted
  # - Good for dev/test workloads
  # - For prod: use ON_DEMAND for critical, SPOT for batch
}

variable "node_desired_size" {
  description = "Desired number of nodes"
  type        = number
  default     = 2
}

variable "node_min_size" {
  description = "Minimum number of nodes"
  type        = number
  default     = 1
}

variable "node_max_size" {
  description = "Maximum number of nodes"
  type        = number
  default     = 4
}

variable "node_disk_size" {
  description = "Disk size in GB for nodes"
  type        = number
  default     = 50
}

# -----------------------------------------------------------------------------
# ADD-ONS CONFIGURATION
# -----------------------------------------------------------------------------

variable "enable_cluster_autoscaler" {
  description = "Create IRSA role for Cluster Autoscaler"
  type        = bool
  default     = true
}

variable "enable_ebs_csi_driver" {
  description = "Install EBS CSI driver add-on"
  type        = bool
  default     = true

  # WHY EBS CSI?
  # - Required for dynamic PersistentVolume provisioning
  # - Replaces deprecated in-tree provisioner
}

variable "enable_metrics_server" {
  description = "Install metrics-server (for HPA)"
  type        = bool
  default     = true

  # WHY METRICS SERVER?
  # - Required for Horizontal Pod Autoscaler
  # - Required for `kubectl top` command
}

# -----------------------------------------------------------------------------
# TAGGING
# -----------------------------------------------------------------------------

variable "tags" {
  description = "Additional tags for resources"
  type        = map(string)
  default     = {}
}

variable "enable_alb_controller" {
  description = "Create IRSA role for AWS Load Balancer Controller"
  type        = bool
  default     = true

  # WHY ALB CONTROLLER?
  # - Provisions ALB/NLB via Kubernetes Ingress
  # - Required for production-grade load balancing
}

