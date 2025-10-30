output "backend_repository_url" {
  description = "ECR repository URL for backend"
  value       = aws_ecr_repository.backend.repository_url
}

output "frontend_repository_url" {
  description = "ECR repository URL for frontend"
  value       = aws_ecr_repository.frontend.repository_url
}

output "backend_repository_name" {
  description = "ECR repository name for backend"
  value       = aws_ecr_repository.backend.name
}

output "frontend_repository_name" {
  description = "ECR repository name for frontend"
  value       = aws_ecr_repository.frontend.name
}

output "backend_repository_arn" {
  description = "ECR repository ARN for backend"
  value       = aws_ecr_repository.backend.arn
}

output "frontend_repository_arn" {
  description = "ECR repository ARN for frontend"
  value       = aws_ecr_repository.frontend.arn
}
