#Requires -Version 5.1

<#
.SYNOPSIS
    Prepare offline bundle package

.DESCRIPTION
    Creates a comprehensive offline bundle with optional Python dependencies, container image, and log files.
    Supports both interactive menu mode and command-line flags.

.PARAMETER IncludePython
    Include Python dependencies in the bundle

.PARAMETER IncludeContainer
    Include container image in the bundle

.PARAMETER IncludeLogs
    Include existing logs in the bundle

.PARAMETER NonInteractive
    Run in non-interactive mode using only command-line flags

.PARAMETER OutputPath
    Output path for the bundle (default: silo-log-pull-offline.zip in repository root)

.EXAMPLE
    .\prepare-offline-bundle.ps1
    Interactive mode with prompts

.EXAMPLE
    .\prepare-offline-bundle.ps1 -IncludePython -IncludeLogs
    Create bundle with Python dependencies and logs

.EXAMPLE
    .\prepare-offline-bundle.ps1 -IncludeContainer -NonInteractive
    Create container-only bundle without prompts
#>

param(
    [switch]$IncludePython,
    [switch]$IncludeContainer,
    [switch]$IncludeLogs,
    [switch]$NonInteractive,
    [string]$OutputPath
)


$repoBase = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$tempDir = Join-Path $repoBase ".offline-temp-bundle"

# Set default output path if not provided
if (-not $OutputPath) {
    if ($IncludePython -and $IncludeContainer) {
        $OutputPath = Join-Path $repoBase "silo-log-pull-full-offline.zip"
    } elseif ($IncludeContainer) {
        $OutputPath = Join-Path $repoBase "silo-log-pull-container-offline.zip"
    } else {
        $OutputPath = Join-Path $repoBase "silo-log-pull-offline.zip"
    }
}

# Interactive mode if no flags provided
if (-not $NonInteractive -and -not ($PSBoundParameters.ContainsKey('IncludePython') -or
    $PSBoundParameters.ContainsKey('IncludeContainer') -or
    $PSBoundParameters.ContainsKey('IncludeLogs'))) {

    Write-Host ""
    Write-Host "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║          Silo Log Pull - Offline Bundle Generator            ║" -ForegroundColor Cyan
    Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "What would you like to include in the offline bundle?" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  [1] Python deployment (with dependencies)" -ForegroundColor White
    Write-Host "  [2] Container deployment (Docker/Podman image)" -ForegroundColor White
    Write-Host "  [3] Both Python and Container" -ForegroundColor White
    Write-Host "  [4] Custom selection" -ForegroundColor White
    Write-Host ""
    Write-Host -NoNewline "Choice [1-4]: "
    $choice = Read-Host

    switch ($choice) {
        "1" {
            $IncludePython = $true
            $IncludeContainer = $false
        }
        "2" {
            $IncludePython = $false
            $IncludeContainer = $true
        }
        "3" {
            $IncludePython = $true
            $IncludeContainer = $true
        }
        "4" {
            Write-Host ""
            Write-Host -NoNewline "Include Python dependencies? [Y/n]: "
            $response = Read-Host
            $IncludePython = ($response -ne 'n' -and $response -ne 'N')

            Write-Host -NoNewline "Include container image? [Y/n]: "
            $response = Read-Host
            $IncludeContainer = ($response -ne 'n' -and $response -ne 'N')
        }
        default {
            Write-Host "Invalid choice. Exiting." -ForegroundColor Red
            exit 1
        }
    }

    # Update output path based on selections
    if ($IncludePython -and $IncludeContainer) {
        $OutputPath = Join-Path $repoBase "silo-log-pull-full-offline.zip"
    } elseif ($IncludeContainer) {
        $OutputPath = Join-Path $repoBase "silo-log-pull-container-offline.zip"
    } else {
        $OutputPath = Join-Path $repoBase "silo-log-pull-offline.zip"
    }

    # Prompt for logs
    if (-not $PSBoundParameters.ContainsKey('IncludeLogs')) {
        $logDetails = & "$PSScriptRoot\get-log-details.ps1"

        Write-Host ""
        Write-Host "Do you want to include existing logs in the offline bundle?" -ForegroundColor Yellow
        $logdetails | ForEach-Object {
            if ($_.filecount -eq $null) {$_.filecount="(not found)"}
        }
        write-host $($logDetails | out-string)
        Write-Host -NoNewline "Include logs? [y/N]: "
        $response = Read-Host
        $IncludeLogs = ($response -eq 'y' -or $response -eq 'Y')
    }
}

