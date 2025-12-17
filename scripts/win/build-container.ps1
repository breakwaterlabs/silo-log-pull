#Requires -Version 5.1

<#
.SYNOPSIS
    Build local container image

.DESCRIPTION
    Builds the silo-log-pull container image locally using Docker
#>

$repoBase = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)

# Check if Docker is installed
$dockerCmd = Get-Command docker -ErrorAction SilentlyContinue
if (-not $dockerCmd) {
    Write-Host "Error: Docker is not installed or not in PATH" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please install Docker Desktop or Rancher Desktop first:"
    Write-Host "  Docker Desktop: https://www.docker.com/products/docker-desktop"
    Write-Host "  Rancher Desktop: https://rancherdesktop.io/"
    exit 1
}

Write-Host "Using Docker: $($dockerCmd.Source)" -ForegroundColor Green
Write-Host ""
Write-Host "Building container image 'silo-log-pull'..." -ForegroundColor Green
Write-Host ""

Push-Location $repoBase
try {
    docker build -t silo-log-pull .

    Write-Host ""
    Write-Host "============================================" -ForegroundColor Green
    Write-Host "Build complete!" -ForegroundColor Green
    Write-Host "============================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "To run the container:"
    Write-Host "  cd $repoBase\app"
    Write-Host "  docker run --rm -v `${PWD}/data:/data silo-log-pull"
} finally {
    Pop-Location
}
