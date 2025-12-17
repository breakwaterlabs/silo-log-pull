#Requires -Version 5.1

<#
.SYNOPSIS
    Fixes container engine not running issue

.DESCRIPTION
    Provides guidance and options to start Docker Desktop or Rancher Desktop
    when the container engine is not running

.PARAMETER DockerFound
    Whether Docker Desktop is installed

.PARAMETER RancherFound
    Whether Rancher Desktop is installed

.PARAMETER IsAdmin
    Whether running with Administrator privileges
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [bool]$DockerFound,

    [Parameter(Mandatory)]
    [bool]$RancherFound,

    [Parameter(Mandatory)]
    [bool]$IsAdmin
)

Write-Host ""
Write-Host "===================================" -ForegroundColor Cyan
Write-Host "Container Engine Issue Detected" -ForegroundColor Cyan
Write-Host "===================================" -ForegroundColor Cyan
Write-Host ""

$engineName = if ($RancherFound) { "Rancher Desktop" } elseif ($DockerFound) { "Docker Desktop" } else { "Container engine" }

Write-Host -ForegroundColor Yellow "$engineName is installed but not running."
Write-Host ""

if ($IsAdmin) {
    Write-Host "You are running with Administrator privileges."
    Write-Host ""
    Write-Host -ForegroundColor Cyan "Options to fix this:"
    Write-Host ""
    Write-Host "1. Start $engineName now (recommended)"
    Write-Host "   - Press 'Y' to attempt to start it"
    Write-Host ""
    Write-Host "2. Start manually"
    if ($RancherFound) {
        Write-Host "   - Open Rancher Desktop from the Start menu"
        Write-Host "   - Wait for it to fully start (check system tray)"
    } elseif ($DockerFound) {
        Write-Host "   - Open Docker Desktop from the Start menu"
        Write-Host "   - Wait for it to fully start (check system tray)"
    } 
    Write-Host ""
    Write-Host -NoNewline "Would you like to attempt to start $engineName now? (Y/N): "
    $response = Read-Host

    if ($response -eq 'Y' -or $response -eq 'y') {
        Write-Host ""
        Write-Host -ForegroundColor Cyan "Attempting to start $engineName..."

        try {
            if ($RancherFound) {
                # Try to start Rancher Desktop
                $rancherPath = "${env:ProgramFiles}\Rancher Desktop\Rancher Desktop.exe"
                if (Test-Path $rancherPath) {
                    Start-Process -FilePath $rancherPath
                    Write-Host -ForegroundColor Green "Rancher Desktop launch initiated."
                } else {
                    Write-Host -ForegroundColor Yellow "Rancher Desktop executable not found at expected location."
                    Write-Host "Please start it manually from the Start menu."
                }
            } elseif ($DockerFound) {
                # Try to start Docker Desktop
                $dockerPath = "${env:ProgramFiles}\Docker\Docker\Docker Desktop.exe"
                if (Test-Path $dockerPath) {
                    Start-Process -FilePath $dockerPath
                    Write-Host -ForegroundColor Green "Docker Desktop launch initiated."
                } else {
                    Write-Host -ForegroundColor Yellow "Docker Desktop executable not found at expected location."
                    Write-Host "Please start it manually from the Start menu."
                }
            }

            Write-Host ""
            Write-Host "Note: The container engine may take a minute or two to fully start."
            Write-Host "Wait for the system tray icon to indicate it's running, then re-run this test."
        } catch {
            Write-Host -ForegroundColor Red "Failed to start $engineName : $_"
            Write-Host "Please start it manually from the Start menu."
        }
    }
} else {
    Write-Host "You are NOT running with Administrator privileges."
    Write-Host ""
    Write-Host -ForegroundColor Cyan "To fix this:"
    Write-Host ""
    Write-Host "1. Start $engineName manually"
    if ($DockerFound) {
        Write-Host "   - Open Docker Desktop from the Start menu"
        Write-Host "   - Wait for it to fully start (check system tray)"
    } elseif ($RancherFound) {
        Write-Host "   - Open Rancher Desktop from the Start menu"
        Write-Host "   - Wait for it to fully start (check system tray)"
    }
    Write-Host ""
    Write-Host "2. Or re-run this script as Administrator to get the option to start it automatically"
    Write-Host "   - Right-click PowerShell or this script"
    Write-Host "   - Select 'Run as Administrator'"
}

Write-Host ""
Write-Host -ForegroundColor Cyan "After starting the container engine, re-run this test to verify:"
Write-Host "  .\scripts\win\system-test.ps1"
