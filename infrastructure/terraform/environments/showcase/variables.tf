variable "aws_region" {
  type    = string
  default = "ap-south-1"
}

variable "environment" {
  type    = string
  default = "showcase"
}

variable "project_name" {
  type    = string
  default = "opssentinel"
}

variable "vpc_cidr" {
  type    = string
  default = "10.1.0.0/16"
}

variable "public_subnet_cidrs" {
  type    = list(string)
  default = ["10.1.1.0/24", "10.1.2.0/24"]
}

variable "private_subnet_cidrs" {
  type    = list(string)
  default = ["10.1.10.0/24", "10.1.11.0/24"]
}

variable "availability_zones" {
  type    = list(string)
  default = ["ap-south-1a", "ap-south-1b"]
}

variable "enable_nat_gateway" {
  type    = bool
  default = true
}

variable "single_nat_gateway" {
  type    = bool
  default = true
}

variable "enable_vpc_endpoints" {
  type    = bool
  default = false
}

variable "kubernetes_version" {
  type    = string
  default = "1.36"
}

variable "cluster_public_access_cidrs" {
  description = "List of CIDR blocks permitted to access the EKS cluster public API server. Set in showcase.auto.tfvars to your public IP/32. Empty default forces explicit configuration."
  type        = list(string)
  default     = []
}

variable "node_instance_type" {
  type    = string
  default = "t3.medium"
}


variable "node_desired_count" {
  type    = number
  default = 2
}

variable "node_min_count" {
  type    = number
  default = 2
}

variable "node_max_count" {
  type    = number
  default = 4
}

variable "ecr_image_retention_count" {
  type    = number
  default = 10
}
