variable "aws_region" {
  description = "AWS region for the staging environment."
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Deployment environment name."
  type        = string
  default     = "staging"

  validation {
    condition     = var.environment == "staging"
    error_message = "This stack is intentionally scoped to the staging environment."
  }
}

variable "service_name" {
  description = "Staging API service name."
  type        = string
  default     = "conquest-api-staging"
}

variable "ecr_repository_name" {
  description = "ECR repository name for the API image."
  type        = string
  default     = "conquest-api-staging"
}

variable "image_tag" {
  description = "Deployment tag used by the staging service."
  type        = string
  default     = "staging"
}

variable "api_port" {
  description = "Container port exposed by the NestJS API."
  type        = number
  default     = 3001
}

variable "ecs_cpu" {
  description = "ECS Express Mode CPU units per task."
  type        = string
  default     = "256"
}

variable "ecs_memory" {
  description = "ECS Express Mode memory in MiB per task."
  type        = string
  default     = "512"
}

variable "ecs_min_task_count" {
  description = "Minimum number of ECS Express Mode tasks."
  type        = number
  default     = 1
}

variable "ecs_max_task_count" {
  description = "Maximum number of ECS Express Mode tasks."
  type        = number
  default     = 1
}

variable "ecs_auto_scaling_target_value" {
  description = "ECS Express Mode CPU target percentage."
  type        = number
  default     = 60
}

variable "runtime_environment_variables" {
  description = "Non-sensitive runtime environment variables."
  type        = map(string)
  default     = {}
}

variable "runtime_secret_arns" {
  description = "Existing Secrets Manager ARNs keyed by runtime variable name."
  type        = map(string)
  sensitive   = true

  validation {
    condition = alltrue([
      for name in ["DATABASE_URL", "JWT_SECRET"] : contains(keys(var.runtime_secret_arns), name)
    ])
    error_message = "runtime_secret_arns must include DATABASE_URL and JWT_SECRET."
  }
}

variable "tags" {
  description = "Tags applied to all managed AWS resources."
  type        = map(string)
  default = {
    Project     = "conquest"
    Environment = "staging"
    ManagedBy   = "Terraform"
  }
}

variable "force_delete_ecr" {
  description = "Allow Terraform to delete non-empty ECR repositories. Keep false by default."
  type        = bool
  default     = false
}

variable "github_oidc_enabled" {
  description = "Create the GitHub Actions OIDC provider and deployment role."
  type        = bool
  default     = false
}

variable "github_oidc_role_name" {
  description = "IAM role assumed by the GitHub Actions deployment workflow."
  type        = string
  default     = "conquest-github-actions-staging"
}

variable "github_repository" {
  description = "GitHub repository in owner/name format. Required when OIDC is enabled."
  type        = string
  default     = ""
}

variable "github_environment" {
  description = "GitHub environment bound to the deployment role."
  type        = string
  default     = "staging"
}

variable "github_oidc_provider_arn" {
  description = "Existing GitHub OIDC provider ARN. Leave null to let Terraform create it."
  type        = string
  default     = null
  nullable    = true
}

variable "github_oidc_thumbprint" {
  description = "GitHub Actions OIDC root certificate thumbprint when creating the provider."
  type        = string
  default     = "6938fd4d98bab03faadb97b34396831e3780aea1"
}
