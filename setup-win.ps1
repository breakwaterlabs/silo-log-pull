#Requires -Version 5.1

<#
.SYNOPSIS
    Setup menu for silo-log-pull on Windows

.DESCRIPTION
    This script provides a menu-driven interface for managing silo-log-pull
    deployment options including Python and container-based setups.

.EXAMPLE
    .\setup.ps1
#>

$repoBase = $PSScriptRoot
$scriptsDir = Join-Path $repoBase "scripts\win"

function Test-IsAdministrator {
    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    return $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Show-Header {
    Clear-Host
    Write-Host "=========================================" -ForegroundColor Cyan
    Write-Host "  silo-log-pull Setup Menu" -ForegroundColor Cyan
    Write-Host "=========================================" -ForegroundColor Cyan
    Write-Host ""

    $isAdmin = Test-IsAdministrator
    if ($isAdmin) {
        Write-Host "Running with Administrator privileges" -ForegroundColor Green
    } else {
        Write-Host "Running without Administrator privileges" -ForegroundColor Yellow
    }
    Write-Host ""
}

function Show-Menu {
    Show-Header

    $isAdmin = Test-IsAdministrator
    if (-not $isAdmin) {
        Write-Host "0. Relaunch as Administrator" -ForegroundColor Yellow
        Write-Host "   (Allows more accurate container and virtualization checks)" -ForegroundColor Gray
        Write-Host ""
    }

    # Highlight container/system options in yellow when not admin
    $color = if ($isAdmin) { "White" } else { "Yellow" }

    Write-Host "1. Run systems test" -ForegroundColor $color
    Write-Host "2. Install Python dependencies (venv)"
    Write-Host "3. Build local container" -ForegroundColor $color
    Write-Host "4. Pull container from registry" -ForegroundColor $color
    Write-Host "5. Prepare offline bundle"
    Write-Host "6. Schedule execution (Task Scheduler)"
    Write-Host "7. Run script (Python or Container)"
    Write-Host "8. Exit"
    Write-Host ""
    Write-Host -NoNewline "Select an option [1-8]: "
}

function Invoke-ScriptAndPause {
    param(
        [string]$ScriptPath,
        [string]$Message
    )

    Write-Host ""
    Write-Host $Message -ForegroundColor Green
    Write-Host ""

    & $ScriptPath

    Write-Host ""
    Write-Host -NoNewline "Press Enter to continue..."
    $null = Read-Host
}

# Main loop
while ($true) {
    Show-Menu
    $choice = Read-Host

    switch ($choice) {
        "0" {
            $isAdmin = Test-IsAdministrator
            if ($isAdmin) {
                Write-Host ""
                Write-Host "Already running as Administrator." -ForegroundColor Green
                Write-Host ""
                Write-Host -NoNewline "Press Enter to continue..."
                $null = Read-Host
            } else {
                Write-Host ""
                Write-Host "Relaunching as Administrator..." -ForegroundColor Yellow
                Start-Process powershell.exe -ArgumentList "-ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
                exit 0
            }
        }
        "1" {
            Invoke-ScriptAndPause `
                -ScriptPath (Join-Path $scriptsDir "system-test.ps1") `
                -Message "Running systems test..."
        }
        "2" {
            Invoke-ScriptAndPause `
                -ScriptPath (Join-Path $scriptsDir "install-python.ps1") `
                -Message "Installing Python dependencies..."
        }
        "3" {
            Invoke-ScriptAndPause `
                -ScriptPath (Join-Path $scriptsDir "build-container.ps1") `
                -Message "Building local container..."
        }
        "4" {
            Invoke-ScriptAndPause `
                -ScriptPath (Join-Path $scriptsDir "pull-container.ps1") `
                -Message "Pulling container from registry..."
        }
        "5" {
            Invoke-ScriptAndPause `
                -ScriptPath (Join-Path $scriptsDir "prepare-offline-bundle.ps1") `
                -Message "Preparing offline bundle..."
        }
        "6" {
            Invoke-ScriptAndPause `
                -ScriptPath (Join-Path $scriptsDir "schedule-taskscheduler.ps1") `
                -Message "Showing schedule execution instructions..."
        }
        "7" {
            & (Join-Path $scriptsDir "run-script.ps1")
        }
        "8" {
            Write-Host ""
            Write-Host "Exiting..." -ForegroundColor Green
            exit 0
        }
        default {
            Write-Host ""
            Write-Host "Invalid option. Please select 1-8." -ForegroundColor Red
            Write-Host ""
            Write-Host -NoNewline "Press Enter to continue..."
            $null = Read-Host
        }
    }
}
