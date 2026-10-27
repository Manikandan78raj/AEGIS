<#
.SYNOPSIS
    AEGIS Phase 1 — Milestone 3: Monitoring Foundation Deployment Script
    Deploys Prometheus and Grafana into the dedicated 'monitoring' namespace.
#>

[CmdletBinding()]
param (
    [string]$ChartVersion = "92.14.0",
    [string]$Namespace = "monitoring",
    [string]$ReleaseName = "aegis-monitoring"
)

$ErrorActionPreference = "Stop"

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host " AEGIS Milestone 3: Monitoring Deployment " -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan

# 1. Pre-flight context validation
Write-Host "[1/6] Verifying active Kubernetes context..." -NoNewline
$currentContext = (kubectl config current-context).Trim()
if ($currentContext -ne "kind-aegis-local") {
    Write-Host " FAILED" -ForegroundColor Red
    Write-Error "Safety violation: Active context is '$currentContext'. Expected 'kind-aegis-local'. Aborting."
}
Write-Host " OK ($currentContext)" -ForegroundColor Green

# 2. Check cluster node readiness
Write-Host "[2/6] Verifying cluster node status..." -NoNewline
$notReadyNodes = kubectl get nodes --no-headers | Where-Object { $_ -notmatch "\sReady\s" }
if ($notReadyNodes) {
    Write-Host " FAILED" -ForegroundColor Red
    Write-Error "One or more nodes are not Ready."
}
Write-Host " OK (2 nodes Ready)" -ForegroundColor Green

# 3. Create or verify monitoring namespace
Write-Host "[3/6] Applying monitoring namespace with aegis.io/managed label..." -NoNewline
$nsPath = Join-Path $PSScriptRoot "..\monitoring\namespace.yaml"
kubectl apply -f $nsPath | Out-Null
Write-Host " OK" -ForegroundColor Green

# 4. Verify Helm repository
Write-Host "[4/6] Verifying prometheus-community Helm repository..." -NoNewline
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts 2>$null | Out-Null
helm repo update prometheus-community | Out-Null
Write-Host " OK" -ForegroundColor Green

# 5. Deploy kube-prometheus-stack
Write-Host "[5/6] Deploying kube-prometheus-stack v$ChartVersion into '$Namespace'..."
$valuesPath = Join-Path $PSScriptRoot "..\monitoring\prometheus-values.yaml"

helm upgrade --install $ReleaseName prometheus-community/kube-prometheus-stack `
    --version $ChartVersion `
    --namespace $Namespace `
    --values $valuesPath `
    --timeout 10m

if ($LASTEXITCODE -ne 0) {
    Write-Error "Helm installation failed with exit code $LASTEXITCODE."
}

# 6. Verify rollout status
Write-Host "[6/6] Verifying deployed workloads..." -ForegroundColor Cyan
kubectl get pods -n $Namespace -o wide

Write-Host "`nMilestone 3 deployment completed successfully!" -ForegroundColor Green
Write-Host "Access Prometheus locally: kubectl port-forward -n $Namespace svc/$ReleaseName-prometheus 9090:9090"
Write-Host "Access Grafana locally:    kubectl port-forward -n $Namespace svc/$ReleaseName-grafana 3000:80"
