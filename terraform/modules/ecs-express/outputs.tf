output "service_arn" {
  description = "ECS Express Mode service ARN."
  value       = aws_ecs_express_gateway_service.this.service_arn
}

output "service_url" {
  description = "Public or private ECS Express Mode service endpoint."
  value       = try(aws_ecs_express_gateway_service.this.ingress_paths[0].endpoint, null)
}

output "service_revision_arn" {
  description = "Current ECS Express Mode service revision ARN."
  value       = aws_ecs_express_gateway_service.this.service_revision_arn
}
