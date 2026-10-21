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

data "aws_iam_policy_document" "ecr_access_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["build.apprunner.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "apprunner_ecr_access" {
  name               = "${var.service_name}-ecr-access"
  assume_role_policy = data.aws_iam_policy_document.ecr_access_assume_role.json
  tags               = var.tags
}

data "aws_iam_policy_document" "ecr_access" {
  statement {
    effect = "Allow"
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:BatchGetImage",
      "ecr:DescribeImages",
      "ecr:GetDownloadUrlForLayer",
    ]
    resources = [module.ecr.repository_arn]
  }

  statement {
    effect    = "Allow"
    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "apprunner_ecr_access" {
  name   = "${var.service_name}-ecr-pull"
  role   = aws_iam_role.apprunner_ecr_access.id
  policy = data.aws_iam_policy_document.ecr_access.json
}

data "aws_iam_policy_document" "apprunner_instance_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["tasks.apprunner.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "apprunner_instance" {
  name               = "${var.service_name}-instance"
  assume_role_policy = data.aws_iam_policy_document.apprunner_instance_assume_role.json
  tags               = var.tags
}

data "aws_iam_policy_document" "apprunner_secrets" {
  statement {
    effect    = "Allow"
    actions   = ["secretsmanager:GetSecretValue"]
    resources = values(var.runtime_secret_arns)
  }
}

resource "aws_iam_role_policy" "apprunner_secrets" {
  name   = "${var.service_name}-secrets-read"
  role   = aws_iam_role.apprunner_instance.id
  policy = data.aws_iam_policy_document.apprunner_secrets.json
}

module "app_runner" {
  source = "../../modules/app-runner"

  service_name                  = var.service_name
  ecr_repository_url            = module.ecr.repository_url
  image_tag                     = var.image_tag
  ecr_access_role_arn           = aws_iam_role.apprunner_ecr_access.arn
  instance_role_arn             = aws_iam_role.apprunner_instance.arn
  cpu                           = var.api_cpu
  memory                        = var.api_memory
  port                          = var.api_port
  min_size                      = var.min_instance_size
  max_size                      = var.max_instance_size
  max_concurrency               = var.max_concurrency
  runtime_environment_variables = local.runtime_environment_variables
  runtime_environment_secrets   = var.runtime_secret_arns
  tags                          = var.tags
}

module "github_oidc" {
  count  = var.github_oidc_enabled ? 1 : 0
  source = "../../modules/github-oidc"

  role_name              = var.github_oidc_role_name
  github_repository      = var.github_repository
  github_environment     = var.github_environment
  oidc_provider_arn      = var.github_oidc_provider_arn
  oidc_thumbprint        = var.github_oidc_thumbprint
  ecr_repository_arn     = module.ecr.repository_arn
  app_runner_service_arn = module.app_runner.service_arn
  tags                   = var.tags
}
