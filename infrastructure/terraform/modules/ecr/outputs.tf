output "demostore_repository_url" {
  description = "ECR repository URL for DemoStore"
  value       = aws_ecr_repository.demostore.repository_url
}

output "demostore_repository_arn" {
  description = "ECR repository ARN for DemoStore"
  value       = aws_ecr_repository.demostore.arn
}

output "opssentinel_repository_url" {
  description = "ECR repository URL for OpsSentinel backend"
  value       = aws_ecr_repository.opssentinel.repository_url
}

output "opssentinel_repository_arn" {
  description = "ECR repository ARN for OpsSentinel backend"
  value       = aws_ecr_repository.opssentinel.arn
}

output "opssentinel_frontend_repository_url" {
  description = "ECR repository URL for OpsSentinel frontend"
  value       = aws_ecr_repository.opssentinel_frontend.repository_url
}

