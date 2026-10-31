variable "aws_region" {
  description = "AWS region for all resources"
  type        = string
  default     = "ap-south-1"
}

variable "environment" {
  description = "Deployment environment name"
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "Project name used in resource naming"
  type        = string
  default     = "opssentinel"
}

# ─── VPC & Connectivity ───────────────────────────────────────────────────────
variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets (one per AZ)"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets (one per AZ)"
  type        = list(string)
  default     = ["10.0.10.0/24", "10.0.11.0/24"]
}

variable "availability_zones" {
  description = "Availability zones to use"
  type        = list(string)
  default     = ["ap-south-1a", "ap-south-1b"]
}

variable "enable_nat_gateway" {
  description = "Enable NAT Gateway for outbound internet (needed for OpenAI/LLM APIs, GitHub ArgoCD sync, DockerHub)"
  type        = bool
  default     = true
}

variable "single_nat_gateway" {
  description = "Use a single NAT Gateway to minimize cost (~$0.045/hr) in dev"
  type        = bool
  default     = true
}

variable "enable_vpc_endpoints" {
  description = "Enable interface VPC endpoints. Set false when NAT Gateway is active to prevent redundant cost"
  type        = bool
  default     = false
}

# ─── EKS ──────────────────────────────────────────────────────────────────────
variable "kubernetes_version" {
  description = "Kubernetes version for EKS cluster (Standard Support until Aug 2027)"
  type        = string
  default     = "1.36"
}

variable "cluster_public_access_cidrs" {
  description = "List of CIDR blocks permitted to access the EKS cluster public API server. Set in dev.auto.tfvars to your public IP/32. Empty default forces explicit configuration."
  type        = list(string)
  default     = []
}

variable "node_instance_type" {
  description = "EC2 instance type for EKS worker nodes"
  type        = string
  default     = "t3.medium"
}


variable "node_desired_count" {
  description = "Desired number of worker nodes"
  type        = number
  default     = 2
}

variable "node_min_count" {
  description = "Minimum number of worker nodes"
  type        = number
  default     = 1
}

variable "node_max_count" {
  description = "Maximum number of worker nodes"
  type        = number
  default     = 3
}

# ─── ECR ──────────────────────────────────────────────────────────────────────
variable "ecr_image_retention_count" {
  description = "Number of images to retain per ECR repository"
  type        = number
  default     = 5
}
