#Requires -Version 5.1

<#
.SYNOPSIS
    Pull container image from registry

.DESCRIPTION
    Pulls the silo-log-pull container image from GitLab registry and tags it locally
#>

$repoBase = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$registryImage = "registry.gitlab.com/breakwaterlabs/silo-log-pull:latest"
$localTag = "silo-log-pull"

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
Write-Host "Pulling container image from registry..." -ForegroundColor Green
Write-Host ""

docker pull $registryImage

Write-Host ""
Write-Host "Tagging image as '$localTag'..." -ForegroundColor Green
docker tag $registryImage $localTag

Write-Host ""
Write-Host "============================================" -ForegroundColor Green
Write-Host "Pull complete!" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Green
Write-Host ""
Write-Host "To run the container:"
Write-Host "  cd $repoBase\app"
Write-Host "  docker run --rm -v `${PWD}/data:/data $localTag"
