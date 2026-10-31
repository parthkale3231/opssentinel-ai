output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = aws_subnet.private[*].id
}

output "eks_cluster_sg_id" {
  description = "Security group ID for EKS cluster control plane"
  value       = aws_security_group.eks_cluster.id
}


output "vpc_cidr" {
  description = "CIDR block of the VPC"
  value       = aws_vpc.main.cidr_block
}

output "vpc_endpoints_sg_id" {
  description = "Security group ID for VPC interface endpoints (if enabled)"
  value       = try(aws_security_group.vpc_endpoints[0].id, "")
}

output "nat_gateway_id" {
  description = "ID of the NAT Gateway (if enabled)"
  value       = try(aws_nat_gateway.main[0].id, "")
}


