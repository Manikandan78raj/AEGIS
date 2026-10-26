<#
.SYNOPSIS
    AEGIS Windows PowerShell task runner.
    Provides identical targets to the Makefile for native Windows environments.

.EXAMPLE
    .\run.ps1 lint
    .\run.ps1 test
    .\run.ps1 clean
    .\run.ps1 help
#>

param (
    [Parameter(Position=0)]
    [string]$Target = "help"
)

$ErrorActionPreference = "Stop"

$VenvPython = Join-Path $PSScriptRoot ".venv\Scripts\python.exe"
$VenvRuff   = Join-Path $PSScriptRoot ".venv\Scripts\ruff.exe"
$VenvPytest = Join-Path $PSScriptRoot ".venv\Scripts\pytest.exe"

function Invoke-RuffCheck {
    if (Test-Path $VenvRuff) {
        & $VenvRuff check .
    } elseif (Get-Command ruff -ErrorAction SilentlyContinue) {
        ruff check .
    } else {
        Write-Error "Ruff not found. Activate .venv or install ruff via: pip install ruff"
    }
}

function Invoke-RuffFormat {
    if (Test-Path $VenvRuff) {
        & $VenvRuff format .
    } elseif (Get-Command ruff -ErrorAction SilentlyContinue) {
        ruff format .
    } else {
        Write-Error "Ruff not found. Activate .venv or install ruff via: pip install ruff"
    }
}

function Invoke-Pytest {
    if (Test-Path $VenvPytest) {
        & $VenvPytest -v tests/
    } elseif (Get-Command pytest -ErrorAction SilentlyContinue) {
        pytest -v tests/
    } else {
        Write-Error "Pytest not found. Activate .venv or install pytest via: pip install pytest"
    }
}

switch ($Target.ToLower()) {
    "lint" {
        Write-Host "--> Running Ruff linter..." -ForegroundColor Cyan
        Invoke-RuffCheck
    }
    "format" {
        Write-Host "--> Formatting code with Ruff..." -ForegroundColor Cyan
        Invoke-RuffFormat
    }
    "test" {
        Write-Host "--> Running test suite with pytest..." -ForegroundColor Cyan
        Invoke-Pytest
    }
    "up" {
        Write-Host "[AEGIS] 'up' is planned for Phase 1 (kind cluster + monitoring stack)." -ForegroundColor Yellow
        Write-Host "Current status: Phase 0 (Repository Foundation)."
    }
    "down" {
        Write-Host "[AEGIS] 'down' is planned for Phase 1 (kind cluster teardown)." -ForegroundColor Yellow
        Write-Host "Current status: Phase 0 (Repository Foundation)."
    }
    "clean" {
        Write-Host "--> Cleaning cache and temporary files..." -ForegroundColor Cyan
        $paths = @(".pytest_cache", ".ruff_cache", "build", "dist", "htmlcov", ".coverage")
        foreach ($p in $paths) {
            $fullPath = Join-Path $PSScriptRoot $p
            if (Test-Path $fullPath) {
                Remove-Item -Recurse -Force $fullPath
                Write-Host "Removed $p"
            }
        }
        Get-ChildItem -Path $PSScriptRoot -Filter "__pycache__" -Recurse -Directory -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force
        Write-Host "Clean complete." -ForegroundColor Green
    }
    default {
        Write-Host "AEGIS PowerShell Task Runner" -ForegroundColor Green
        Write-Host "Usage: .\run.ps1 <target>"
        Write-Host ""
        Write-Host "Available targets:"
        Write-Host "  lint     Run Ruff linter on Python codebase"
        Write-Host "  format   Run Ruff formatter"
        Write-Host "  test     Run pytest test suite"
        Write-Host "  up       Cluster/service startup (Phase 1)"
        Write-Host "  down     Cluster/service teardown (Phase 1)"
        Write-Host "  clean    Remove Python caches and build artifacts"
        Write-Host "  help     Display this help message"
    }
}
