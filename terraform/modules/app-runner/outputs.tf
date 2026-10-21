output "service_arn" {
  description = "App Runner service ARN."
  value       = aws_apprunner_service.this.arn
}

output "service_url" {
  description = "App Runner service URL."
  value       = aws_apprunner_service.this.service_url
}
