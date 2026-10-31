variable "project_name" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "public_subnet_cidrs" {
  description = "List of CIDR blocks for public subnets"
  type        = list(string)

  validation {
    condition     = length(var.public_subnet_cidrs) > 0
    error_message = "At least one public subnet CIDR is required."
  }
}

variable "private_subnet_cidrs" {
  description = "List of CIDR blocks for private subnets"
  type        = list(string)

  validation {
    condition     = length(var.private_subnet_cidrs) > 0
    error_message = "At least one private subnet CIDR is required."
  }
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)

  validation {
    condition     = length(var.availability_zones) > 0
    error_message = "At least one availability zone is required."
  }
}

variable "enable_nat_gateway" {
  description = "Provision a NAT Gateway for outbound internet egress (required for GitHub, OpenAI/LLMs, DockerHub, Helm repos)"
  type        = bool
  default     = true
}

variable "single_nat_gateway" {
  description = "Use a single NAT Gateway across all private subnets to minimize costs in dev/showcase (~$0.045/hr vs 8 VPC endpoints at ~$0.11/hr)"
  type        = bool
  default     = true
}

variable "enable_vpc_endpoints" {
  description = "Whether to provision interface VPC Endpoints (ECR, STS, EC2). Keep false when NAT Gateway is active to avoid duplicate hourly charges"
  type        = bool
  default     = false
}


