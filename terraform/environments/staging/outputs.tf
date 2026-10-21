output "ecr_repository_url" {
  description = "ECR repository URL for staging API images."
  value       = module.ecr.repository_url
}

output "app_runner_service_arn" {
  description = "App Runner service ARN used by the staging deployment workflow."
  value       = module.app_runner.service_arn
}

output "app_runner_service_url" {
  description = "Managed App Runner staging URL."
  value       = module.app_runner.service_url
}

output "app_runner_ecr_access_role_arn" {
  description = "IAM role used by App Runner to pull staging images from ECR."
  value       = aws_iam_role.apprunner_ecr_access.arn
}

output "github_actions_role_arn" {
  description = "IAM role ARN for the staging GitHub Actions workflow, when OIDC is enabled."
  value       = try(module.github_oidc[0].role_arn, null)
}
