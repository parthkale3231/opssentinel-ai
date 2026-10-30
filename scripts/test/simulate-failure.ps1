#!/usr/bin/env pwsh
# scripts/test/simulate-failure.ps1
# Inject controlled failures for incident testing

param(
    [Parameter(Mandatory)]
    [ValidateSet("pod-crash", "high-cpu", "high-memory", "app-error", "scale-down")]
    [string]$Scenario,

    [string]$Namespace = "demo-app",
    [string]$Deployment = "demostore-backend"
)

Write-Host ""
Write-Host "=============================================" -ForegroundColor Yellow
Write-Host "  OpsSentinel AI — Failure Simulation" -ForegroundColor Yellow
Write-Host "  Scenario : $Scenario" -ForegroundColor Yellow
Write-Host "  Namespace: $Namespace" -ForegroundColor Yellow
Write-Host "  Workload : $Deployment" -ForegroundColor Yellow
Write-Host "=============================================" -ForegroundColor Yellow
Write-Host ""

switch ($Scenario) {
    "pod-crash" {
        Write-Host "Injecting bad environment variable to cause CrashLoopBackOff..." -ForegroundColor Red
        kubectl set env deployment/$Deployment -n $Namespace DATABASE_URL="invalid://crash"
    }
    "high-cpu" {
        Write-Host "Deploying CPU stress pod..." -ForegroundColor Red
        kubectl apply -f tests/chaos/cpu-stress.yaml -n $Namespace
    }
    "high-memory" {
        Write-Host "Deploying memory stress pod..." -ForegroundColor Red
        kubectl apply -f tests/chaos/memory-stress.yaml -n $Namespace
    }
    "app-error" {
        Write-Host "Injecting 5xx error mode..." -ForegroundColor Red
        kubectl set env deployment/$Deployment -n $Namespace FORCE_ERROR_RATE="0.8"
    }
    "scale-down" {
        Write-Host "Scaling deployment to 0 replicas..." -ForegroundColor Red
        kubectl scale deployment/$Deployment -n $Namespace --replicas=0
    }
}

Write-Host ""
Write-Host "Failure injected. Monitor OpsSentinel dashboard and Grafana for incident detection." -ForegroundColor Cyan
Write-Host "Run this script again with a restore scenario to recover." -ForegroundColor Cyan

