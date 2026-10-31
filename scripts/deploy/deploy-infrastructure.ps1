#!/usr/bin/env pwsh
# scripts/deploy/deploy-infrastructure.ps1
# Deploy AWS infrastructure for OpsSentinel AI

param(
    [ValidateSet("dev", "showcase")]
    [string]$Environment = "dev",
    [switch]$PlanOnly,
    [switch]$AutoApprove
)

$TF_DIR = "infrastructure\terraform\environments\$Environment"

Write-Host ""
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host "  OpsSentinel AI — Infrastructure Deploy" -ForegroundColor Cyan
Write-Host "  Environment: $Environment" -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host ""

# Verify AWS identity
Write-Host "Step 1: Verifying AWS identity..." -ForegroundColor Yellow
$identity = aws sts get-caller-identity --output json | ConvertFrom-Json
Write-Host "  Account : $($identity.Account)" -ForegroundColor Green
Write-Host "  UserID  : $($identity.UserId)" -ForegroundColor Green
Write-Host "  ARN     : $($identity.Arn)" -ForegroundColor Green
Write-Host ""

# Check for budget confirmation
Write-Host "Step 2: AWS Cost Reminder" -ForegroundColor Yellow
Write-Host "  EKS control plane:  ~`$0.10/hr" -ForegroundColor Yellow
Write-Host "  t3.medium x2 nodes: ~`$0.14/hr" -ForegroundColor Yellow
Write-Host "  NAT Gateway:        ~`$0.045/hr + data processing" -ForegroundColor Yellow
Write-Host "  Estimated 4hr cost: ~`$1.20 (excludes EBS, data transfer, CloudWatch)" -ForegroundColor Yellow
Write-Host ""

if (-not $AutoApprove -and -not $PlanOnly) {
    $confirm = Read-Host "Continue? (y/N)"
    if ($confirm -ne "y") { exit 0 }
}

Set-Location $TF_DIR

Write-Host "Step 3: terraform init..." -ForegroundColor Cyan
terraform init
if ($LASTEXITCODE -ne 0) {
    Write-Host "Terraform init failed. Aborting." -ForegroundColor Red
    exit 1
}

Write-Host "Step 4: terraform validate..." -ForegroundColor Cyan
terraform validate
if ($LASTEXITCODE -ne 0) {
    Write-Host "Terraform validation failed. Aborting." -ForegroundColor Red
    exit 1
}

Write-Host "Step 5: terraform plan..." -ForegroundColor Cyan
terraform plan -out=tfplan
if ($LASTEXITCODE -ne 0) {
    Write-Host "Terraform plan failed. Aborting." -ForegroundColor Red
    exit 1
}

if ($PlanOnly) {
    Write-Host "Plan complete. Review above before applying." -ForegroundColor Green
    exit 0
}

Write-Host "Step 6: terraform apply..." -ForegroundColor Cyan
if ($AutoApprove) {
    terraform apply tfplan
} else {
    $applyConfirm = Read-Host "Apply this plan? (y/N)"
    if ($applyConfirm -eq "y") {
        terraform apply tfplan
    } else {
        Write-Host "Apply cancelled." -ForegroundColor Yellow
        exit 0
    }
}
if ($LASTEXITCODE -ne 0) {
    Write-Host "Terraform apply failed. Check AWS console and state." -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Step 7: Fetching outputs..." -ForegroundColor Cyan
terraform output

Write-Host ""
Write-Host "Step 8: Configuring kubectl..." -ForegroundColor Cyan
$clusterName = terraform output -raw eks_cluster_name
aws eks update-kubeconfig --region ap-south-1 --name $clusterName
if ($LASTEXITCODE -ne 0) {
    Write-Host "Failed to update kubeconfig for cluster $clusterName." -ForegroundColor Red
    exit 1
}
kubectl get nodes
if ($LASTEXITCODE -ne 0) {
    Write-Host "Failed to connect to cluster nodes with kubectl." -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Infrastructure deployed successfully!" -ForegroundColor Green
Write-Host "Remember to run destroy.ps1 when finished to avoid unnecessary charges." -ForegroundColor Yellow

