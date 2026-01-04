# =============================================================================
# GITHUB OIDC PROVIDER FOR AWS AUTHENTICATION
# =============================================================================
#
# PURPOSE:
# This file configures GitHub Actions to authenticate with AWS using OIDC
# (OpenID Connect) instead of static access keys.
#
# WHY OIDC?
# - No static AWS keys stored in GitHub Secrets = more secure
# - Short-lived credentials = reduced risk if compromised
# - AWS CloudTrail shows which GitHub repo/workflow assumed the role
#
# HOW IT WORKS:
# 1. GitHub Actions requests a JWT token from GitHub's OIDC provider
# 2. The token contains claims about the repo, branch, workflow, etc.
# 3. AWS STS validates the token and issues temporary credentials
# 4. Terraform uses these credentials (valid for ~1 hour)
#
# RESOURCES CREATED:
# - aws_iam_openid_connect_provider: Trust relationship with GitHub
# - aws_iam_role: Role that GitHub Actions assumes
# - aws_iam_role_policy: Permissions for Terraform operations
# =============================================================================

terraform {
  required_providers {
    # TLS provider - for fetching GitHub's OIDC certificate thumbprint
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }
}

# -----------------------------------------------------------------------------
# GITHUB OIDC PROVIDER
# -----------------------------------------------------------------------------
# Fetches GitHub's OIDC provider certificate for validation
# AWS uses this thumbprint to verify tokens are from GitHub

data "tls_certificate" "github" {
  url = "https://token.actions.githubusercontent.com/.well-known/openid-configuration"
}

# Creates the OIDC identity provider in AWS IAM
# This establishes trust between AWS and GitHub's identity service
resource "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"

  # The audience claim - GitHub Actions always uses this value
  client_id_list = ["sts.amazonaws.com"]

  # Certificate thumbprint for token validation
  thumbprint_list = [data.tls_certificate.github.certificates[0].sha1_fingerprint]

  tags = {
    Name = "github-actions-oidc"
  }
}

# =============================================================================
# IAM ROLE FOR GITHUB ACTIONS
# =============================================================================
# This role is assumed by GitHub Actions workflows
# The trust policy restricts which repos can assume this role

resource "aws_iam_role" "github_actions_terraform" {
  name = "${var.project_name}-github-terraform"

  # TRUST POLICY
  # Defines WHO can assume this role (GitHub Actions from specific repos)
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.github.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          # Verify the token is for AWS
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          # SECURITY: Restrict to specific repos only!
          # The :* at the end allows any branch/ref
          StringLike = {
            "token.actions.githubusercontent.com:sub" = [
              "repo:TechITFactory/techitfactory-infra:*",
              "repo:TechITFactory/techitfactory-app:*",
              "repo:TechITFactory/techitfactory-gitops:*"
            ]
          }
        }
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-github-terraform"
  }
}

# =============================================================================
# IAM POLICY FOR TERRAFORM OPERATIONS
# =============================================================================
# Defines WHAT the role can do (permissions for Terraform)

resource "aws_iam_role_policy" "github_actions_terraform" {
  name = "terraform-permissions"
  role = aws_iam_role.github_actions_terraform.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # -----------------------------------------------------------------
      # TERRAFORM STATE ACCESS
      # -----------------------------------------------------------------
      # Allows reading/writing state to S3 bucket
      {
        Sid    = "TerraformStateAccess"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.terraform_state.arn,
          "${aws_s3_bucket.terraform_state.arn}/*"
        ]
      },
      # -----------------------------------------------------------------
      # TERRAFORM STATE LOCKING
      # -----------------------------------------------------------------
      # Allows acquiring/releasing locks in DynamoDB
      {
        Sid    = "TerraformLockAccess"
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:DeleteItem"
        ]
        Resource = aws_dynamodb_table.terraform_lock.arn
      },
      # -----------------------------------------------------------------
      # KMS ACCESS
      # -----------------------------------------------------------------
      # Allows encrypting/decrypting state with KMS key
      {
        Sid    = "KMSAccess"
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:Encrypt",
          "kms:GenerateDataKey"
        ]
        Resource = aws_kms_key.terraform_state.arn
      },
      # -----------------------------------------------------------------
      # EC2/VPC PERMISSIONS
      # -----------------------------------------------------------------
      # Full access to EC2/VPC resources for infrastructure management
      # In production, you'd scope this down to specific resources
      {
        Sid    = "EC2VPCFullAccess"
        Effect = "Allow"
        Action = [
          "ec2:*",
          "elasticloadbalancing:*"
        ]
        Resource = "*"
      },
      # -----------------------------------------------------------------
      # EKS PERMISSIONS
      # -----------------------------------------------------------------
      # Full access to EKS for cluster management
      {
        Sid    = "EKSFullAccess"
        Effect = "Allow"
        Action = [
          "eks:*",
          "iam:CreateServiceLinkedRole"
        ]
        Resource = "*"
      },
      # -----------------------------------------------------------------
      # IAM PERMISSIONS
      # -----------------------------------------------------------------
      # Needed to create roles for EKS, IRSA, etc.
      # Be careful with IAM permissions - they're powerful!
      {
        Sid    = "IAMManagement"
        Effect = "Allow"
        Action = [
          "iam:CreateRole",
          "iam:DeleteRole",
          "iam:AttachRolePolicy",
          "iam:DetachRolePolicy",
          "iam:PutRolePolicy",
          "iam:DeleteRolePolicy",
          "iam:GetRole",
          "iam:GetRolePolicy",
          "iam:ListRolePolicies",
          "iam:ListAttachedRolePolicies",
          "iam:PassRole",
          "iam:CreateOpenIDConnectProvider",
          "iam:DeleteOpenIDConnectProvider",
          "iam:GetOpenIDConnectProvider",
          "iam:TagRole",
          "iam:UntagRole",
          "iam:ListInstanceProfilesForRole"
        ]
        Resource = "*"
      },
      # -----------------------------------------------------------------
      # ROUTE53 & ACM PERMISSIONS
      # -----------------------------------------------------------------
      # For DNS and TLS certificate management
      {
        Sid    = "Route53Access"
        Effect = "Allow"
        Action = [
          "route53:*",
          "acm:*"
        ]
        Resource = "*"
      }
    ]
  })
}

# =============================================================================
# OUTPUTS
# =============================================================================
# The role ARN is needed for GitHub Actions workflow configuration

output "github_actions_role_arn" {
  description = "ARN of IAM role for GitHub Actions - add this to GitHub Secrets as AWS_ROLE_ARN"
  value       = aws_iam_role.github_actions_terraform.arn
}

output "oidc_provider_arn" {
  description = "ARN of the GitHub OIDC provider"
  value       = aws_iam_openid_connect_provider.github.arn
}