# Display configuration
Write-Host ""
Write-Host "Bundle Configuration:" -ForegroundColor Cyan
Write-Host "  Python dependencies: $(if ($IncludePython) { 'Yes' } else { 'No' })" -ForegroundColor $(if ($IncludePython) { 'Green' } else { 'Gray' })
Write-Host "  Container image:     $(if ($IncludeContainer) { 'Yes' } else { 'No' })" -ForegroundColor $(if ($IncludeContainer) { 'Green' } else { 'Gray' })
Write-Host "  Logs:                $(if ($IncludeLogs) { 'Yes' } else { 'No' })" -ForegroundColor $(if ($IncludeLogs) { 'Green' } else { 'Gray' })
Write-Host "  Output:              $OutputPath" -ForegroundColor White
Write-Host ""

# Validate prerequisites
if ($IncludePython) {
    try {
        $pythonVersion = & python --version 2>&1
        if ($LASTEXITCODE -ne 0) {
            throw "Python not found"
        }
        Write-Host "✓ Python found: $pythonVersion" -ForegroundColor Green
    } catch {
        Write-Host "Error: Python is not installed or not in PATH" -ForegroundColor Red
        Write-Host "Python is required for -IncludePython option" -ForegroundColor Red
        exit 1
    }

    try {
        $null = & python -m pip --version 2>&1
        if ($LASTEXITCODE -ne 0) {
            throw "pip not found"
        }
    } catch {
        Write-Host "Error: pip is not available" -ForegroundColor Red
        exit 1
    }
}

if ($IncludeContainer) {
    $dockerCmd = Get-Command docker -ErrorAction SilentlyContinue
    if (-not $dockerCmd) {
        Write-Host "Error: Docker is not installed or not in PATH" -ForegroundColor Red
        Write-Host "Docker is required for -IncludeContainer option" -ForegroundColor Red
        exit 1
    }
    Write-Host "✓ Docker found: $($dockerCmd.Source)" -ForegroundColor Green

    # Check if image exists
    try {
        docker image inspect silo-log-pull 2>&1 | Out-Null
        if ($LASTEXITCODE -ne 0) {
            throw "Image not found"
        }
        Write-Host "✓ Container image 'silo-log-pull' found" -ForegroundColor Green
    } catch {
        Write-Host "Error: Container image 'silo-log-pull' not found" -ForegroundColor Red
        Write-Host ""
        Write-Host "Please build or pull the image first:" -ForegroundColor Yellow
        Write-Host "  Option 1: Run 'Build local container' from the menu"
        Write-Host "  Option 2: Run 'Pull container from registry' from the menu"
        exit 1
    }
}

Write-Host ""

# Create staging directory structure
Write-Host "Creating staging directory..." -ForegroundColor Green
if (Test-Path $tempDir) {
    Remove-Item $tempDir -Recurse -Force
}
New-Item -ItemType Directory -Force -Path $tempDir | Out-Null

# Copy repository files (excluding data, venv, pycache, git)
Write-Host "Copying repository files..." -ForegroundColor Green
$excludeDirs = @('data', 'venv', '__pycache__', '.git', '.offline-temp*', 'node_modules')

Get-ChildItem -Path $repoBase -Directory | Where-Object {
    $_.Name -notin $excludeDirs -and $_.Name -notlike '.offline-temp*'
} | ForEach-Object {
    Copy-Item -Path $_.FullName -Destination $tempDir -Recurse -Force
}

Get-ChildItem -Path $repoBase -File | Where-Object {
    $_.Name -ne 'data_dir.txt' -and $_.Name -notlike '*.zip'
} | ForEach-Object {
    Copy-Item -Path $_.FullName -Destination $tempDir -Force
}

# Create clean data directory structure
Write-Host "Creating clean data directory structure..." -ForegroundColor Green
$dataDir = Join-Path $tempDir "app\data"
New-Item -ItemType Directory -Force -Path $dataDir | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $dataDir "logs") | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $dataDir "logs_out") | Out-Null

