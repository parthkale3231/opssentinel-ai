output "eks_cluster_name" { value = module.eks.cluster_name }
output "eks_cluster_endpoint" {
  description = "EKS cluster API endpoint"
  value       = module.eks.cluster_endpoint
  sensitive   = true
}
output "ecr_demostore_url" { value = module.ecr.demostore_repository_url }
output "ecr_opssentinel_url" { value = module.ecr.opssentinel_repository_url }
output "opssentinel_sa_role_arn" { value = module.irsa.opssentinel_sa_role_arn }
output "kubectl_config_command" { value = "aws eks update-kubeconfig --region ${var.aws_region} --name ${module.eks.cluster_name}" }
