variable "service_name" {
  description = "ECS Express Mode service name."
  type        = string
}

variable "ecr_repository_url" {
  description = "Private ECR repository URL."
  type        = string
}

variable "image_tag" {
  description = "Image tag used by the ECS Express Mode service."
  type        = string
}

variable "execution_role_arn" {
  description = "ECS task execution role ARN."
  type        = string
}

variable "infrastructure_role_arn" {
  description = "ECS Express Mode infrastructure role ARN."
  type        = string
}

variable "cpu" {
  description = "Fargate CPU units allocated to each task."
  type        = string
}

variable "memory" {
  description = "Fargate memory in MiB allocated to each task."
  type        = string
}

variable "port" {
  description = "Container port receiving HTTP traffic."
  type        = number
}

variable "health_check_path" {
  description = "Application Load Balancer health check path."
  type        = string
  default     = "/api/health"
}

variable "log_group_name" {
  description = "CloudWatch Logs group for ECS task logs."
  type        = string
}

variable "log_stream_prefix" {
  description = "CloudWatch Logs stream prefix."
  type        = string
  default     = "ecs"
}

variable "runtime_environment_variables" {
  description = "Non-sensitive runtime environment variables."
  type        = map(string)
  default     = {}
}

variable "runtime_secret_arns" {
  description = "Secrets Manager ARNs keyed by runtime variable name."
  type        = map(string)
  sensitive   = true
  default     = {}
}

variable "min_task_count" {
  description = "Minimum number of ECS tasks."
  type        = number
  default     = 1
}

variable "max_task_count" {
  description = "Maximum number of ECS tasks."
  type        = number
  default     = 1
}

variable "auto_scaling_metric" {
  description = "ECS Express Mode auto-scaling metric."
  type        = string
  default     = "AVERAGE_CPU"
}

variable "auto_scaling_target_value" {
  description = "Target value for the auto-scaling metric."
  type        = number
  default     = 60
}

variable "wait_for_steady_state" {
  description = "Wait for the Express Mode service to become active during apply."
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags for ECS Express Mode resources."
  type        = map(string)
  default     = {}
}
