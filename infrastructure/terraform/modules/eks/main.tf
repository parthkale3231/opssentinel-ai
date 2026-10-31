locals {
  name_prefix  = "${var.project_name}-${var.environment}"
  cluster_name = "${local.name_prefix}-eks"
}

# ─── EKS Cluster ──────────────────────────────────────────────────────────────
resource "aws_eks_cluster" "main" {
  name     = local.cluster_name
  version  = var.kubernetes_version
  role_arn = var.cluster_role_arn

  vpc_config {
    subnet_ids              = concat(var.private_subnet_ids, var.public_subnet_ids)
    endpoint_private_access = true
    endpoint_public_access  = length(var.cluster_public_access_cidrs) > 0
    public_access_cidrs     = length(var.cluster_public_access_cidrs) > 0 ? var.cluster_public_access_cidrs : null
    security_group_ids      = var.cluster_security_group_id != "" ? [var.cluster_security_group_id] : null
  }

  access_config {
    authentication_mode                         = "API_AND_CONFIG_MAP"
    bootstrap_cluster_creator_admin_permissions = false
  }

  # Enable control-plane logs; CloudWatch ingestion and storage charges may apply.
  enabled_cluster_log_types = [
    "api",
    "audit",
    "authenticator",
  ]

  tags = {
    Name = local.cluster_name
  }
}

# ─── OIDC Provider for IRSA ───────────────────────────────────────────────────
# IRSA (IAM Roles for Service Accounts) requires an OIDC provider linked to
# the EKS cluster's OIDC issuer URL. Without this, service accounts cannot
# assume IAM roles via web identity federation.

data "tls_certificate" "eks_oidc" {
  url = aws_eks_cluster.main.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "eks" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks_oidc.certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.main.identity[0].oidc[0].issuer

  tags = {
    Name = "${local.cluster_name}-oidc-provider"
  }
}

# ─── EKS Managed Node Group ───────────────────────────────────────────────────
resource "aws_eks_node_group" "main" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "${local.name_prefix}-ng"
  node_role_arn   = var.node_role_arn
  subnet_ids      = var.private_subnet_ids

  # AL2 reached EOS in Nov 2025; using AL2023 standard EKS-optimized AMI
  ami_type       = "AL2023_x86_64_STANDARD"
  instance_types = [var.node_instance_type]
  capacity_type  = "ON_DEMAND"
  disk_size      = 20

  scaling_config {
    desired_size = var.node_desired_count
    min_size     = var.node_min_count
    max_size     = var.node_max_count
  }

  update_config {
    max_unavailable = 1
  }

  labels = {
    role        = "worker"
    environment = var.environment
  }

  tags = {
    Name = "${local.name_prefix}-node-group"
  }

  # Prevent Terraform from resetting externally autoscaled desired_size
  lifecycle {
    ignore_changes = [scaling_config[0].desired_size]
  }
}

# ─── EKS Access Entry (for the deploying IAM principal) ───────────────────────
data "aws_caller_identity" "current" {}

resource "aws_eks_access_entry" "deployer" {
  cluster_name  = aws_eks_cluster.main.name
  principal_arn = data.aws_caller_identity.current.arn
  type          = "STANDARD"

  tags = {
    Name = "${local.name_prefix}-deployer-access"
  }
}

resource "aws_eks_access_policy_association" "deployer_admin" {
  cluster_name  = aws_eks_cluster.main.name
  principal_arn = data.aws_caller_identity.current.arn
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

  access_scope {
    type = "cluster"
  }
}

