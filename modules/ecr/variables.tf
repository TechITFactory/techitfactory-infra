# =============================================================================
# ECR MODULE - VARIABLES
# =============================================================================

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "environment" {
  description = "Environment (dev/prod)"
  type        = string
}

variable "repositories" {
  description = "List of ECR repository names"
  type        = list(string)
  default     = []
}

variable "image_tag_mutability" {
  description = "Tag mutability: MUTABLE or IMMUTABLE"
  type        = string
  default     = "MUTABLE"

  # MUTABLE: Same tag can be overwritten (e.g., latest)
  # IMMUTABLE: Tags are permanent (good for prod releases)
}

variable "scan_on_push" {
  description = "Enable image scanning on push"
  type        = bool
  default     = true

  # WHY ENABLE?
  # - Finds vulnerabilities automatically
  # - Free basic scanning with ECR
}

variable "lifecycle_policy_count" {
  description = "Number of tagged images to keep"
  type        = number
  default     = 30

  # Older images expire to save storage costs
}

variable "untagged_image_days" {
  description = "Days to keep untagged images"
  type        = number
  default     = 7
}

variable "tags" {
  description = "Additional tags"
  type        = map(string)
  default     = {}
}
