# =============================================================================
# TERRAFORM BOOTSTRAP - VARIABLES
# =============================================================================
#
# PURPOSE:
# Define input variables that customize the bootstrap configuration.
# Variables make our Terraform code reusable and configurable.
#
# HOW TO OVERRIDE:
# 1. terraform.tfvars file: project_name = "myproject"
# 2. Command line: terraform apply -var="project_name=myproject"
# 3. Environment variable: export TF_VAR_project_name="myproject"
# =============================================================================

# -----------------------------------------------------------------------------
# PROJECT NAME
# -----------------------------------------------------------------------------
# Used as a prefix for all resource names
# Examples: techitfactory-tfstate-xxx, techitfactory-tflock
#
# Naming convention helps with:
# - Resource identification in AWS Console
# - Cost allocation (filter by project name)
# - Automation (scripts can target resources by name pattern)

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "techitfactory"
}

# -----------------------------------------------------------------------------
# ENVIRONMENT
# -----------------------------------------------------------------------------
# Identifies which environment this bootstrap serves
# For bootstrap, we use "shared" because state management is shared across envs
#
# In environment-specific configs (dev/prod), this would be "dev" or "prod"

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "shared"
}

# -----------------------------------------------------------------------------
# AWS REGION
# -----------------------------------------------------------------------------
# Which AWS region to create resources in
#
# WHY ap-south-1 (Mumbai)?
# - Low latency for India-based development
# - Cost-effective compared to US regions
# - Has all services we need (EKS, etc.)
#
# CONSIDERATION: Your state bucket should be in the same region as your
# infrastructure to minimize latency during terraform operations

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-south-1"
}

# -----------------------------------------------------------------------------
# TAGS
# -----------------------------------------------------------------------------
# Common tags applied to ALL resources via provider default_tags
#
# WHY TAGGING?
# - Cost tracking: Filter AWS bills by Project tag
# - Ownership: Know who/what manages the resource
# - Automation: Scripts can target resources by tags
#
# BEST PRACTICE: Always tag resources with at minimum:
# - Project: Which project owns this
# - ManagedBy: Terraform (vs manual, CloudFormation, etc.)
# - Environment: dev, staging, prod, shared

variable "tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default = {
    Project   = "TechITFactory"
    ManagedBy = "Terraform"
    Purpose   = "DevOps Course"
  }
}
