#Requires -Version 5.1

<#
.SYNOPSIS
    Offline Python Package Extraction Script

.DESCRIPTION
    Sets up Python virtual environment and installs dependencies from offline packages

.PARAMETER Install
    Install dependencies only

.PARAMETER Run
    Run script only (assumes already installed)

.PARAMETER NoConfigure
    Skip data directory configuration
#>

[CmdletBinding()]
param(
    [switch]$Install,
    [switch]$Run,
    [switch]$NoConfigure
)

# Default: install only if no flags specified
if (-not $Install -and -not $Run) {
    $Install = $true
}

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoDir = Split-Path -Parent (Split-Path -Parent $scriptDir)
$appDir = Join-Path $repoDir "app"
$venvDir = Join-Path $appDir "venv"

if ($Install) {
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
    if (-not (Test-Path $venvDir)) {
        Write-Host "Error: Virtual environment not found" -ForegroundColor Red
        Write-Host "Please run with -Install first"
        exit 1
    }

    Write-Host "Running silo-log-pull..." -ForegroundColor Cyan
    Write-Host ""
    $activateScript = Join-Path $venvDir "Scripts\Activate.ps1"
    & $activateScript
    Set-Location $appDir
    python silo_batch_pull.py
} else {
    Write-Host "To run silo-log-pull:"
    Write-Host "  cd $appDir"
    Write-Host "  .\venv\Scripts\Activate.ps1"
    Write-Host "  python silo_batch_pull.py"
    Write-Host ""
    Write-Host "Or use: $scriptDir\$(Split-Path -Leaf $MyInvocation.MyCommand.Path) -Run"
    Write-Host ""
    Write-Host "See the docs\ directory for complete documentation."
}
