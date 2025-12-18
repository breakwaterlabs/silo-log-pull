#Requires -Version 5.1

<#
.SYNOPSIS
    Offline Container Package Extraction Script

.DESCRIPTION
    Loads container image and configures data directory

.PARAMETER Load
    Load container image only

.PARAMETER Run
    Run container only (assumes already loaded)

.PARAMETER NoConfigure
    Skip data directory configuration
#>

[CmdletBinding()]
param(
    [switch]$Load,
    [switch]$Run,
    [switch]$NoConfigure
)

# Default: load only if no flags specified
if (-not $Load -and -not $Run) {
    $Load = $true
}

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoDir = Split-Path -Parent (Split-Path -Parent $scriptDir)
$appDir = Join-Path $repoDir "app"

# Check for Docker
$dockerCmd = Get-Command docker -ErrorAction SilentlyContinue
if (-not $dockerCmd) {
    Write-Host "Error: Docker is not installed or not in PATH" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please install Docker Desktop or Rancher Desktop first:"
    Write-Host "  Docker Desktop: https://www.docker.com/products/docker-desktop"
    Write-Host "  Rancher Desktop: https://rancherdesktop.io/"
    exit 1
}

if ($Load) {
    Write-Host "=========================================" -ForegroundColor Cyan
    Write-Host "  silo-log-pull Offline Setup" -ForegroundColor Cyan
    Write-Host "=========================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Found Docker: $($dockerCmd.Source)" -ForegroundColor Green

    $tarFile = Join-Path $repoDir "silo-log-pull.tar"

    if (-not (Test-Path $tarFile)) {
        Write-Host "Error: Container image file not found: $tarFile" -ForegroundColor Red
        exit 1
    }

    Write-Host ""
    Write-Host "Loading container image..." -ForegroundColor Green
    Write-Host "This may take a few minutes..." -ForegroundColor Gray
    Write-Host ""

    docker load -i $tarFile
    if ($LASTEXITCODE -ne 0) {
        & "$scriptDir\scripts\win\show-error-container.ps1" -ErrorType load
        exit 1
    }

    Write-Host ""
    Write-Host "============================================" -ForegroundColor Green
    Write-Host "Container image loaded successfully!" -ForegroundColor Green
    Write-Host "============================================" -ForegroundColor Green
    Write-Host ""

    # Configure data directory
    if (-not $NoConfigure) {
        Write-Host "Data Directory Configuration" -ForegroundColor Cyan
        Write-Host "----------------------------" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "Where would you like to store configuration files and logs?"
        Write-Host ""
        Write-Host "  [1] Default location ($appDir\data\)"
        Write-Host "  [2] Custom location"
        Write-Host ""
        Write-Host -NoNewline "Choice [1-2]: "
        $choice = Read-Host

        switch ($choice) {
            "2" {
                Write-Host ""
                Write-Host -NoNewline "Enter full path for data directory: "
                $customPath = Read-Host

                # Expand environment variables
                $customPath = [System.Environment]::ExpandEnvironmentVariables($customPath)

                # Validate or create directory
                if (-not (Test-Path $customPath)) {
                    Write-Host ""
                    Write-Host "Directory does not exist: $customPath" -ForegroundColor Yellow
                    Write-Host -NoNewline "Create it now? [Y/n]: "
                    $create = Read-Host
                    if ($create -eq "" -or $create -eq "Y" -or $create -eq "y") {
                        New-Item -ItemType Directory -Path $customPath -Force | Out-Null
                        Write-Host "Created: $customPath" -ForegroundColor Green
                    } else {
                        Write-Host "Cannot continue without data directory" -ForegroundColor Red
                        exit 1
                    }
                }

                # Create subdirectories
                New-Item -ItemType Directory -Path (Join-Path $customPath "logs") -Force | Out-Null
                New-Item -ItemType Directory -Path (Join-Path $customPath "logs_out") -Force | Out-Null

                # Write data_dir.txt
                $dataDirFile = Join-Path $appDir "data_dir.txt"
                Set-Content -Path $dataDirFile -Value $customPath -NoNewline
                Write-Host ""
                Write-Host "Data directory configured: $customPath" -ForegroundColor Green
                Write-Host "(Saved to $dataDirFile)" -ForegroundColor Gray
            }
            default {
                Write-Host ""
                Write-Host "Using default data directory: $appDir\data\" -ForegroundColor Green
            }
        }
        Write-Host ""
    }
}

if ($Run) {
    # Verify image is loaded
    try {
        docker image inspect silo-log-pull 2>&1 | Out-Null
        if ($LASTEXITCODE -ne 0) {
            throw "Image not found"
        }
    } catch {
        Write-Host "Error: Container image not loaded" -ForegroundColor Red
        Write-Host "Please run with -Load first"
        exit 1
    }

    # Resolve data directory
    $dataMountPath = Join-Path $appDir "data"
    $dataDirFile = Join-Path $appDir "data_dir.txt"
    if (Test-Path $dataDirFile) {
        $dataMountPath = Get-Content $dataDirFile -Raw
    }

    Write-Host "Running silo-log-pull..." -ForegroundColor Cyan
    Write-Host "Data directory: $dataMountPath" -ForegroundColor Gray
    Write-Host ""

    # Run container with full path (convert to Linux-style path for volume mount)
    $volumeMount = "${dataMountPath}:/data"
    docker run --rm -v $volumeMount silo-log-pull

    if ($LASTEXITCODE -ne 0) {
        & "$scriptDir\scripts\win\show-error-container.ps1" -ErrorType run
        exit 1
    }
} else {
    # Resolve data directory for display
    $dataMountPath = Join-Path $appDir "data"
    $dataDirFile = Join-Path $appDir "data_dir.txt"
    if (Test-Path $dataDirFile) {
        $dataMountPath = Get-Content $dataDirFile -Raw
    }

    Write-Host "To run silo-log-pull:"
    Write-Host "  docker run --rm -v `"${dataMountPath}:/data`" silo-log-pull"
    Write-Host ""
    Write-Host "Or use: $scriptDir\$(Split-Path -Leaf $MyInvocation.MyCommand.Path) -Run"
    Write-Host ""
    Write-Host "See the docs\ directory for complete documentation."
}
