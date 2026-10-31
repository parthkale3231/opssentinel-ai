#!/usr/bin/env pwsh
# scripts/setup/create-tf-backend.ps1
# Create and configure the S3 bucket for Terraform remote state.
# Run this ONCE before any `terraform init`. The bucket must not already exist.
#
# Requirements: AWS CLI configured, IAM permissions for S3.

param(
    [string]$BucketName = "opssentinel-terraform-state",
    [string]$Region     = "ap-south-1"
)

function Check-LastExitCode {
    param([string]$StepName)
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Error in $StepName. Command failed with exit code $LASTEXITCODE. Aborting." -ForegroundColor Red
        exit $LASTEXITCODE
    }
}

Write-Host ""
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host "  OpsSentinel AI — Terraform Backend Setup" -ForegroundColor Cyan
Write-Host "  Bucket: $BucketName" -ForegroundColor Cyan
Write-Host "  Region: $Region" -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host ""

# 1. Verify AWS identity
Write-Host "Step 1: Verifying AWS identity..." -ForegroundColor Yellow
$identityJson = aws sts get-caller-identity --output json
Check-LastExitCode "Step 1: Verifying AWS identity"
$identity = $identityJson | ConvertFrom-Json
Write-Host "  Account : $($identity.Account)" -ForegroundColor Green
Write-Host "  ARN     : $($identity.Arn)" -ForegroundColor Green
Write-Host ""

# 2. Create S3 bucket
Write-Host "Step 2: Creating S3 bucket..." -ForegroundColor Yellow
$createArgs = @(
    "s3api", "create-bucket",
    "--bucket", $BucketName,
    "--region", $Region,
    "--create-bucket-configuration", "LocationConstraint=$Region"
)
aws @createArgs | Out-Null
Check-LastExitCode "Step 2: Creating S3 bucket"
Write-Host "  Bucket created: $BucketName" -ForegroundColor Green

# 3. Block all public access — CRITICAL
Write-Host "Step 3: Blocking all public access..." -ForegroundColor Yellow
aws s3api put-public-access-block `
    --bucket $BucketName `
    --public-access-block-configuration "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"
Check-LastExitCode "Step 3: Blocking all public access"
Write-Host "  Public access blocked." -ForegroundColor Green

# 4. Enable versioning (required for state recovery)
Write-Host "Step 4: Enabling versioning..." -ForegroundColor Yellow
aws s3api put-bucket-versioning `
    --bucket $BucketName `
    --versioning-configuration Status=Enabled
Check-LastExitCode "Step 4: Enabling versioning"
Write-Host "  Versioning enabled." -ForegroundColor Green

# 5. Enable AES-256 server-side encryption
Write-Host "Step 5: Enabling server-side encryption (AES-256)..." -ForegroundColor Yellow
$encryptionConfig = @'
{
  "Rules": [{
    "ApplyServerSideEncryptionByDefault": {
      "SSEAlgorithm": "AES256"
    }
  }]
}
'@
aws s3api put-bucket-encryption `
    --bucket $BucketName `
    --server-side-encryption-configuration $encryptionConfig
Check-LastExitCode "Step 5: Enabling server-side encryption"
Write-Host "  Encryption enabled." -ForegroundColor Green

# 6. Enforce encryption in transit (deny HTTP)
Write-Host "Step 6: Enforcing HTTPS-only access..." -ForegroundColor Yellow
$policy = @"
{
  "Version": "2012-10-17",
  "Statement": [{
    "Sid": "DenyNonTLS",
    "Effect": "Deny",
    "Principal": "*",
    "Action": "s3:*",
    "Resource": [
      "arn:aws:s3:::$BucketName",
      "arn:aws:s3:::$BucketName/*"
    ],
    "Condition": {
      "Bool": { "aws:SecureTransport": "false" }
    }
  }]
}
"@
aws s3api put-bucket-policy --bucket $BucketName --policy $policy
Check-LastExitCode "Step 6: Enforcing HTTPS-only access"
Write-Host "  HTTPS-only policy applied." -ForegroundColor Green

# 7. Verify final configuration
Write-Host ""
Write-Host "Step 7: Verifying bucket configuration..." -ForegroundColor Yellow

$versioningJson = aws s3api get-bucket-versioning --bucket $BucketName
Check-LastExitCode "Step 7: Verifying bucket versioning"
$versioning = ($versioningJson | ConvertFrom-Json).Status

$publicBlockJson = aws s3api get-public-access-block --bucket $BucketName
Check-LastExitCode "Step 7: Verifying public access block"
$publicBlock = $publicBlockJson | ConvertFrom-Json

Write-Host "  Versioning      : $versioning" -ForegroundColor Green
Write-Host "  BlockPublicAcls : $($publicBlock.PublicAccessBlockConfiguration.BlockPublicAcls)" -ForegroundColor Green
Write-Host "  BlockPublicPolicy: $($publicBlock.PublicAccessBlockConfiguration.BlockPublicPolicy)" -ForegroundColor Green

Write-Host ""
Write-Host "=============================================" -ForegroundColor Green
Write-Host "  Backend bucket ready!" -ForegroundColor Green
Write-Host "  Now run: cd infrastructure/terraform/environments/dev" -ForegroundColor Green
Write-Host "           terraform init" -ForegroundColor Green
Write-Host "           terraform validate" -ForegroundColor Green
Write-Host "=============================================" -ForegroundColor Green
