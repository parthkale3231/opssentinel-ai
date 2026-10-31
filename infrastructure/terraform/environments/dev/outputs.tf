# ─── VPC Outputs ──────────────────────────────────────────────────────────────
output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "IDs of public subnets"
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "IDs of private subnets"
  value       = module.vpc.private_subnet_ids
}

output "nat_gateway_id" {
  description = "ID of the NAT Gateway"
  value       = module.vpc.nat_gateway_id
}

# ─── EKS Outputs ──────────────────────────────────────────────────────────────
output "eks_cluster_name" {
  description = "Name of the EKS cluster"
  value       = module.eks.cluster_name
}

output "eks_cluster_endpoint" {
  description = "Endpoint URL of the EKS cluster"
  value       = module.eks.cluster_endpoint
  sensitive   = true
}

output "eks_cluster_ca_data" {
  description = "Certificate authority data for the EKS cluster"
  value       = module.eks.cluster_ca_data
  sensitive   = true
}

output "eks_node_group_name" {
  description = "Name of the EKS managed node group"
  value       = module.eks.node_group_name
}

output "eks_oidc_provider_arn" {
  description = "ARN of the EKS OIDC provider"
  value       = module.eks.oidc_provider_arn
}

# ─── ECR Outputs ──────────────────────────────────────────────────────────────
output "ecr_demostore_url" {
  description = "ECR repository URL for DemoStore"
  value       = module.ecr.demostore_repository_url
}

output "ecr_opssentinel_url" {
  description = "ECR repository URL for OpsSentinel"
  value       = module.ecr.opssentinel_repository_url
}

# ─── IAM & IRSA Outputs ───────────────────────────────────────────────────────
output "eks_cluster_role_arn" {
  description = "ARN of the EKS cluster IAM role"
  value       = module.iam.eks_cluster_role_arn
}

output "eks_node_role_arn" {
  description = "ARN of the EKS worker node IAM role"
  value       = module.iam.eks_node_role_arn
}

output "opssentinel_sa_role_arn" {
  description = "ARN of the OpsSentinel ServiceAccount IAM role for IRSA"
  value       = module.irsa.opssentinel_sa_role_arn
}

# ─── kubectl config command ───────────────────────────────────────────────────
output "kubectl_config_command" {
  description = "Command to configure kubectl for this cluster"
  value       = "aws eks update-kubeconfig --region ${var.aws_region} --name ${module.eks.cluster_name}"
}
