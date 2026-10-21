resource "aws_apprunner_auto_scaling_configuration_version" "this" {
  auto_scaling_configuration_name = "${var.service_name}-scaling"
  max_concurrency                 = var.max_concurrency
  max_size                        = var.max_size
  min_size                        = var.min_size
  tags                            = var.tags
}

resource "aws_apprunner_service" "this" {
  service_name                   = var.service_name
  auto_scaling_configuration_arn = aws_apprunner_auto_scaling_configuration_version.this.arn

  source_configuration {
    auto_deployments_enabled = false

    authentication_configuration {
      access_role_arn = var.ecr_access_role_arn
    }

    image_repository {
      image_identifier      = "${var.ecr_repository_url}:${var.image_tag}"
      image_repository_type = "ECR"

      image_configuration {
        port                          = tostring(var.port)
        runtime_environment_variables = var.runtime_environment_variables
        runtime_environment_secrets   = var.runtime_environment_secrets
      }
    }
  }

  instance_configuration {
    cpu               = var.cpu
    memory            = var.memory
    instance_role_arn = var.instance_role_arn
  }

  health_check_configuration {
    healthy_threshold   = 1
    interval            = 20
    path                = "/api/health"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 5
  }

  tags = var.tags
}
