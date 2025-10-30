variable "backend_repository_name" {
  description = "Name of the ECR repository for backend"
  type        = string
  default     = "iai-backend"
}

variable "frontend_repository_name" {
  description = "Name of the ECR repository for frontend"
  type        = string
  default     = "iai-frontend"
}

variable "max_image_count" {
  description = "Maximum number of images to keep in ECR"
  type        = number
  default     = 3
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
