# =============================================================================
# ECR MODULE - MAIN
# =============================================================================
#
# PURPOSE:
# Creates ECR repositories for container images with:
# - Lifecycle policies for cleanup
# - Image scanning enabled
# - Encryption at rest
#
# NAMING CONVENTION:
# Repository names: techitfactory/api-gateway, techitfactory/user-service, etc.
# =============================================================================

locals {
  common_tags = merge(
    {
      Module      = "ecr"
      Environment = var.environment
    },
    var.tags
  )
}

# =============================================================================
# ECR REPOSITORIES
# =============================================================================

resource "aws_ecr_repository" "repos" {
  for_each = toset(var.repositories)

  name                 = "${var.project_name}/${each.key}"
  image_tag_mutability = var.image_tag_mutability

  image_scanning_configuration {
    scan_on_push = var.scan_on_push
  }

  encryption_configuration {
    encryption_type = "AES256"
  }

  tags = merge(local.common_tags, {
    Name    = "${var.project_name}/${each.key}"
    Service = each.key
  })
}

# =============================================================================
# LIFECYCLE POLICIES
# =============================================================================
# Automatically clean up old images to save storage costs

resource "aws_ecr_lifecycle_policy" "repos" {
  for_each   = toset(var.repositories)
  repository = aws_ecr_repository.repos[each.key].name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last ${var.lifecycle_policy_count} tagged images"
        selection = {
          tagStatus     = "tagged"
          tagPrefixList = ["v", "release", "main-"]
          countType     = "imageCountMoreThan"
          countNumber   = var.lifecycle_policy_count
        }
        action = {
          type = "expire"
        }
      },
      {
        rulePriority = 2
        description  = "Delete untagged images older than ${var.untagged_image_days} days"
        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = var.untagged_image_days
        }
        action = {
          type = "expire"
        }
      },
      {
        rulePriority = 3
        description  = "Delete PR images after 14 days"
        selection = {
          tagStatus     = "tagged"
          tagPrefixList = ["pr-"]
          countType     = "sinceImagePushed"
          countUnit     = "days"
          countNumber   = 14
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}
