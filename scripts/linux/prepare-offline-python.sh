#!/usr/bin/env bash

#==============================================================================
# Prepare Offline Python Package
#==============================================================================

set -e

REPOBASE="$(cd "$(dirname "${BASH_SOURCE[0]}")"/../.. && pwd)"
APP_DIR="${REPOBASE}/app"
DEPS_DIR="${APP_DIR}/silo-dependencies"
TEMP_DIR="${REPOBASE}/.offline-temp"
OUTPUT_ZIP="${REPOBASE}/silo-log-pull-offline.zip"
INCLUDE_LOGS=false

# ANSI color codes
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
RESET='\033[0m'

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --include-logs)
            INCLUDE_LOGS=true
            shift
            ;;
        *)
            echo "Unknown option: $1"
            echo "Usage: $0 [--include-logs]"
            exit 1
            ;;
    esac
done

# Check if Python 3 is installed
if ! command -v python3 >/dev/null 2>&1; then
    echo -e "${RED}Error: Python 3 is not installed or not in PATH${RESET}"
    exit 1
fi

# Check if pip is available
if ! python3 -m pip --version >/dev/null 2>&1; then
    echo -e "${RED}Error: pip is not available${RESET}"
    exit 1
fi

# Check if zip is installed
if ! command -v zip >/dev/null 2>&1; then
    echo -e "${RED}Error: zip command is not installed${RESET}"
    echo "Please install zip: sudo apt install zip"
    exit 1
fi

# Prompt for log inclusion if not specified via command line
if [ "$INCLUDE_LOGS" = false ]; then
    SCRIPT_DIR="$(dirname "${BASH_SOURCE[0]}")"
    LOG_DETAILS=$("${SCRIPT_DIR}/get-log-details.sh")

    echo ""
    echo -e "${YELLOW}Do you want to include existing logs in the offline bundle?${RESET}"
    echo "$LOG_DETAILS"
    echo -n "Include logs? [y/N]: "
    read -r response
    if [ "$response" = "y" ] || [ "$response" = "Y" ]; then
        INCLUDE_LOGS=true
    fi
fi

if [ "$INCLUDE_LOGS" = true ]; then
    echo -e "${GREEN}Logs will be included in the offline bundle${RESET}"
else
    echo -e "${RESET}Logs will be excluded from the offline bundle${RESET}"
fi
echo ""

echo -e "${GREEN}Creating dependencies directory...${RESET}"
mkdir -p "${DEPS_DIR}"

echo ""
echo -e "${GREEN}Downloading Python dependencies...${RESET}"
echo "This may take a few minutes..."
echo ""
cd "${APP_DIR}"
python3 -m pip download -r requirements.txt -d silo-dependencies/

echo ""
echo -e "${GREEN}Creating extraction scripts and README...${RESET}"
mkdir -p "${TEMP_DIR}"

# Create Linux/macOS extraction script
cat > "${TEMP_DIR}/offline-extract.sh" <<'EXTRACT_SH_EOF'
#!/usr/bin/env bash

#==============================================================================
# Offline Python Package Extraction Script
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

# Check if Python 3 is installed
if ! command -v python3 >/dev/null 2>&1; then
    echo -e "${RED}Error: Python 3 is not installed${RESET}"
    echo ""
    echo "Please install Python 3 first:"
    echo "  Ubuntu/Debian: sudo apt install python3 python3-pip python3-venv python3-dev gcc libgmp-dev"
    echo "  RHEL/CentOS:   sudo dnf install python3 python3-pip python3-devel gcc gmp-devel"
    exit 1
fi

APP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/app" && pwd)"
VENV_DIR="${APP_DIR}/venv"

echo -e "${GREEN}Creating virtual environment...${RESET}"
python3 -m venv "${VENV_DIR}"

echo -e "${GREEN}Activating virtual environment...${RESET}"
source "${VENV_DIR}/bin/activate"

echo -e "${GREEN}Upgrading pip...${RESET}"
pip install --upgrade pip --quiet

echo -e "${GREEN}Installing dependencies from offline packages...${RESET}"
pip install --no-index --find-links "${APP_DIR}/silo-dependencies" -r "${APP_DIR}/requirements.txt"

echo ""
echo -e "${GREEN}============================================${RESET}"
echo -e "${GREEN}Installation complete!${RESET}"
echo -e "${GREEN}============================================${RESET}"
echo ""
echo "To run silo-log-pull:"
echo "  cd ${APP_DIR}"
echo "  source venv/bin/activate"
echo "  python silo_batch_pull.py"
echo ""
echo "See the docs/ directory for complete documentation."
EXTRACT_SH_EOF

chmod +x "${TEMP_DIR}/offline-extract.sh"

# Create Windows extraction script
cat > "${TEMP_DIR}/offline-extract.ps1" <<'EXTRACT_PS1_EOF'
#Requires -Version 5.1

<#
.SYNOPSIS
    Offline Python Package Extraction Script

.DESCRIPTION
    Sets up Python virtual environment and installs dependencies from offline packages
#>

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "  silo-log-pull Offline Setup" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

