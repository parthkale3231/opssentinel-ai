#!/usr/bin/env pwsh
# scripts/cleanup/destroy.ps1
# Safely destroy AWS infrastructure and clean up resources

param(
    [ValidateSet("dev", "showcase")]
    [string]$Environment = "dev",
    [switch]$Force
)

$TF_DIR = "infrastructure\terraform\environments\$Environment"

Write-Host ""
Write-Host "=============================================" -ForegroundColor Red
Write-Host "  OpsSentinel AI — Infrastructure Cleanup" -ForegroundColor Red
Write-Host "  Environment: $Environment" -ForegroundColor Red
Write-Host "=============================================" -ForegroundColor Red
Write-Host ""
Write-Host "WARNING: This will destroy all AWS infrastructure in the $Environment environment." -ForegroundColor Yellow
Write-Host ""

if (-not $Force) {
    $confirm = Read-Host "Type 'DESTROY' to confirm"
    if ($confirm -ne "DESTROY") {
        Write-Host "Cancelled." -ForegroundColor Green
        exit 0
    }
}

if (-not (Test-Path $TF_DIR)) {
    Write-Host "Directory $TF_DIR not found. Aborting." -ForegroundColor Red
    exit 1
}

Write-Host "Step 1: Reviewing Terraform state..." -ForegroundColor Cyan
Set-Location $TF_DIR
terraform state list

Write-Host ""
Write-Host "Step 2: Running terraform destroy..." -ForegroundColor Cyan
terraform destroy -auto-approve
if ($LASTEXITCODE -ne 0) {
    Write-Host "Terraform destroy failed. Check resources in AWS console." -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Step 3: Verifying cleanup..." -ForegroundColor Cyan
Write-Host "  Check AWS Console for any remaining resources:" -ForegroundColor Yellow
Write-Host "    - EKS clusters" -ForegroundColor Yellow
Write-Host "    - EC2 instances and node groups" -ForegroundColor Yellow
Write-Host "    - Load balancers" -ForegroundColor Yellow
Write-Host "    - VPC and networking" -ForegroundColor Yellow
Write-Host "    - ECR images (retain or clean)" -ForegroundColor Yellow
Write-Host "    - S3 Terraform state (retain)" -ForegroundColor Yellow
Write-Host ""
Write-Host "Infrastructure destroyed successfully." -ForegroundColor Green
Write-Host "Review AWS Billing to confirm no unexpected charges." -ForegroundColor Green
