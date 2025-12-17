#Requires -Version 5.1

<#
.SYNOPSIS
    Schedule execution with Task Scheduler

.DESCRIPTION
    Provides instructions for scheduling silo-log-pull with Windows Task Scheduler
#>

$repoBase = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$appDir = Join-Path $repoBase "app"

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "  Schedule Execution with Task Scheduler" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "To schedule silo-log-pull to run automatically, follow these steps:"
Write-Host ""

# Detect available tools
$hasPython = $null -ne (Get-Command python -ErrorAction SilentlyContinue)
$hasDocker = $null -ne (Get-Command docker -ErrorAction SilentlyContinue)

Write-Host "Method 1: Using Task Scheduler GUI" -ForegroundColor Green
Write-Host "===================================" -ForegroundColor Green
Write-Host ""
Write-Host "1. Open Task Scheduler (taskschd.msc)"
Write-Host "2. Click 'Create Basic Task'"
Write-Host "3. Set a name (e.g., 'Silo Log Pull Daily')"
Write-Host "4. Choose trigger (e.g., Daily at 2:00 AM)"
Write-Host "5. Choose action: 'Start a program'"
Write-Host ""

if ($hasDocker) {
    Write-Host "For Container Mode:" -ForegroundColor Yellow
    Write-Host "  Program/script: docker"
    Write-Host "  Arguments: run --rm -v $appDir\data:/data silo-log-pull"
    Write-Host "  Start in: $appDir"
    Write-Host ""
}

if ($hasPython) {
    $venvPath = Join-Path $appDir "venv"
    if (Test-Path $venvPath) {
        Write-Host "For Python Mode (with venv):" -ForegroundColor Yellow
        Write-Host "  Create a batch file at: $appDir\run_silo.bat"
        Write-Host "  With this content:"
        Write-Host "    @echo off"
        Write-Host "    cd /d $appDir"
        Write-Host "    call venv\Scripts\activate.bat"
        Write-Host "    python silo_batch_pull.py"
        Write-Host ""
        Write-Host "  Then in Task Scheduler:"
        Write-Host "  Program/script: $appDir\run_silo.bat"
        Write-Host ""
    } else {
        Write-Host "For Python Mode (system Python):" -ForegroundColor Yellow
        $pythonPath = (Get-Command python).Source
        Write-Host "  Program/script: $pythonPath"
        Write-Host "  Arguments: silo_batch_pull.py"
        Write-Host "  Start in: $appDir"
        Write-Host ""
    }
}

if (-not $hasPython -and -not $hasDocker) {
    Write-Host "No container runtime or Python detected." -ForegroundColor Yellow
    Write-Host "Please install Docker or Python 3 first."
    Write-Host ""
}

Write-Host ""
Write-Host "Method 2: Using PowerShell (Advanced)" -ForegroundColor Green
Write-Host "======================================" -ForegroundColor Green
Write-Host ""
Write-Host "Example: Create a task that runs daily at 2 AM"
Write-Host ""

if ($hasDocker) {
    Write-Host "For Container Mode:" -ForegroundColor Yellow
    Write-Host @'
$action = New-ScheduledTaskAction -Execute "docker" -Argument "run --rm -v C:\path\to\silo-log-pull\app\data:/data silo-log-pull" -WorkingDirectory "C:\path\to\silo-log-pull\app"
$trigger = New-ScheduledTaskTrigger -Daily -At 2am
Register-ScheduledTask -Action $action -Trigger $trigger -TaskName "SiloLogPull" -Description "Run Silo Log Pull daily"
'@
    Write-Host ""
}

Write-Host ""
Write-Host "Additional Configuration:" -ForegroundColor Green
Write-Host "=========================" -ForegroundColor Green
Write-Host ""
Write-Host "In Task Scheduler, configure these settings:"
Write-Host "  - Run whether user is logged on or not"
Write-Host "  - Run with highest privileges (if needed for Docker)"
Write-Host "  - Configure for: Windows 10"
Write-Host ""
Write-Host "To view scheduled tasks:"
Write-Host "  Get-ScheduledTask | Where-Object {`$_.TaskName -like '*Silo*'}"
Write-Host ""
Write-Host "To manually run a task (testing):"
Write-Host "  Start-ScheduledTask -TaskName 'SiloLogPull'"
