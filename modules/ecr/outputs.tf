# =============================================================================
# ECR MODULE - OUTPUTS
# =============================================================================

output "repository_urls" {
  description = "Map of repository names to URLs"
  value       = { for k, v in aws_ecr_repository.repos : k => v.repository_url }
}

output "repository_arns" {
  description = "Map of repository names to ARNs"
  value       = { for k, v in aws_ecr_repository.repos : k => v.arn }
}

output "registry_id" {
  description = "ECR registry ID (AWS account ID)"
  value       = length(aws_ecr_repository.repos) > 0 ? values(aws_ecr_repository.repos)[0].registry_id : ""
}

output "login_command" {
  description = "Command to login to ECR"
  value       = length(aws_ecr_repository.repos) > 0 ? "aws ecr get-login-password --region ${data.aws_region.current.name} | docker login --username AWS --password-stdin ${values(aws_ecr_repository.repos)[0].registry_id}.dkr.ecr.${data.aws_region.current.name}.amazonaws.com" : ""
}
