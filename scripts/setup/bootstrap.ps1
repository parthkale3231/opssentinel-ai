#!/usr/bin/env pwsh
# scripts/setup/bootstrap.ps1
# Verify all required development tools for OpsSentinel AI

$tools = @(
    @{ Name = "Git";        Command = "git";       Args = "--version" },
    @{ Name = "Docker";     Command = "docker";    Args = "--version" },
    @{ Name = "kubectl";    Command = "kubectl";   Args = "version --client --short" },
    @{ Name = "kind";       Command = "kind";      Args = "version" },
    @{ Name = "Helm";       Command = "helm";      Args = "version --short" },
    @{ Name = "Terraform";  Command = "terraform"; Args = "version" },
    @{ Name = "AWS CLI";    Command = "aws";       Args = "--version" },
    @{ Name = "Python";     Command = "python";    Args = "--version" },
    @{ Name = "Node.js";    Command = "node";      Args = "--version" },
    @{ Name = "npm";        Command = "npm";       Args = "--version" },
    @{ Name = "Trivy";      Command = "trivy";     Args = "--version" },
    @{ Name = "Checkov";    Command = "checkov";   Args = "--version" }
)

$allPassed = $true

Write-Host ""
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host "  OpsSentinel AI — Bootstrap Check" -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host ""

foreach ($tool in $tools) {
    try {
        $output = & $tool.Command $tool.Args.Split(" ") 2>&1 | Select-Object -First 1
        Write-Host "  [OK]  $($tool.Name.PadRight(12)) $output" -ForegroundColor Green
    } catch {
        Write-Host "  [MISSING] $($tool.Name)" -ForegroundColor Red
        $allPassed = $false
    }
}

Write-Host ""

if ($allPassed) {
    Write-Host "All tools are available. You're ready to start development!" -ForegroundColor Green
} else {
    Write-Host "Some tools are missing. Please install them before proceeding." -ForegroundColor Red
    Write-Host "See docs/setup.md for installation instructions." -ForegroundColor Yellow
    exit 1
}

# Check Docker is running
try {
    docker info | Out-Null
    Write-Host "  [OK]  Docker daemon is running" -ForegroundColor Green
} catch {
    Write-Host "  [WARN] Docker daemon is not running. Start Docker Desktop." -ForegroundColor Yellow
}

# Check kind cluster
$clusters = kind get clusters 2>&1
if ($clusters -match "opssentinel") {
    Write-Host "  [OK]  kind cluster 'opssentinel' exists" -ForegroundColor Green
} else {
    Write-Host "  [INFO] No kind cluster found. Run: make cluster-up" -ForegroundColor Yellow
}

Write-Host ""

