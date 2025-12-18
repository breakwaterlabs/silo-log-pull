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

# Test Docker daemon connectivity
Write-Host "Checking Docker daemon..." -ForegroundColor Cyan
$testResult = docker version 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host ""
    Write-Host "Error: Cannot connect to Docker daemon" -ForegroundColor Red
    Write-Host ""

    $errorOutput = $testResult | Out-String

    if ($errorOutput -match "pipe.*docker_engine.*cannot find") {
        Write-Host "The Docker daemon is not running or the container engine is not started." -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Possible solutions:" -ForegroundColor Cyan
        Write-Host "  1. Start Docker Desktop or Rancher Desktop"
        Write-Host "  2. Wait a few moments for the container engine to fully start"
        Write-Host "  3. Run 'System test' from the setup menu to diagnose the issue"
        Write-Host "  4. Check if you need to select a container engine in your Docker/Rancher settings"
    } elseif ($errorOutput -match "access.*denied|permission") {
        Write-Host "Access denied when connecting to Docker." -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Possible solutions:" -ForegroundColor Cyan
        Write-Host "  1. Run this script as Administrator"
        Write-Host "  2. Ensure your user is in the 'docker-users' group (Docker Desktop)"
        Write-Host "  3. Restart your computer after adding to docker-users group"
        Write-Host "  4. Run 'System test' from the setup menu for detailed diagnostics"
    } else {
        Write-Host "Docker daemon connection error:" -ForegroundColor Yellow
        Write-Host $errorOutput
        Write-Host ""
        Write-Host "Recommended actions:" -ForegroundColor Cyan
        Write-Host "  1. Run 'System test' from the setup menu to diagnose the issue"
        Write-Host "  2. Check if Docker Desktop or Rancher Desktop is running"
        Write-Host "  3. Try restarting your container runtime"
    }

    exit 1
}

Write-Host "✓ Docker daemon is running" -ForegroundColor Green
Write-Host ""
Write-Host "Pulling container image from registry..." -ForegroundColor Green
Write-Host "This may take several minutes..." -ForegroundColor Yellow
Write-Host ""

$pullOutput = docker pull $registryImage 2>&1
$pullExitCode = $LASTEXITCODE

if ($pullExitCode -ne 0) {
    Write-Host ""
    Write-Host "Error: Failed to pull container image" -ForegroundColor Red
    Write-Host ""

    $pullError = $pullOutput | Out-String

    if ($pullError -match "denied|unauthorized|authentication") {
        Write-Host "Registry authentication failed." -ForegroundColor Yellow
        Write-Host ""
        Write-Host "The registry may require authentication or the image may not be publicly accessible."
        Write-Host "Please check with your administrator for access credentials."
    } elseif ($pullError -match "not found|no such|does not exist") {
        Write-Host "Container image not found in registry." -ForegroundColor Yellow
        Write-Host ""
        Write-Host "The image path may be incorrect or the image may not be published yet."
        Write-Host "Registry: $registryImage"
    } elseif ($pullError -match "timeout|network|connection|resolve") {
        Write-Host "Network connection error." -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Cannot reach the registry. Please check your internet connection."
    } else {
        Write-Host "Pull error details:" -ForegroundColor Yellow
        Write-Host $pullError
    }

    Write-Host ""
    Write-Host "Troubleshooting:" -ForegroundColor Cyan
    Write-Host "  1. Check your internet connection"
    Write-Host "  2. Verify registry access: $registryImage"
    Write-Host "  3. Run 'System test' from the setup menu"
    Write-Host "  4. Try building the container locally instead (option 3 in menu)"

    exit 1
}

Write-Host ""
Write-Host "Tagging image as '$localTag'..." -ForegroundColor Green
docker tag $registryImage $localTag

if ($LASTEXITCODE -ne 0) {
    Write-Host ""
    Write-Host "Error: Failed to tag image" -ForegroundColor Red
    Write-Host "The image was pulled but could not be tagged locally."
    Write-Host ""
    Write-Host "You can try tagging it manually:"
    Write-Host "  docker tag $registryImage $localTag"
    exit 1
}

Write-Host ""
Write-Host "============================================" -ForegroundColor Green
Write-Host "Pull complete!" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Green
Write-Host ""
Write-Host "Container image successfully pulled and tagged as '$localTag'"
Write-Host ""
Write-Host "To run the container:"
Write-Host "  cd $repoBase\app"
Write-Host "  docker run --rm -v `${PWD}/data:/data $localTag"
