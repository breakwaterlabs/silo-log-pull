#Requires -Version 5.1

<#
.SYNOPSIS
    Prepare offline Python package

.DESCRIPTION
    Downloads Python dependencies and creates a comprehensive zip archive for offline systems

.PARAMETER IncludeLogs
    Include existing logs/ and logs_out/ directories in the offline bundle
#>

param(
    [switch]$IncludeLogs
)

$repoBase = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$appDir = Join-Path $repoBase "app"
$depsDir = Join-Path $appDir "silo-dependencies"
$tempDir = Join-Path $repoBase ".offline-temp"
$outputZip = Join-Path $repoBase "silo-log-pull-offline.zip"
$requirementsPath = Join-Path $appDir "requirements.txt"

# Check if Python is installed
try {
    $pythonVersion = & python --version 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "Python not found"
    }
} catch {
    Write-Host "Error: Python is not installed or not in PATH" -ForegroundColor Red
    exit 1
}

# Check if pip is available
try {
    $pipVersion = & python -m pip --version 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "pip not found"
    }
} catch {
    Write-Host "Error: pip is not available" -ForegroundColor Red
    exit 1
}

# Prompt for log inclusion if not specified
if (-not $PSBoundParameters.ContainsKey('IncludeLogs')) {
    $logDetails = & "$PSScriptRoot\get-log-details.ps1"

    Write-Host ""
    Write-Host "Do you want to include existing logs in the offline bundle?" -ForegroundColor Yellow
    foreach ($logInfo in $logDetails) {
        $displayCount = if ($logInfo.Exists) {
            $logInfo.FileCount
        } else {
            "(not found)"
        }
        Write-Host "Files: $($displayCount.PadRight(13)) Path: $($logInfo.Path)"
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

Write-Host "Creating dependencies directory..." -ForegroundColor Green
New-Item -ItemType Directory -Force -Path $depsDir | Out-Null

Write-Host ""
Write-Host "Downloading Python dependencies..." -ForegroundColor Green
Write-Host "This may take a few minutes..." -ForegroundColor Yellow
Write-Host ""

Push-Location $appDir
try {
    python -m pip download -r requirements.txt -d silo-dependencies
} finally {
    Pop-Location
}

Write-Host ""
Write-Host "Creating extraction scripts and README..." -ForegroundColor Green
New-Item -ItemType Directory -Force -Path $tempDir | Out-Null

# Create Linux/macOS extraction script
$extractShContent = @'
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
'@

Set-Content -Path (Join-Path $tempDir "offline-extract.sh") -Value $extractShContent -NoNewline

# Create Windows extraction script
$extractPs1Content = @'
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
'@

Set-Content -Path (Join-Path $tempDir "offline-extract.ps1") -Value $extractPs1Content -NoNewline

# Create README file
$readmeContent = @'
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
'@

Set-Content -Path (Join-Path $tempDir "README-OFFLINE.txt") -Value $readmeContent -NoNewline

Write-Host ""
Write-Host "Creating offline package archive..." -ForegroundColor Green

# Remove old zip if it exists
if (Test-Path $outputZip) {
    Remove-Item $outputZip -Force
}

# Create a temporary staging directory for the zip
$stagingDir = Join-Path $tempDir "staging"
New-Item -ItemType Directory -Force -Path $stagingDir | Out-Null

# Copy app directory
Write-Host "Adding app directory..." -ForegroundColor Gray
$stagingApp = Join-Path $stagingDir "app"
Copy-Item -Path $appDir -Destination $stagingApp -Recurse -Force
# Remove unwanted directories from app
Remove-Item -Path (Join-Path $stagingApp "venv") -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path (Join-Path $stagingApp "__pycache__") -Recurse -Force -ErrorAction SilentlyContinue

# Conditionally remove logs based on parameter
if (-not $IncludeLogs) {
    Remove-Item -Path (Join-Path $stagingApp "data\logs") -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -Path (Join-Path $stagingApp "data\logs_out") -Recurse -Force -ErrorAction SilentlyContinue
}

Remove-Item -Path (Join-Path $stagingApp "data\silo_config.json") -Force -ErrorAction SilentlyContinue
Remove-Item -Path (Join-Path $stagingApp "data\token.txt") -Force -ErrorAction SilentlyContinue
Remove-Item -Path (Join-Path $stagingApp "data_dir.txt") -Force -ErrorAction SilentlyContinue

# Copy docs directory
Write-Host "Adding docs directory..." -ForegroundColor Gray
Copy-Item -Path (Join-Path $repoBase "docs") -Destination (Join-Path $stagingDir "docs") -Recurse -Force

# Copy scripts directory
Write-Host "Adding scripts directory..." -ForegroundColor Gray
Copy-Item -Path (Join-Path $repoBase "scripts") -Destination (Join-Path $stagingDir "scripts") -Recurse -Force

# Copy extraction scripts and README
Copy-Item -Path (Join-Path $tempDir "offline-extract.sh") -Destination $stagingDir
Copy-Item -Path (Join-Path $tempDir "offline-extract.ps1") -Destination $stagingDir
Copy-Item -Path (Join-Path $tempDir "README-OFFLINE.txt") -Destination $stagingDir

# Create the zip archive
Write-Host "Compressing archive..." -ForegroundColor Gray
Compress-Archive -Path (Join-Path $stagingDir "*") -DestinationPath $outputZip -Force

# Clean up temp directory
Remove-Item $tempDir -Recurse -Force

Write-Host ""
Write-Host "============================================" -ForegroundColor Green
Write-Host "Offline package created!" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Green
Write-Host ""
Write-Host "Package location: $outputZip"
Write-Host ""
Write-Host "To use on an offline system:" -ForegroundColor Cyan
Write-Host ""
Write-Host "  1. Transfer the zip file to the offline system"
Write-Host ""
Write-Host "  2. Extract the archive:"
Write-Host "     Expand-Archive silo-log-pull-offline.zip"
Write-Host ""
Write-Host "  3. Run the extraction script (recommended):"
Write-Host "     .\offline-extract.ps1"
Write-Host ""
Write-Host "  4. OR install manually:"
Write-Host "     cd app"
Write-Host "     python -m venv venv"
Write-Host "     .\venv\Scripts\Activate.ps1"
Write-Host "     pip install --no-index --find-links silo-dependencies -r requirements.txt"
Write-Host ""
Write-Host "  5. Configure and run - see README-OFFLINE.txt in the package"
