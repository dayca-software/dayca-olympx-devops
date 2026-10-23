locals {
  runtime_environment_variables = merge(
    {
      NODE_ENV                         = "staging"
      PORT                             = tostring(var.api_port)
      ENABLE_DEMO_USERS                = "false"
      PLACES_CACHE_ENABLED             = "true"
      FIREBASE_USE_APPLICATION_DEFAULT = "false"
    },
    var.runtime_environment_variables
  )
}

module "ecr" {
  source = "../../modules/ecr"

  repository_name = var.ecr_repository_name
  force_delete    = var.force_delete_ecr
  tags            = var.tags
}

data "aws_iam_policy_document" "ecs_task_execution_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ecs_task_execution" {
  name               = "${var.service_name}-ecs-task-execution"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_execution_assume_role.json
  tags               = var.tags
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution" {
  role       = aws_iam_role.ecs_task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

data "aws_iam_policy_document" "ecs_task_execution_secrets" {
  statement {
    effect    = "Allow"
    actions   = ["secretsmanager:GetSecretValue"]
    resources = values(var.runtime_secret_arns)
  }
}

resource "aws_iam_role_policy" "ecs_task_execution_secrets" {
  name   = "${var.service_name}-ecs-secrets-read"
  role   = aws_iam_role.ecs_task_execution.id
  policy = data.aws_iam_policy_document.ecs_task_execution_secrets.json
}

data "aws_iam_policy_document" "ecs_infrastructure_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ecs_infrastructure" {
  name               = "${var.service_name}-ecs-infrastructure"
  assume_role_policy = data.aws_iam_policy_document.ecs_infrastructure_assume_role.json
  tags               = var.tags
}

resource "aws_iam_role_policy_attachment" "ecs_infrastructure" {
  role       = aws_iam_role.ecs_infrastructure.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSInfrastructureRoleforExpressGatewayServices"
}

resource "aws_cloudwatch_log_group" "ecs" {
  name              = "/aws/ecs/${var.service_name}"
  retention_in_days = 30
  tags              = var.tags
}

module "ecs_express" {
  source = "../../modules/ecs-express"

  service_name                  = var.service_name
  ecr_repository_url            = module.ecr.repository_url
  image_tag                     = var.image_tag
  execution_role_arn            = aws_iam_role.ecs_task_execution.arn
  infrastructure_role_arn       = aws_iam_role.ecs_infrastructure.arn
  cpu                           = var.ecs_cpu
  memory                        = var.ecs_memory
  port                          = var.api_port
  log_group_name                = aws_cloudwatch_log_group.ecs.name
  runtime_environment_variables = local.runtime_environment_variables
  runtime_secret_arns           = var.runtime_secret_arns
  min_task_count                = var.ecs_min_task_count
  max_task_count                = var.ecs_max_task_count
  auto_scaling_target_value     = var.ecs_auto_scaling_target_value
  tags                          = var.tags

  depends_on = [
    aws_iam_role_policy_attachment.ecs_task_execution,
    aws_iam_role_policy.ecs_task_execution_secrets,
    aws_iam_role_policy_attachment.ecs_infrastructure,
  ]
}

module "github_oidc" {
  count  = var.github_oidc_enabled ? 1 : 0
  source = "../../modules/github-oidc"

  role_name               = var.github_oidc_role_name
  github_repository       = var.github_repository
  github_environment      = var.github_environment
  oidc_provider_arn       = var.github_oidc_provider_arn
  oidc_thumbprint         = var.github_oidc_thumbprint
  ecr_repository_arn      = module.ecr.repository_arn
  ecs_express_service_arn = module.ecs_express.service_arn
  tags                    = var.tags
}
