locals {
  oidc_provider_arn = var.oidc_provider_arn != null ? var.oidc_provider_arn : aws_iam_openid_connect_provider.github[0].arn
  subject           = "repo:${var.github_repository}:environment:${var.github_environment}"
}

resource "aws_iam_openid_connect_provider" "github" {
  count = var.oidc_provider_arn == null ? 1 : 0

  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [var.oidc_thumbprint]
  tags            = var.tags
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [local.oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values   = [local.subject]
    }
  }
}

resource "aws_iam_role" "github_actions" {
  name               = var.role_name
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
  tags               = var.tags
}

data "aws_iam_policy_document" "deployment" {
  statement {
    effect = "Allow"
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:CompleteLayerUpload",
      "ecr:InitiateLayerUpload",
      "ecr:PutImage",
      "ecr:UploadLayerPart",
    ]
    resources = [var.ecr_repository_arn]
  }

  statement {
    effect    = "Allow"
    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "apprunner:DescribeService",
      "apprunner:StartDeployment",
    ]
    resources = [var.app_runner_service_arn]
  }

  statement {
    effect    = "Allow"
    actions   = ["apprunner:DescribeOperation"]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "deployment" {
  name   = "${var.role_name}-deployment"
  role   = aws_iam_role.github_actions.id
  policy = data.aws_iam_policy_document.deployment.json
}
