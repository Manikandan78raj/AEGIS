<#
.SYNOPSIS
    AEGIS Pre-Flight & Context Verification Script
    Ensures safe local sandbox operation and guards against modifying external clusters.
#>

[CmdletBinding()]
param (
    [switch]$RequireCluster = $false
)

$ErrorActionPreference = "Stop"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host " AEGIS Infrastructure Pre-flight Check " -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# 1. Docker Connectivity Check
Write-Host "[1/5] Checking Docker Desktop connectivity..." -NoNewline
try {
    $dockerInfo = docker info --format '{{.ServerVersion}} ({{.OperatingSystem}})' 2>$null
    if (-not $dockerInfo) {
        throw "Docker engine not reachable."
    }
    Write-Host " OK ($dockerInfo)" -ForegroundColor Green
} catch {
    Write-Host " FAILED" -ForegroundColor Red
    Write-Error "Docker engine is not running or not accessible. Please ensure Docker Desktop is started."
}

# 2. Host RAM and Disk Verification
Write-Host "[2/5] Checking host memory and disk space..." -NoNewline
$os = Get-CimInstance Win32_OperatingSystem
$freeRamGB = [math]::Round($os.FreePhysicalMemory / 1MB, 2)
$diskC = Get-PSDrive -Name C -PSProvider FileSystem -ErrorAction SilentlyContinue
$freeCGB = if ($diskC) { [math]::Round($diskC.Free / 1GB, 2) } else { 0 }
$diskX = Get-PSDrive -Name X -PSProvider FileSystem -ErrorAction SilentlyContinue
$freeXGB = if ($diskX) { [math]::Round($diskX.Free / 1GB, 2) } else { 0 }

Write-Host " OK" -ForegroundColor Green
Write-Host "      - Free Host RAM : $freeRamGB GB"
Write-Host "      - Free Disk C:  : $freeCGB GB"
Write-Host "      - Free Disk X:  : $freeXGB GB"

if ($freeRamGB -lt 2.0) {
    Write-Warning "Free host RAM is below 2.0 GB ($freeRamGB GB). Stack performance may degrade."
}
if ($freeCGB -lt 10.0) {
    Write-Warning "Free disk space on C: is below 10.0 GB ($freeCGB GB). Image pulls might fail."
}

# 3. CLI Tooling Checks (kubectl, kind, helm)
Write-Host "[3/5] Checking CLI tools (kubectl, kind, helm)..." -NoNewline
$missing = @()
if (-not (Get-Command kubectl -ErrorAction SilentlyContinue)) { $missing += "kubectl" }
if (-not (Get-Command kind -ErrorAction SilentlyContinue)) { $missing += "kind" }
if (-not (Get-Command helm -ErrorAction SilentlyContinue)) { $missing += "helm" }

if ($missing.Count -gt 0) {
    Write-Host " FAILED" -ForegroundColor Red
    Write-Error "Missing required tools: $($missing -join ', ')"
} else {
    $kubectlVer = kubectl version --client --output=json 2>$null | ConvertFrom-Json
    $kindVer = kind version 2>$null
    Write-Host " OK" -ForegroundColor Green
    Write-Host "      - kubectl : $($kubectlVer.clientVersion.gitVersion)"
    Write-Host "      - kind    : $kindVer"
}

# 4. Context Isolation & VMware Defense Wall
Write-Host "[4/5] Checking active Kubernetes context..." -NoNewline
$currentContext = ""
try {
    $contextOutput = & kubectl config view --minify -o jsonpath='{.current-context}' 2>&1
    if ($LASTEXITCODE -eq 0 -and $contextOutput) {
        $currentContext = $contextOutput.Trim()
    }
} catch {
    $currentContext = ""
}

# Forbidden context names matching external or learning environments
$forbiddenPatterns = @("k8s-master", "k8s-worker", "vmware", "docker-desktop", "default", "minikube")

if ($currentContext) {
    foreach ($pat in $forbiddenPatterns) {
        if ($currentContext -like "*$pat*") {
            Write-Host " BLOCKED" -ForegroundColor Red
            Write-Error "Active context '$currentContext' matches forbidden pattern '$pat'. AEGIS is restricted strictly to 'kind-aegis-local'."
        }
    }

    if ($currentContext -ne "kind-aegis-local") {
        if ($RequireCluster) {
            Write-Host " MISMATCH" -ForegroundColor Red
            Write-Error "Expected active context 'kind-aegis-local', but found '$currentContext'."
        } else {
            Write-Host " NOTICE ($currentContext)" -ForegroundColor Yellow
        }
    } else {
        Write-Host " OK (kind-aegis-local)" -ForegroundColor Green
    }
} else {
    Write-Host " UNSET (Clean)" -ForegroundColor Green
}

# 5. Cluster Presence
Write-Host "[5/5] Checking kind clusters..." -NoNewline
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
    Write-Host " FOUND (aegis-local active)" -ForegroundColor Green
} else {
    Write-Host " NOT FOUND (clean state ready for creation)" -ForegroundColor Green
}

Write-Host "Pre-flight checks completed successfully." -ForegroundColor Green
