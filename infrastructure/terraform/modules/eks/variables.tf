variable "project_name" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "kubernetes_version" {
  description = "Kubernetes version"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where EKS is deployed"
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs for worker nodes"
  type        = list(string)
}

variable "public_subnet_ids" {
  description = "Public subnet IDs for load balancers"
  type        = list(string)
}

variable "cluster_role_arn" {
  description = "IAM role ARN for the EKS cluster"
  type        = string
}

variable "node_role_arn" {
  description = "IAM role ARN for the EKS worker nodes"
  type        = string
}

variable "node_instance_type" {
  description = "EC2 instance type for worker nodes"
  type        = string
}

variable "node_desired_count" {
  description = "Desired worker node count"
  type        = number
}

variable "node_min_count" {
  description = "Minimum worker node count"
  type        = number
}

variable "node_max_count" {
  description = "Maximum worker node count"
  type        = number
}

variable "cluster_public_access_cidrs" {
  description = "List of CIDR blocks that can access the Amazon EKS public API server endpoint. Pass empty list to deny all public access."
  type        = list(string)
  default     = []
}

variable "cluster_security_group_id" {
  description = "Additional security group ID to attach to the EKS cluster control plane ENIs"
  type        = string
  default     = ""
}


