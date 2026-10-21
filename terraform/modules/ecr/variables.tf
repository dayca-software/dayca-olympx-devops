variable "repository_name" {
  description = "ECR repository name."
  type        = string
}

variable "force_delete" {
  description = "Allow deletion of a non-empty repository."
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags for the repository."
  type        = map(string)
  default     = {}
}
