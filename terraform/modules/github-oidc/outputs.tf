output "role_arn" {
  description = "IAM role ARN to configure as AWS_ROLE_TO_ASSUME in GitHub."
  value       = aws_iam_role.github_actions.arn
}

output "oidc_provider_arn" {
  description = "GitHub Actions OIDC provider ARN used by the role."
  value       = local.oidc_provider_arn
}
