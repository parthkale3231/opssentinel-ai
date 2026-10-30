# AWS Deployment Guide

> **Target Region:** ap-south-1 (Mumbai)
> **Strategy:** Provision only for final validation and demonstration. Use `kind` for daily development.

## Prerequisites

- AWS account with IAM deployment permissions
- AWS CLI v2 configured (`aws configure`)
- Terraform 1.7+
- kubectl
- Docker Desktop
- ECR repositories created via Terraform

## Step 1 — Configure AWS Credentials

```powershell
aws configure
aws sts get-caller-identity  # Verify identity
```

## Step 2 — Create Terraform Backend

```powershell
# Create S3 bucket for state (one-time)
aws s3api create-bucket `
  --bucket opssentinel-terraform-state `
  --region ap-south-1 `
  --create-bucket-configuration LocationConstraint=ap-south-1

aws s3api put-bucket-versioning `
  --bucket opssentinel-terraform-state `
  --versioning-configuration Status=Enabled

aws s3api put-bucket-encryption `
  --bucket opssentinel-terraform-state `
  --server-side-encryption-configuration '{
    "Rules": [{"ApplyServerSideEncryptionByDefault": {"SSEAlgorithm": "AES256"}}]
  }'
```

## Step 3 — Provision Infrastructure

```powershell
cd infrastructure/terraform/environments/dev

terraform init
terraform validate
terraform plan -out=tfplan
# Review the plan carefully before applying
terraform apply tfplan
```

## Step 4 — Configure kubectl

```powershell
aws eks update-kubeconfig --region ap-south-1 --name opssentinel-dev
kubectl get nodes  # Verify connectivity
```

## Step 5 — Build and Push Images

```powershell
# Authenticate with ECR
aws ecr get-login-password --region ap-south-1 | docker login --username AWS --password-stdin <ACCOUNT_ID>.dkr.ecr.ap-south-1.amazonaws.com

# Build and push DemoStore
docker build -t demostore:latest applications/demostore/backend/
docker tag demostore:latest <ACCOUNT_ID>.dkr.ecr.ap-south-1.amazonaws.com/demostore:latest
docker push <ACCOUNT_ID>.dkr.ecr.ap-south-1.amazonaws.com/demostore:latest

# Build and push OpsSentinel
docker build -t opssentinel:latest applications/opssentinel/backend/
docker tag opssentinel:latest <ACCOUNT_ID>.dkr.ecr.ap-south-1.amazonaws.com/opssentinel:latest
docker push <ACCOUNT_ID>.dkr.ecr.ap-south-1.amazonaws.com/opssentinel:latest
```

## Step 6 — Deploy with ArgoCD

```powershell
# Install ArgoCD
helm repo add argo https://argoproj.github.io/argo-helm
helm install argocd argo/argo-cd -n argocd --create-namespace

# Apply application definitions
kubectl apply -f gitops/applications/ -n argocd

# Watch sync status
kubectl get applications -n argocd
```

## Step 7 — Verify Deployment

```powershell
kubectl get nodes
kubectl get namespaces
kubectl get deployments -A
kubectl get pods -A
kubectl get services -A
```

## Infrastructure Cleanup

> [!CAUTION]
> Always verify before destroying. Check for any persistent data that needs to be backed up.

```powershell
.\scripts\cleanup\destroy.ps1 -Environment dev
```