# Copy example config
$exampleConfig = Join-Path $repoBase "app\data\example_silo_config.json"
if (Test-Path $exampleConfig) {
    Copy-Item -Path $exampleConfig -Destination $dataDir -Force
}

# Conditionally include Python dependencies
if ($IncludePython) {
    Write-Host ""
    Write-Host "Downloading Python dependencies..." -ForegroundColor Green
    Write-Host "This may take a few minutes..." -ForegroundColor Yellow

    $depsDir = Join-Path $tempDir "app\silo-dependencies"
    New-Item -ItemType Directory -Force -Path $depsDir | Out-Null

    $appDir = Join-Path $repoBase "app"
    Push-Location $appDir
    try {
        python -m pip download -r requirements.txt -d (Join-Path $tempDir "app\silo-dependencies")
        if ($LASTEXITCODE -ne 0) {
            throw "Failed to download dependencies"
        }
    } finally {
        Pop-Location
    }
}

# Conditionally include container image
if ($IncludeContainer) {
    Write-Host ""
    Write-Host "Exporting container image..." -ForegroundColor Green
    Write-Host "This may take a few minutes..." -ForegroundColor Yellow

    $outputTar = Join-Path $tempDir "silo-log-pull.tar"
    docker save silo-log-pull -o $outputTar

    if ($LASTEXITCODE -ne 0) {
        Write-Host "Error: Failed to export container image" -ForegroundColor Red
        Remove-Item $tempDir -Recurse -Force
        exit 1
    }
}

# Conditionally include logs
if ($IncludeLogs) {
    Write-Host ""
    Write-Host "Bundling logs..." -ForegroundColor Green

    & "$PSScriptRoot\bundle-logs.ps1" `
        -OutputPath $dataDir `
        -LogSourcePath $repoBase
}

# Create extraction scripts and README
Write-Host ""
Write-Host "Creating extraction scripts and README..." -ForegroundColor Green

# Determine which extraction scripts to create based on what's included
if ($IncludePython) {
    # Create Python extraction script for Linux/macOS
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

    # Create Python extraction script for Windows
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
}

if ($IncludeContainer) {
    # Create Container extraction script for Linux/macOS
    $extractContainerShContent = @'
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

    $extractContainerFilename = if ($IncludePython) { "offline-extract-container.sh" } else { "offline-extract.sh" }
    Set-Content -Path (Join-Path $tempDir $extractContainerFilename) -Value $extractContainerShContent -NoNewline

    # Create Container extraction script for Windows
    $extractContainerPs1Content = @'
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

    $extractContainerFilename = if ($IncludePython) { "offline-extract-container.ps1" } else { "offline-extract.ps1" }
    Set-Content -Path (Join-Path $tempDir $extractContainerFilename) -Value $extractContainerPs1Content -NoNewline
}

# Create README
$readmeContent = "================================================================================" + [Environment]::NewLine
$readmeContent += "silo-log-pull - Offline Package" + [Environment]::NewLine
$readmeContent += "================================================================================" + [Environment]::NewLine
$readmeContent += [Environment]::NewLine
$readmeContent += "This package contains everything needed to run silo-log-pull on an offline" + [Environment]::NewLine
$readmeContent += "system without internet access." + [Environment]::NewLine
$readmeContent += [Environment]::NewLine
$readmeContent += "CONTENTS:" + [Environment]::NewLine
$readmeContent += "  - app/                  Python application" + [Environment]::NewLine
if ($IncludePython) {
    $readmeContent += "  - app/silo-dependencies/  Python dependencies (offline packages)" + [Environment]::NewLine
}
if ($IncludeContainer) {
    $readmeContent += "  - silo-log-pull.tar     Container image (Docker/Podman)" + [Environment]::NewLine
}
$readmeContent += "  - docs/                 Complete documentation" + [Environment]::NewLine
$readmeContent += "  - scripts/              Setup and utility scripts" + [Environment]::NewLine
if ($IncludePython) {
    $readmeContent += "  - offline-extract.sh    Python setup script (Linux/macOS)" + [Environment]::NewLine
    $readmeContent += "  - offline-extract.ps1   Python setup script (Windows)" + [Environment]::NewLine
}
if ($IncludeContainer -and $IncludePython) {
    $readmeContent += "  - offline-extract-container.sh   Container setup script (Linux/macOS)" + [Environment]::NewLine
    $readmeContent += "  - offline-extract-container.ps1  Container setup script (Windows)" + [Environment]::NewLine
} elseif ($IncludeContainer) {
    $readmeContent += "  - offline-extract.sh    Container setup script (Linux/macOS)" + [Environment]::NewLine
    $readmeContent += "  - offline-extract.ps1   Container setup script (Windows)" + [Environment]::NewLine
}
$readmeContent += "  - README-OFFLINE.txt    This file" + [Environment]::NewLine
$readmeContent += [Environment]::NewLine
$readmeContent += "QUICK START:" + [Environment]::NewLine
$readmeContent += [Environment]::NewLine

