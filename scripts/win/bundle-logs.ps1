#!/usr/bin/env pwsh

<#
.SYNOPSIS
    Bundle logs for offline deployment
.DESCRIPTION
    Copies log files from actual locations (determined by data_dir.txt and config) to bundle output directory.
    Non-interactive - all decisions made by calling script.
.PARAMETER OutputPath
    Destination directory for bundled logs (required)
.PARAMETER LogSourcePath
    Override source directory for get-log-details (optional, defaults to current directory)
.PARAMETER Compress
    Compress the bundled logs into a zip archive
.EXAMPLE
    .\bundle-logs.ps1 -OutputPath ".\staging\app\data"
.EXAMPLE
    .\bundle-logs.ps1 -OutputPath ".\staging\app\data" -LogSourcePath "C:\custom\path"
.EXAMPLE
    .\bundle-logs.ps1 -OutputPath ".\staging\app\data" -Compress
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$OutputPath,

    [string]$LogSourcePath = (Get-Location).Path,

    [switch]$Compress
)

# Get log details from the source location
Write-Host "Discovering log files..." -ForegroundColor Cyan

Push-Location $LogSourcePath
try {
    $logDetails = & "$PSScriptRoot\get-log-details.ps1"
} finally {
    Pop-Location
}

if (-not $logDetails -or $logDetails.Count -eq 0) {
    Write-Host "No log locations found." -ForegroundColor Yellow
    exit 0
}

# Copy logs from actual locations to output path
$totalFilesCopied = 0

foreach ($logInfo in $logDetails) {
    if ($logInfo.Exists -and $logInfo.FileCount -gt 0) {
        # Determine destination directory name based on source path
        $destDir = if ($logInfo.Path -match "logs_out|log_out_directory") {
            "logs_out"
        } else {
            "logs"
        }

        $destPath = Join-Path $OutputPath $destDir

        Write-Host "Copying $($logInfo.FileCount) file(s) from:" -ForegroundColor Gray
        Write-Host "  Source: $($logInfo.Path)" -ForegroundColor Gray
        Write-Host "  Dest:   $destPath" -ForegroundColor Gray

        # Ensure destination exists
        New-Item -ItemType Directory -Path $destPath -Force -ErrorAction SilentlyContinue | Out-Null

        # Copy all files from source directory
        try {
            $sourceFiles = Join-Path $logInfo.Path "*"
            Copy-Item -Path $sourceFiles `
                     -Destination $destPath `
                     -Recurse -Force `
                     -ErrorAction Stop

            $totalFilesCopied += $logInfo.FileCount
            Write-Host "  ✓ Copied successfully" -ForegroundColor Green
        } catch {
            Write-Host "  ✗ Error copying files: $_" -ForegroundColor Red
        }
    } elseif (-not $logInfo.Exists) {
        Write-Host "Skipping (not found): $($logInfo.Path)" -ForegroundColor Yellow
    } elseif ($logInfo.FileCount -eq 0) {
        Write-Host "Skipping (empty): $($logInfo.Path)" -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "Log bundling complete." -ForegroundColor Green
Write-Host "Total files bundled: $totalFilesCopied" -ForegroundColor Cyan

# Optionally compress the bundled logs
if ($Compress -and $totalFilesCopied -gt 0) {
    Write-Host ""
    Write-Host "Compressing bundled logs..." -ForegroundColor Cyan

    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $zipPath = Join-Path (Split-Path $OutputPath -Parent) "bundled-logs-$timestamp.zip"

    $logsDir = Join-Path $OutputPath "logs"
    $logsOutDir = Join-Path $OutputPath "logs_out"

    $itemsToCompress = @()
    if (Test-Path $logsDir) { $itemsToCompress += $logsDir }
    if (Test-Path $logsOutDir) { $itemsToCompress += $logsOutDir }

    if ($itemsToCompress.Count -gt 0) {
        try {
            Compress-Archive -Path $itemsToCompress -DestinationPath $zipPath -Force
            $zipSize = [math]::Round((Get-Item $zipPath).Length / 1MB, 2)

            Write-Host "  ✓ Compressed to: $zipPath" -ForegroundColor Green
            Write-Host "  ✓ Archive size: $zipSize MB" -ForegroundColor Green
        } catch {
            Write-Host "  ✗ Error compressing logs: $_" -ForegroundColor Red
        }
    }
}
