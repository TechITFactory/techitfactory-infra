variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "techitfactory"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "shared"
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-south-1"
}

variable "tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default = {
    Project   = "TechITFactory"
    ManagedBy = "Terraform"
    Purpose   = "DevOps Course"
  }
}