if ($IncludePython) {
    $readmeContent += "  Python Deployment (Linux/macOS):" + [Environment]::NewLine
    $readmeContent += "    1. Extract this archive: unzip $(Split-Path -Leaf $OutputPath)" + [Environment]::NewLine
    $readmeContent += "    2. Run setup script: ./offline-extract.sh" + [Environment]::NewLine
    $readmeContent += "    3. Follow on-screen instructions" + [Environment]::NewLine
    $readmeContent += [Environment]::NewLine
    $readmeContent += "  Python Deployment (Windows):" + [Environment]::NewLine
    $readmeContent += "    1. Extract this archive: Expand-Archive $(Split-Path -Leaf $OutputPath)" + [Environment]::NewLine
    $readmeContent += "    2. Run setup script: .\offline-extract.ps1" + [Environment]::NewLine
    $readmeContent += "    3. Follow on-screen instructions" + [Environment]::NewLine
    $readmeContent += [Environment]::NewLine
}

if ($IncludeContainer) {
    $containerScript = if ($IncludePython) { "offline-extract-container" } else { "offline-extract" }
    $readmeContent += "  Container Deployment (Linux/macOS):" + [Environment]::NewLine
    $readmeContent += "    1. Extract this archive: unzip $(Split-Path -Leaf $OutputPath)" + [Environment]::NewLine
    $readmeContent += "    2. Run setup script: ./$containerScript.sh" + [Environment]::NewLine
    $readmeContent += "    3. Follow on-screen instructions" + [Environment]::NewLine
    $readmeContent += [Environment]::NewLine
    $readmeContent += "  Container Deployment (Windows):" + [Environment]::NewLine
    $readmeContent += "    1. Extract this archive: Expand-Archive $(Split-Path -Leaf $OutputPath)" + [Environment]::NewLine
    $readmeContent += "    2. Run setup script: .\$containerScript.ps1" + [Environment]::NewLine
    $readmeContent += "    3. Follow on-screen instructions" + [Environment]::NewLine
    $readmeContent += [Environment]::NewLine
}

$readmeContent += "CONFIGURATION:" + [Environment]::NewLine
$readmeContent += [Environment]::NewLine
$readmeContent += "  See docs/configuration-reference.md for complete configuration details." + [Environment]::NewLine
$readmeContent += [Environment]::NewLine
$readmeContent += "  Quick start:" + [Environment]::NewLine
$readmeContent += "    1. Copy app/data/example_silo_config.json to app/data/silo_config.json" + [Environment]::NewLine
$readmeContent += "    2. Edit silo_config.json with your organization name" + [Environment]::NewLine
$readmeContent += "    3. Create app/data/token.txt with your API token" + [Environment]::NewLine
$readmeContent += [Environment]::NewLine
$readmeContent += "RUNNING:" + [Environment]::NewLine
$readmeContent += [Environment]::NewLine

if ($IncludePython) {
    $readmeContent += "  Python deployment after setup:" + [Environment]::NewLine
    $readmeContent += "    cd app" + [Environment]::NewLine
    $readmeContent += "    source venv/bin/activate  (Linux/macOS) or .\venv\Scripts\Activate.ps1 (Windows)" + [Environment]::NewLine
    $readmeContent += "    python silo_batch_pull.py" + [Environment]::NewLine
    $readmeContent += [Environment]::NewLine
}

