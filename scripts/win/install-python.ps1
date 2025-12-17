#Requires -Version 5.1

<#
.SYNOPSIS
    Install Python dependencies in a virtual environment

.DESCRIPTION
    Creates a Python virtual environment and installs all required dependencies
#>

$repoBase = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$appDir = Join-Path $repoBase "app"
$venvDir = Join-Path $appDir "venv"
$requirementsPath = Join-Path $appDir "requirements.txt"

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
python -m pip install --upgrade pip

Write-Host "Installing dependencies from requirements.txt..." -ForegroundColor Green
python -m pip install -r $requirementsPath

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
Write-Host "To deactivate the virtual environment when done:"
Write-Host "  deactivate"
