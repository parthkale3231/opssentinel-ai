# ─── VPC Module ───────────────────────────────────────────────────────────────
module "vpc" {
  source = "../../modules/vpc"

  project_name         = var.project_name
  environment          = var.environment
  vpc_cidr             = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  availability_zones   = var.availability_zones
  enable_nat_gateway   = var.enable_nat_gateway
  single_nat_gateway   = var.single_nat_gateway
  enable_vpc_endpoints = var.enable_vpc_endpoints
}

# ─── Cluster & Node IAM Module ───────────────────────────────────────────────
module "iam" {
  source = "../../modules/iam"

  project_name = var.project_name
  environment  = var.environment
}

# ─── ECR Module ───────────────────────────────────────────────────────────────
module "ecr" {
  source = "../../modules/ecr"

  project_name          = var.project_name
  environment           = var.environment
  image_retention_count = var.ecr_image_retention_count
}

# ─── EKS Module ───────────────────────────────────────────────────────────────
# depends_on ensures IAM policy attachments complete before EKS cluster creation.
# Safe because the cycle-causing IRSA is in a separate module (not iam).
module "eks" {
  source = "../../modules/eks"

  project_name       = var.project_name
  environment        = var.environment
  kubernetes_version = var.kubernetes_version

  vpc_id                      = module.vpc.vpc_id
  private_subnet_ids          = module.vpc.private_subnet_ids
  public_subnet_ids           = module.vpc.public_subnet_ids
  cluster_security_group_id   = module.vpc.eks_cluster_sg_id
  cluster_public_access_cidrs = var.cluster_public_access_cidrs

  cluster_role_arn = module.iam.eks_cluster_role_arn
  node_role_arn    = module.iam.eks_node_role_arn

  node_instance_type = var.node_instance_type
  node_desired_count = var.node_desired_count
  node_min_count     = var.node_min_count
  node_max_count     = var.node_max_count

  depends_on = [module.iam]
}


# ─── Workload IRSA Module ────────────────────────────────────────────────────
# Pure downstream dependency on module.eks OIDC outputs.
# Natural DAG flow: vpc/iam -> eks -> irsa.
module "irsa" {
  source = "../../modules/irsa"

  project_name      = var.project_name
  environment       = var.environment
  oidc_provider_arn = module.eks.oidc_provider_arn
  oidc_provider_url = module.eks.oidc_provider_url
}