if ($IncludeContainer) {
    $readmeContent += "  Container deployment after setup:" + [Environment]::NewLine
    $readmeContent += "    cd app" + [Environment]::NewLine
    $readmeContent += "    docker run --rm -v `$(pwd)/data:/data silo-log-pull  (Linux/macOS)" + [Environment]::NewLine
    $readmeContent += "    docker run --rm -v `${PWD}/data:/data silo-log-pull  (Windows)" + [Environment]::NewLine
    $readmeContent += [Environment]::NewLine
}

$readmeContent += "DOCUMENTATION:" + [Environment]::NewLine
$readmeContent += [Environment]::NewLine
$readmeContent += "  All documentation is in the docs/ directory:" + [Environment]::NewLine
$readmeContent += "    - README.md                      Documentation index" + [Environment]::NewLine
$readmeContent += "    - configuration-reference.md     All settings and options" + [Environment]::NewLine
if ($IncludePython) {
    $readmeContent += "    - python-guide.md               Python deployment guide" + [Environment]::NewLine
}
if ($IncludeContainer) {
    $readmeContent += "    - container-guide.md            Container deployment guide" + [Environment]::NewLine
}
$readmeContent += "    - scheduled-execution.md        Automation setup" + [Environment]::NewLine
$readmeContent += "    - example_configs/              Example configurations" + [Environment]::NewLine
$readmeContent += [Environment]::NewLine
$readmeContent += "SUPPORT:" + [Environment]::NewLine
$readmeContent += [Environment]::NewLine
$readmeContent += "  See https://gitlab.com/breakwaterlabs/silo-log-pull for updates and support." + [Environment]::NewLine
$readmeContent += [Environment]::NewLine
$readmeContent += "================================================================================" + [Environment]::NewLine

Set-Content -Path (Join-Path $tempDir "README-OFFLINE.txt") -Value $readmeContent -NoNewline

# Create the zip archive
Write-Host ""
Write-Host "Creating offline package archive..." -ForegroundColor Green

# Remove old zip if it exists
if (Test-Path $OutputPath) {
    Remove-Item $OutputPath -Force
}

Write-Host "Compressing archive..." -ForegroundColor Gray
Compress-Archive -Path (Join-Path $tempDir "*") -DestinationPath $OutputPath -Force

# Clean up temp directory
Write-Host "Cleaning up..." -ForegroundColor Gray
Remove-Item $tempDir -Recurse -Force

# Display summary
Write-Host ""
Write-Host "============================================" -ForegroundColor Green
Write-Host "Offline package created!" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Green
Write-Host ""
Write-Host "Package location: $OutputPath" -ForegroundColor White
Write-Host "Package size: $([math]::Round((Get-Item $OutputPath).Length / 1MB, 2)) MB" -ForegroundColor White
Write-Host ""
Write-Host "To use on an offline system:" -ForegroundColor Cyan
Write-Host ""
Write-Host "  1. Transfer the zip file to the offline system"
Write-Host ""
Write-Host "  2. Extract the archive:"
if ($IncludePython -or $IncludeContainer) {
    Write-Host "     Windows: Expand-Archive $(Split-Path -Leaf $OutputPath)"
    Write-Host "     Linux:   unzip $(Split-Path -Leaf $OutputPath)"
} else {
    Write-Host "     Expand-Archive $(Split-Path -Leaf $OutputPath)"
}
Write-Host ""
Write-Host "  3. Run the appropriate extraction script:"
if ($IncludePython) {
    Write-Host "     Python (Windows):   .\offline-extract.ps1"
    Write-Host "     Python (Linux):     ./offline-extract.sh"
}
if ($IncludeContainer) {
    if ($IncludePython) {
        Write-Host "     Container (Windows): .\offline-extract-container.ps1"
        Write-Host "     Container (Linux):   ./offline-extract-container.sh"
    } else {
        Write-Host "     Windows: .\offline-extract.ps1"
        Write-Host "     Linux:   ./offline-extract.sh"
    }
}
Write-Host ""
Write-Host "  4. Configure and run - see README-OFFLINE.txt in the package"
Write-Host ""
