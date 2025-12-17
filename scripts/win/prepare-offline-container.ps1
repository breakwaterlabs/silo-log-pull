#Requires -Version 5.1

<#
.SYNOPSIS
    Prepare offline container package

.DESCRIPTION
    Exports the silo-log-pull container image and creates a comprehensive archive for offline systems

.PARAMETER IncludeLogs
    Include existing logs/ and logs_out/ directories in the offline bundle
#>

param(
    [switch]$IncludeLogs
)

$repoBase = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$tempDir = Join-Path $repoBase ".offline-temp-container"
$outputTar = Join-Path $tempDir "silo-log-pull.tar"
$outputZip = Join-Path $repoBase "silo-log-pull-container-offline.zip"
$imageName = "silo-log-pull"

# Check if Docker is installed
$dockerCmd = Get-Command docker -ErrorAction SilentlyContinue
if (-not $dockerCmd) {
    Write-Host "Error: Docker is not installed or not in PATH" -ForegroundColor Red
    exit 1
}

Write-Host "Using Docker: $($dockerCmd.Source)" -ForegroundColor Green
Write-Host ""

# Check if the image exists
try {
    docker image inspect $imageName 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) {
        throw "Image not found"
    }
} catch {
    Write-Host "Error: Container image '$imageName' not found" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please build or pull the image first:"
    Write-Host "  Option 1: Run 'Build local container' from the menu"
    Write-Host "  Option 2: Run 'Pull container from registry' from the menu"
    exit 1
}

# Prompt for log inclusion if not specified
if (-not $PSBoundParameters.ContainsKey('IncludeLogs')) {
    $logDetails = & "$PSScriptRoot\get-log-details.ps1"

    Write-Host ""
    Write-Host "Do you want to include existing logs in the offline bundle?" -ForegroundColor Yellow
    foreach ($logInfo in $logDetails) {
        $displayCount = if ($logInfo.Exists) {
            "Files: $($logInfo.FileCount)"
        } else {
            "(not found)"
        }
        Write-Host "   $($displayCount.PadRight(13)) Path: $($logInfo.Path)"
    }
    Write-Host -NoNewline "Include logs? [y/N]: "
    $response = Read-Host
    $IncludeLogs = ($response -eq 'y' -or $response -eq 'Y')
}

if ($IncludeLogs) {
    Write-Host "Logs will be included in the offline bundle" -ForegroundColor Green
} else {
    Write-Host "Logs will be excluded from the offline bundle" -ForegroundColor Gray
}
Write-Host ""

Write-Host "Creating temporary directory structure..." -ForegroundColor Green
New-Item -ItemType Directory -Force -Path $tempDir | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $tempDir "app\data") | Out-Null

