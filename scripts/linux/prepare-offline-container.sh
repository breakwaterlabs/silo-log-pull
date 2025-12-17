#!/usr/bin/env bash

#==============================================================================
# Prepare Offline Container Package
#==============================================================================

set -e

REPOBASE="$(cd "$(dirname "${BASH_SOURCE[0]}")"/../.. && pwd)"
TEMP_DIR="${REPOBASE}/.offline-temp-container"
OUTPUT_TAR="${TEMP_DIR}/silo-log-pull.tar"
OUTPUT_ZIP="${REPOBASE}/silo-log-pull-container-offline.zip"
IMAGE_NAME="silo-log-pull"

# ANSI color codes
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
RESET='\033[0m'

# Determine which container runtime to use
CONTAINER_CMD=""
if command -v docker >/dev/null 2>&1; then
    CONTAINER_CMD="docker"
elif command -v podman >/dev/null 2>&1; then
    CONTAINER_CMD="podman"
else
    echo -e "${RED}Error: Neither docker nor podman is installed${RESET}"
    exit 1
fi

echo -e "${GREEN}Using container runtime: ${CONTAINER_CMD}${RESET}"
echo ""

# Check if the image exists
if ! ${CONTAINER_CMD} image inspect "${IMAGE_NAME}" >/dev/null 2>&1; then
    echo -e "${RED}Error: Container image '${IMAGE_NAME}' not found${RESET}"
    echo ""
    echo "Please build or pull the image first:"
    echo "  Option 1: Run 'Build local container' from the menu"
    echo "  Option 2: Run 'Pull container from registry' from the menu"
    exit 1
fi

# Check if zip is installed
if ! command -v zip >/dev/null 2>&1; then
    echo -e "${RED}Error: zip command is not installed${RESET}"
    echo "Please install zip: sudo apt install zip"
    exit 1
fi

echo -e "${GREEN}Creating temporary directory structure...${RESET}"
mkdir -p "${TEMP_DIR}/app/data"

# Copy example configs to app/data if they exist
if [ -d "${REPOBASE}/app/data" ]; then
    # Only copy example/template files, not actual config or logs
    if [ -f "${REPOBASE}/app/data/example_silo_config.json" ]; then
        cp "${REPOBASE}/app/data/example_silo_config.json" "${TEMP_DIR}/app/data/"
    fi
fi

echo ""
echo -e "${GREEN}Exporting container image to tar file...${RESET}"
echo "This may take a few minutes..."
echo ""

${CONTAINER_CMD} save "${IMAGE_NAME}" -o "${OUTPUT_TAR}"

echo ""
echo -e "${GREEN}Creating extraction scripts and README...${RESET}"

# Create Linux/macOS extraction script
cat > "${TEMP_DIR}/offline-extract.sh" <<'EXTRACT_SH_EOF'
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
EXTRACT_SH_EOF

chmod +x "${TEMP_DIR}/offline-extract.sh"

# Create Windows extraction script
cat > "${TEMP_DIR}/offline-extract.ps1" <<'EXTRACT_PS1_EOF'
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
EXTRACT_PS1_EOF

# Create README file
cat > "${TEMP_DIR}/README-OFFLINE.txt" <<'README_EOF'
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
README_EOF

echo ""
echo -e "${GREEN}Creating offline package archive...${RESET}"
cd "${REPOBASE}"

# Remove old zip if it exists
rm -f "${OUTPUT_ZIP}"

# Copy docs and scripts to temp dir for packaging
cp -r "${REPOBASE}/docs" "${TEMP_DIR}/"
cp -r "${REPOBASE}/scripts" "${TEMP_DIR}/"

# Create the zip with all necessary files
cd "${TEMP_DIR}"
zip -r "${OUTPUT_ZIP}" . -x "*.pyc" "__pycache__/*" "*/pycache__/*"

# Clean up temp directory
cd "${REPOBASE}"
rm -rf "${TEMP_DIR}"

echo ""
echo -e "${GREEN}============================================${RESET}"
echo -e "${GREEN}Container package created!${RESET}"
echo -e "${GREEN}============================================${RESET}"
echo ""
echo "Package location: ${OUTPUT_ZIP}"
echo ""
echo -e "${CYAN}To use on an offline system:${RESET}"
echo ""
echo "  1. Transfer the zip file to the offline system"
echo ""
echo "  2. Extract the archive:"
echo "     unzip silo-log-pull-container-offline.zip"
echo ""
echo "  3. Run the extraction script (recommended):"
echo "     ./offline-extract.sh"
echo ""
echo "  4. OR load manually:"
echo "     ${CONTAINER_CMD} load -i silo-log-pull.tar"
echo ""
echo "  5. Configure and run - see README-OFFLINE.txt in the package"
