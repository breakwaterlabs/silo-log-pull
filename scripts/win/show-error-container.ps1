#Requires -Version 5.1

<#
.SYNOPSIS
    Display Container Error Information

.DESCRIPTION
    Shows common container runtime issues on Windows systems

.PARAMETER ErrorType
    Type of error: run, build, or load (defaults to run)

.EXAMPLE
    .\show-error-container.ps1
    .\show-error-container.ps1 -ErrorType build
#>

[CmdletBinding()]
param(
    [string]$ErrorType = "run"
)

Write-Host ""
Write-Host "Container operation failed." -ForegroundColor Red
Write-Host ""
Write-Host "Common issues:" -ForegroundColor Yellow

switch ($ErrorType) {
    "run" {
        Write-Host "  • Docker service not running"
        Write-Host "  • Invalid volume mount path"
        Write-Host "  • Configuration errors"
    }
    "build" {
        Write-Host "  • Docker service not running"
        Write-Host "  • Insufficient disk space"
        Write-Host "  • Network connectivity issues"
    }
    "load" {
        Write-Host "  • Docker service not running"
        Write-Host "  • Insufficient disk space"
        Write-Host "  • Corrupted tar file"
    }
    default {
        Write-Host "  • Docker service not running"
        Write-Host "  • Configuration or permission errors"
    }
}

Write-Host ""
Write-Host "For troubleshooting, see:" -ForegroundColor Yellow
Write-Host "  docs\container-guide.md"

if ($ErrorType -eq "load") {
    Write-Host "  docs\offline-systems.md"
}
