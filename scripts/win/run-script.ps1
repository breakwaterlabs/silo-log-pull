#Requires -Version 5.1

<#
.SYNOPSIS
    Run silo-log-pull script menu

.DESCRIPTION
    Provides a menu to run silo-log-pull using Python (venv) or Container,
    showing the command and offering to execute it.
#>

$repoBase = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$appDir = Join-Path $repoBase "app"

function Show-Header {
    Clear-Host
    Write-Host "=========================================" -ForegroundColor Cyan
    Write-Host "  Run silo-log-pull Script" -ForegroundColor Cyan
    Write-Host "=========================================" -ForegroundColor Cyan
    Write-Host ""
}

function Show-RunScriptMenu {
    while ($true) {
        Show-Header
        Write-Host "Run Script Options:" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "1. Run with Python (venv)"
        Write-Host "2. Run with Container"
        Write-Host "3. Back to main menu"
        Write-Host ""
        Write-Host -NoNewline "Select an option [1-3]: "

        $choice = Read-Host
        Write-Host ""

        switch ($choice) {
            "1" {
                $pythonCmd = "python silo_batch_pull.py"
                $venvPython = Join-Path $appDir "venv\Scripts\python.exe"

                if (Test-Path $venvPython) {
                    $pythonCmd = "venv\Scripts\python.exe silo_batch_pull.py"
                }

                Write-Host "To run with Python:" -ForegroundColor Green
                Write-Host "  cd $appDir" -ForegroundColor Cyan
                Write-Host "  $pythonCmd" -ForegroundColor Cyan
                Write-Host ""
                Write-Host -NoNewline "Would you like to run it now? [Y/n]: "
                $run = Read-Host

                if ($run -eq "" -or $run -eq "Y" -or $run -eq "y") {
                    Write-Host ""
                    Write-Host "Running Python script..." -ForegroundColor Green
                    Write-Host ""
                    Push-Location $appDir
                    try {
                        if (Test-Path $venvPython) {
                            & $venvPython "silo_batch_pull.py"
                        } else {
                            python "silo_batch_pull.py"
                        }
                    } finally {
                        Pop-Location
                    }
                }

                Write-Host ""
                Write-Host -NoNewline "Press Enter to continue..."
                $null = Read-Host
            }
            "2" {
                $containerCmd = "docker run --rm -v `"`${PWD}/data:/data`" silo-log-pull"

                Write-Host "To run with Container:" -ForegroundColor Green
                Write-Host "  cd $appDir" -ForegroundColor Cyan
                Write-Host "  $containerCmd" -ForegroundColor Cyan
                Write-Host ""
                Write-Host -NoNewline "Would you like to run it now? [Y/n]: "
                $run = Read-Host

                if ($run -eq "" -or $run -eq "Y" -or $run -eq "y") {
                    Write-Host ""
                    Write-Host "Running container..." -ForegroundColor Green
                    Write-Host ""
                    Push-Location $appDir
                    try {
                        docker run --rm -v "${PWD}/data:/data" silo-log-pull
                    } finally {
                        Pop-Location
                    }
                }

                Write-Host ""
                Write-Host -NoNewline "Press Enter to continue..."
                $null = Read-Host
            }
            "3" {
                return
            }
            default {
                Write-Host "Invalid option. Please select 1-3." -ForegroundColor Red
                Write-Host ""
                Write-Host -NoNewline "Press Enter to continue..."
                $null = Read-Host
            }
        }
    }
}

# Run the menu
Show-RunScriptMenu