# Copy example configs to app/data if they exist
$exampleConfig = Join-Path $repoBase "app\data\example_silo_config.json"
if (Test-Path $exampleConfig) {
    Copy-Item -Path $exampleConfig -Destination (Join-Path $tempDir "app\data\")
}

# Conditionally copy logs if requested
if ($IncludeLogs) {
    $logsDir = Join-Path $repoBase "app\data\logs"
    $logsOutDir = Join-Path $repoBase "app\data\logs_out"

    if (Test-Path $logsDir) {
        Write-Host "Adding logs directory..." -ForegroundColor Gray
        Copy-Item -Path $logsDir -Destination (Join-Path $tempDir "app\data\logs") -Recurse -Force
    }

    if (Test-Path $logsOutDir) {
        Write-Host "Adding logs_out directory..." -ForegroundColor Gray
        Copy-Item -Path $logsOutDir -Destination (Join-Path $tempDir "app\data\logs_out") -Recurse -Force
    }
}

Write-Host ""
Write-Host "Exporting container image to tar file..." -ForegroundColor Green
Write-Host "This may take a few minutes..." -ForegroundColor Yellow
Write-Host ""

docker save $imageName -o $outputTar

Write-Host ""
Write-Host "Creating extraction scripts and README..." -ForegroundColor Green

# Create Linux/macOS extraction script
$extractShContent = @'
#!/usr/bin/env bash

#==============================================================================
# Offline Container Package Extraction Script
#==============================================================================

set -e

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
RESET='\033[0m'

echo -e "${CYAN}=======================================${RESET}"
echo -e "${CYAN}  silo-log-pull Offline Setup${RESET}"
echo -e "${CYAN}=======================================${RESET}"
echo ""

# Determine which container runtime to use
CONTAINER_CMD=""
if command -v docker >/dev/null 2>&1; then
    CONTAINER_CMD="docker"
    echo -e "${GREEN}Found Docker${RESET}"
elif command -v podman >/dev/null 2>&1; then
    CONTAINER_CMD="podman"
    echo -e "${GREEN}Found Podman${RESET}"
else
    echo -e "${RED}Error: Neither docker nor podman is installed${RESET}"
    echo ""
    echo "Please install a container runtime first:"
    echo "  Ubuntu/Debian: sudo apt install docker.io"
    echo "  RHEL/CentOS:   sudo dnf install docker"
    echo "  Or install Podman: sudo dnf install podman"
    exit 1
fi

TAR_FILE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/silo-log-pull.tar"

if [ ! -f "${TAR_FILE}" ]; then
    echo -e "${RED}Error: Container image file not found: ${TAR_FILE}${RESET}"
    exit 1
fi

echo ""
echo -e "${GREEN}Loading container image...${RESET}"
echo "This may take a few minutes..."
echo ""

${CONTAINER_CMD} load -i "${TAR_FILE}"

echo ""
echo -e "${GREEN}============================================${RESET}"
echo -e "${GREEN}Container image loaded successfully!${RESET}"
echo -e "${GREEN}============================================${RESET}"
echo ""
echo "To run silo-log-pull:"
echo "  cd app"
echo "  ${CONTAINER_CMD} run --rm -v \$(pwd)/data:/data silo-log-pull"
echo ""
echo "See the docs/ directory for complete documentation."
'@

Set-Content -Path (Join-Path $tempDir "offline-extract.sh") -Value $extractShContent -NoNewline

# Create Windows extraction script
$extractPs1Content = @'
#Requires -Version 5.1

<#
.SYNOPSIS
    Offline Container Package Extraction Script

.DESCRIPTION
    Loads the silo-log-pull container image from the tar file
#>

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "  silo-log-pull Offline Setup" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

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

Write-Host "Found Docker: $($dockerCmd.Source)" -ForegroundColor Green

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$tarFile = Join-Path $scriptDir "silo-log-pull.tar"

if (-not (Test-Path $tarFile)) {
    Write-Host "Error: Container image file not found: $tarFile" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Loading container image..." -ForegroundColor Green
Write-Host "This may take a few minutes..." -ForegroundColor Yellow
Write-Host ""

docker load -i $tarFile

Write-Host ""
Write-Host "============================================" -ForegroundColor Green
Write-Host "Container image loaded successfully!" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Green
Write-Host ""
Write-Host "To run silo-log-pull:"
Write-Host "  cd app"
Write-Host "  docker run --rm -v `${PWD}/data:/data silo-log-pull"
Write-Host ""
Write-Host "See the docs\ directory for complete documentation."
'@

Set-Content -Path (Join-Path $tempDir "offline-extract.ps1") -Value $extractPs1Content -NoNewline

# Create README file
$readmeContent = @'
================================================================================
silo-log-pull - Offline Container Package
================================================================================

This package contains everything needed to run silo-log-pull with containers
on an offline system without internet access.

CONTENTS:
  - silo-log-pull.tar     Container image (Docker/Podman)
  - app/                  Application data directory
  - docs/                 Complete documentation
  - scripts/              Setup and utility scripts
  - offline-extract.sh    Linux/macOS setup script
  - offline-extract.ps1   Windows setup script
  - README-OFFLINE.txt    This file

QUICK START:

  Linux/macOS:
    1. Extract this archive: unzip silo-log-pull-container-offline.zip
    2. Run setup script: ./offline-extract.sh
    3. Follow on-screen instructions

  Windows:
    1. Extract this archive: Expand-Archive silo-log-pull-container-offline.zip
    2. Run setup script: .\offline-extract.ps1
    3. Follow on-screen instructions

MANUAL INSTALLATION (if extraction script doesn't work):

  Linux/macOS:
    docker load -i silo-log-pull.tar
    (or: podman load -i silo-log-pull.tar)

  Windows:
    docker load -i silo-log-pull.tar

CONFIGURATION:

  See docs/configuration-reference.md for complete configuration details.

  Quick start:
    1. Copy app/data/example_silo_config.json to app/data/silo_config.json
    2. Edit silo_config.json with your organization name
    3. Create app/data/token.txt with your API token

RUNNING:

  After loading the image and configuring:

  Linux/macOS:
    cd app
    docker run --rm -v $(pwd)/data:/data silo-log-pull
    (or: podman run --rm -v $(pwd)/data:/data silo-log-pull)

  Windows:
    cd app
    docker run --rm -v ${PWD}/data:/data silo-log-pull

  Logs will be written to app/data/logs/

DOCUMENTATION:

  All documentation is in the docs/ directory:
    - README.md                      Documentation index
    - configuration-reference.md     All settings and options
    - container-guide.md            Container deployment guide
    - scheduled-execution.md        Automation setup
    - example_configs/              Example configurations

SUPPORT:

  See https://gitlab.com/breakwaterlabs/silo-log-pull for updates and support.

================================================================================
'@

Set-Content -Path (Join-Path $tempDir "README-OFFLINE.txt") -Value $readmeContent -NoNewline

Write-Host ""
Write-Host "Creating offline package archive..." -ForegroundColor Green

# Remove old zip if it exists
if (Test-Path $outputZip) {
    Remove-Item $outputZip -Force
}

# Copy docs and scripts to temp dir for packaging
Write-Host "Adding docs directory..." -ForegroundColor Gray
Copy-Item -Path (Join-Path $repoBase "docs") -Destination (Join-Path $tempDir "docs") -Recurse -Force

Write-Host "Adding scripts directory..." -ForegroundColor Gray
Copy-Item -Path (Join-Path $repoBase "scripts") -Destination (Join-Path $tempDir "scripts") -Recurse -Force

# Create the zip with all necessary files
Write-Host "Compressing archive..." -ForegroundColor Gray
Compress-Archive -Path (Join-Path $tempDir "*") -DestinationPath $outputZip -Force

# Clean up temp directory
Remove-Item $tempDir -Recurse -Force

Write-Host ""
Write-Host "============================================" -ForegroundColor Green
Write-Host "Container package created!" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Green
Write-Host ""
Write-Host "Package location: $outputZip"
Write-Host ""
Write-Host "To use on an offline system:" -ForegroundColor Cyan
Write-Host ""
Write-Host "  1. Transfer the zip file to the offline system"
Write-Host ""
Write-Host "  2. Extract the archive:"
Write-Host "     Expand-Archive silo-log-pull-container-offline.zip"
Write-Host ""
Write-Host "  3. Run the extraction script (recommended):"
Write-Host "     .\offline-extract.ps1"
Write-Host ""
Write-Host "  4. OR load manually:"
Write-Host "     docker load -i silo-log-pull.tar"
Write-Host ""
Write-Host "  5. Configure and run - see README-OFFLINE.txt in the package"
