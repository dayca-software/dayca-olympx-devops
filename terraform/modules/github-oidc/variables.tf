variable "role_name" {
  description = "IAM role assumed by the GitHub Actions deployment job."
  type        = string
}

variable "github_repository" {
  description = "GitHub repository in owner/name format."
  type        = string

  validation {
    condition     = can(regex("^[^/]+/[^/]+$", var.github_repository))
    error_message = "github_repository must use the owner/name format."
  }
}

variable "github_environment" {
  description = "GitHub environment allowed to assume the role."
  type        = string
  default     = "dev"
}

variable "oidc_provider_arn" {
  description = "Existing GitHub OIDC provider ARN. Leave null to create it."
  type        = string
  default     = null
  nullable    = true
}

variable "oidc_thumbprint" {
  description = "GitHub Actions OIDC root certificate thumbprint used when creating the provider."
  type        = string
  default     = "6938fd4d98bab03faadb97b34396831e3780aea1"
}

variable "ecr_repository_arn" {
  description = "ECR repository ARN allowed for image publishing."
  type        = string
}

variable "ecs_express_service_arn" {
  description = "ECS Express Mode service ARN allowed for deployment operations."
  type        = string
}

variable "tags" {
  description = "Tags applied to IAM resources."
  type        = map(string)
  default     = {}
}
