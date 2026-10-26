<#
.SYNOPSIS
    AEGIS Sandbox Teardown Script
    Safely tears down only the dedicated 'aegis-local' kind cluster without touching external environments.
#>

[CmdletBinding()]
param (
    [switch]$Force = $false
)

$ErrorActionPreference = "Stop"

Write-Host "Checking for existing aegis-local cluster..." -ForegroundColor Cyan

$existingClusters = @()
try {
    $kindOutput = & kind get clusters 2>&1
    if ($LASTEXITCODE -eq 0 -and $kindOutput) {
        $existingClusters = $kindOutput | Where-Object { $_ -notmatch "No kind clusters found" }
    }
} catch {
    $existingClusters = @()
}

if ($existingClusters -contains "aegis-local") {
    Write-Host "Found 'aegis-local' cluster. Deleting..." -ForegroundColor Yellow
    kind delete cluster --name aegis-local
    Write-Host "Cluster 'aegis-local' deleted successfully." -ForegroundColor Green
} else {
    Write-Host "No 'aegis-local' cluster found. Nothing to tear down." -ForegroundColor Green
}
