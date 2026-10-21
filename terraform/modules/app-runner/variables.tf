variable "service_name" {
  description = "App Runner service name."
  type        = string
}

variable "ecr_repository_url" {
  description = "Private ECR repository URL."
  type        = string
}

variable "image_tag" {
  description = "Image tag App Runner tracks."
  type        = string
}

variable "ecr_access_role_arn" {
  description = "App Runner ECR access role ARN."
  type        = string
}

variable "instance_role_arn" {
  description = "App Runner runtime instance role ARN."
  type        = string
}

variable "cpu" {
  description = "App Runner CPU size."
  type        = string
}

variable "memory" {
  description = "App Runner memory size."
  type        = string
}

variable "port" {
  description = "Container port."
  type        = number
}

variable "min_size" {
  description = "Minimum instances."
  type        = number
}

variable "max_size" {
  description = "Maximum instances."
  type        = number
}

variable "max_concurrency" {
  description = "Maximum concurrent requests per instance."
  type        = number
}

variable "runtime_environment_variables" {
  description = "Non-sensitive runtime environment variables."
  type        = map(string)
  default     = {}
}

variable "runtime_environment_secrets" {
  description = "Secrets Manager ARNs keyed by runtime variable name."
  type        = map(string)
  sensitive   = true
  default     = {}
}

variable "tags" {
  description = "Tags for App Runner resources."
  type        = map(string)
  default     = {}
}
