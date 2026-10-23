resource "aws_ecs_express_gateway_service" "this" {
  service_name           = var.service_name
  execution_role_arn     = var.execution_role_arn
  infrastructure_role_arn = var.infrastructure_role_arn
  health_check_path      = var.health_check_path
  cpu                    = var.cpu
  memory                 = var.memory
  wait_for_steady_state  = var.wait_for_steady_state

  primary_container {
    image          = "${var.ecr_repository_url}:${var.image_tag}"
    container_port = var.port

    aws_logs_configuration = [{
      log_group         = var.log_group_name
      log_stream_prefix = var.log_stream_prefix
    }]

    dynamic "environment" {
      for_each = var.runtime_environment_variables

      content {
        name  = environment.key
        value = environment.value
      }
    }

    dynamic "secret" {
      for_each = var.runtime_secret_arns

      content {
        name       = secret.key
        value_from = secret.value
      }
    }
  }

  scaling_target = [{
    min_task_count           = var.min_task_count
    max_task_count           = var.max_task_count
    auto_scaling_metric      = var.auto_scaling_metric
    auto_scaling_target_value = var.auto_scaling_target_value
  }]

  tags = var.tags
}
