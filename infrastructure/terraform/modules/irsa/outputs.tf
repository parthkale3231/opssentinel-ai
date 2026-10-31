output "opssentinel_sa_role_arn" {
  description = "ARN of the OpsSentinel ServiceAccount IAM role for IRSA"
  value       = aws_iam_role.opssentinel_sa.arn
}

output "opssentinel_sa_role_name" {
  description = "Name of the OpsSentinel ServiceAccount IAM role"
  value       = aws_iam_role.opssentinel_sa.name
}

