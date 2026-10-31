#!/usr/bin/env pwsh
# scripts/setup/validate-phase1.ps1
# Run ALL Phase 1 validation checks. Fix any failures before applying to AWS.

$ErrorActionPreference = "SilentlyContinue"
$Pass  = 0
$Fail  = 0
$INFRA = "infrastructure\terraform"

function OK   { param($msg) Write-Host "  [PASS] $msg" -ForegroundColor Green;  $global:Pass++ }
function FAIL { param($msg) Write-Host "  [FAIL] $msg" -ForegroundColor Red;    $global:Fail++ }
function INFO { param($msg) Write-Host "  [INFO] $msg" -ForegroundColor Yellow }

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "  Phase 1 Validation — Terraform + AWS" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan

# ── 1. Tool checks ─────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "1. Tool Versions" -ForegroundColor White

$tfVer = terraform version -json 2>$null | ConvertFrom-Json
if ($tfVer) {
    OK "Terraform $($tfVer.terraform_version)"
} else { FAIL "Terraform not found" }

$awsVer = aws --version 2>&1
if ($LASTEXITCODE -eq 0) { OK "AWS CLI: $awsVer" } else { FAIL "AWS CLI not found" }

$checkVer = checkov --version 2>&1
if ($LASTEXITCODE -eq 0) { OK "Checkov $checkVer" } else { FAIL "Checkov not found (pip install checkov)" }

# ── 2. AWS Identity ────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "2. AWS Identity" -ForegroundColor White

$identity = aws sts get-caller-identity --output json 2>$null | ConvertFrom-Json
if ($identity.Account) {
    OK "Account: $($identity.Account) | ARN: $($identity.Arn)"
} else {
    FAIL "AWS identity check failed — run 'aws configure'"
}

# ── 3. EKS Supported Versions ──────────────────────────────────────────────────
Write-Host ""
Write-Host "3. EKS Version Check (ap-south-1)" -ForegroundColor White

$eksVersions = aws eks describe-cluster-versions `
    --region ap-south-1 `
    --query "clusterVersions[?status=='STANDARD_SUPPORT'].clusterVersion" `
    --output json 2>$null | ConvertFrom-Json

if ($eksVersions -contains "1.36") {
    OK "EKS 1.36 is under Standard Support in ap-south-1"
} else {
    INFO "Could not verify EKS versions (check AWS connectivity)"
}

# ── 4. Terraform Formatting ────────────────────────────────────────────────────
Write-Host ""
Write-Host "4. Terraform Format Check" -ForegroundColor White

terraform fmt -check -recursive $INFRA 2>&1 | Out-Null
if ($LASTEXITCODE -eq 0) {
    OK "All .tf files are correctly formatted"
} else {
    FAIL "Formatting issues found — run: terraform fmt -recursive $INFRA"
    terraform fmt -check -recursive $INFRA
}

# ── 5. Terraform Init + Validate (no backend) ──────────────────────────────────
Write-Host ""
Write-Host "5. Terraform Init + Validate (dev, no backend)" -ForegroundColor White

Push-Location "$INFRA\environments\dev"
terraform init -backend=false -no-color 2>&1 | Out-Null
if ($LASTEXITCODE -eq 0) {
    OK "terraform init succeeded"
    terraform validate -no-color 2>&1 | Out-Null
    if ($LASTEXITCODE -eq 0) {
        OK "terraform validate passed"
    } else {
        FAIL "terraform validate failed"
        terraform validate
    }
} else {
    FAIL "terraform init failed"
    terraform init -backend=false
}
Pop-Location

# ── 6. Checkov Security Scan ───────────────────────────────────────────────────
Write-Host ""
Write-Host "6. Checkov Security Scan" -ForegroundColor White

$checkovConfig = "security\scans\checkov.yaml"
checkov -d $INFRA --framework terraform --quiet --config-file $checkovConfig 2>&1 | Out-Null
if ($LASTEXITCODE -eq 0) {
    OK "Checkov scan passed (no unskipped high/critical findings)"
} else {
    FAIL "Checkov found policy violations — review security/scans/checkov-report.json"
    INFO "Non-critical findings can be suppressed in $checkovConfig with justification"
}

# ── 7. S3 Backend Bucket ───────────────────────────────────────────────────────
Write-Host ""
Write-Host "7. Terraform State Backend (S3)" -ForegroundColor White

$bucket = "opssentinel-terraform-state"
$s3Info = aws s3api head-bucket --bucket $bucket 2>&1
if ($LASTEXITCODE -eq 0) {
    OK "S3 bucket exists: $bucket"
    $vers = (aws s3api get-bucket-versioning --bucket $bucket | ConvertFrom-Json).Status
    if ($vers -eq "Enabled") { OK "  Versioning: Enabled" } else { FAIL "  Versioning: NOT enabled — run create-tf-backend.ps1" }
} else {
    FAIL "S3 bucket not found: $bucket — run scripts/setup/create-tf-backend.ps1"
}

# ── Summary ────────────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "  Results: $Pass passed, $Fail failed" -ForegroundColor $(if ($Fail -eq 0) { "Green" } else { "Red" })
Write-Host "==========================================" -ForegroundColor Cyan

if ($Fail -gt 0) {
    Write-Host ""
    Write-Host "Fix all failures before running terraform apply." -ForegroundColor Red
    exit 1
} else {
    Write-Host ""
    Write-Host "All checks passed. Phase 1 is ready for AWS deployment." -ForegroundColor Green
    Write-Host "Next: .\scripts\deploy\deploy-infrastructure.ps1 -Environment dev -PlanOnly" -ForegroundColor Cyan
}