# Check if Python is installed
try {
    $pythonVersion = & python --version 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "Python not found"
    }
} catch {
    Write-Host "Error: Python is not installed or not in PATH" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please install Python 3 first:"
    Write-Host "  1. Download from https://www.python.org/downloads/"
    Write-Host "  2. Run the installer and check 'Add Python to PATH'"
    Write-Host "  3. Restart PowerShell after installation"
    exit 1
}

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$appDir = Join-Path $scriptDir "app"
$venvDir = Join-Path $appDir "venv"

Write-Host "Creating virtual environment..." -ForegroundColor Green
python -m venv $venvDir

Write-Host "Activating virtual environment..." -ForegroundColor Green
$activateScript = Join-Path $venvDir "Scripts\Activate.ps1"
& $activateScript

Write-Host "Upgrading pip..." -ForegroundColor Green
python -m pip install --upgrade pip --quiet

Write-Host "Installing dependencies from offline packages..." -ForegroundColor Green
$depsDir = Join-Path $appDir "silo-dependencies"
$reqFile = Join-Path $appDir "requirements.txt"
python -m pip install --no-index --find-links $depsDir -r $reqFile

Write-Host ""
Write-Host "============================================" -ForegroundColor Green
Write-Host "Installation complete!" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Green
Write-Host ""
Write-Host "To run silo-log-pull:"
Write-Host "  cd $appDir"
Write-Host "  .\venv\Scripts\Activate.ps1"
Write-Host "  python silo_batch_pull.py"
Write-Host ""
Write-Host "See the docs\ directory for complete documentation."
EXTRACT_PS1_EOF

# Create README file
cat > "${TEMP_DIR}/README-OFFLINE.txt" <<'README_EOF'
================================================================================
silo-log-pull - Offline Python Package
================================================================================

This package contains everything needed to run silo-log-pull on an offline
system without internet access.

CONTENTS:
  - app/                  Python application and dependencies
  - docs/                 Complete documentation
  - scripts/              Setup and utility scripts
  - offline-extract.sh    Linux/macOS setup script
  - offline-extract.ps1   Windows setup script
  - README-OFFLINE.txt    This file

QUICK START:

  Linux/macOS:
    1. Extract this archive: unzip silo-log-pull-offline.zip
    2. Run setup script: ./offline-extract.sh
    3. Follow on-screen instructions

  Windows:
    1. Extract this archive: Expand-Archive silo-log-pull-offline.zip
    2. Run setup script: .\offline-extract.ps1
    3. Follow on-screen instructions

MANUAL INSTALLATION (if extraction script doesn't work):

  Linux/macOS:
    cd app
    python3 -m venv venv
    source venv/bin/activate
    pip install --no-index --find-links silo-dependencies -r requirements.txt

  Windows:
    cd app
    python -m venv venv
    .\venv\Scripts\Activate.ps1
    pip install --no-index --find-links silo-dependencies -r requirements.txt

CONFIGURATION:

  See docs/configuration-reference.md for complete configuration details.

  Quick start:
    1. Copy app/data/example_silo_config.json to app/data/silo_config.json
    2. Edit silo_config.json with your organization name
    3. Create app/data/token.txt with your API token

RUNNING:

  After installation and configuration:
    cd app
    source venv/bin/activate  (Linux/macOS) or .\venv\Scripts\Activate.ps1 (Windows)
    python silo_batch_pull.py

DOCUMENTATION:

  All documentation is in the docs/ directory:
    - README.md                      Documentation index
    - configuration-reference.md     All settings and options
    - python-guide.md               Python deployment guide
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

# Build exclusion list
EXCLUSIONS="-x app/venv/* app/__pycache__/* app/data/silo_config.json app/data/token.txt app/data_dir.txt"
EXCLUSIONS="$EXCLUSIONS scripts/*/__pycache__/*"

# Conditionally exclude logs
if [ "$INCLUDE_LOGS" = false ]; then
    EXCLUSIONS="$EXCLUSIONS app/data/logs/* app/data/logs_out/*"
fi

# Create the zip with all necessary files
zip -r "${OUTPUT_ZIP}" \
    app/ \
    docs/ \
    scripts/ \
    $EXCLUSIONS

# Add the extraction scripts and README from temp dir
cd "${TEMP_DIR}"
zip -u "${OUTPUT_ZIP}" offline-extract.sh offline-extract.ps1 README-OFFLINE.txt

# Clean up temp directory
cd "${REPOBASE}"
rm -rf "${TEMP_DIR}"

echo ""
echo -e "${GREEN}============================================${RESET}"
echo -e "${GREEN}Offline package created!${RESET}"
echo -e "${GREEN}============================================${RESET}"
echo ""
echo "Package location: ${OUTPUT_ZIP}"
echo ""
echo -e "${CYAN}To use on an offline system:${RESET}"
echo ""
echo "  1. Transfer the zip file to the offline system"
echo ""
echo "  2. Extract the archive:"
echo "     unzip silo-log-pull-offline.zip"
echo ""
echo "  3. Run the extraction script (recommended):"
echo "     ./offline-extract.sh"
echo ""
echo "  4. OR install manually:"
echo "     cd app"
echo "     python3 -m venv venv"
echo "     source venv/bin/activate"
echo "     pip install --no-index --find-links silo-dependencies -r requirements.txt"
echo ""
echo "  5. Configure and run - see README-OFFLINE.txt in the package"
