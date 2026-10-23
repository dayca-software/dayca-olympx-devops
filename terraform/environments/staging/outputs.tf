output "ecr_repository_url" {
  description = "ECR repository URL for staging API images."
  value       = module.ecr.repository_url
}

output "ecs_express_service_arn" {
  description = "ECS Express Mode service ARN used by the staging deployment workflow."
  value       = module.ecs_express.service_arn
}

output "ecs_express_service_url" {
  description = "Managed ECS Express Mode staging URL."
  value       = module.ecs_express.service_url
}

output "ecs_task_execution_role_arn" {
  description = "ECS task execution role ARN."
  value       = aws_iam_role.ecs_task_execution.arn
}

output "ecs_infrastructure_role_arn" {
  description = "ECS Express Mode infrastructure role ARN."
  value       = aws_iam_role.ecs_infrastructure.arn
}

output "github_actions_role_arn" {
  description = "IAM role ARN for the staging GitHub Actions workflow, when OIDC is enabled."
  value       = try(module.github_oidc[0].role_arn, null)
}
