output "load_balancer_controller_role_arn" {
  description = "ARN of the IAM role for AWS Load Balancer Controller"
  value       = aws_iam_role.aws_load_balancer_controller.arn
}

output "load_balancer_controller_service_account" {
  description = "Name of the Kubernetes service account for AWS Load Balancer Controller"
  value       = kubernetes_service_account.aws_load_balancer_controller.metadata[0].name
}
