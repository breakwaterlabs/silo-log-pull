#Requires -Version 5.1

<#
.SYNOPSIS
    Backup configuration and secrets

.DESCRIPTION
    Creates a backup of configuration files and secrets, excluding log files.
    Includes a README with restoration instructions.

.PARAMETER OutputPath
    Output path for the backup archive

.PARAMETER NonInteractive
    Run without interactive prompts

.EXAMPLE
    .\backup-config.ps1
    Creates a backup with timestamp in filename

.EXAMPLE
    .\backup-config.ps1 -OutputPath C:\backups\config.zip -NonInteractive
    Creates backup at specific location without prompts
#>

[CmdletBinding()]
param(
    [Parameter()]
    [string]$OutputPath,

    [Parameter()]
    [switch]$NonInteractive
)

$repoBase = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)

# Set default output path
if (-not $OutputPath) {
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $OutputPath = Join-Path $repoBase "silo-log-pull-config-backup-$timestamp.zip"
}

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "  Backup Configuration and Secrets" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

# Check if Compress-Archive is available (PowerShell 5.0+)
if (-not (Get-Command Compress-Archive -ErrorAction SilentlyContinue)) {
    Write-Host "Error: Compress-Archive cmdlet not available" -ForegroundColor Red
    Write-Host "Please use PowerShell 5.0 or later" -ForegroundColor Red
    exit 1
}

# Read data directory path
$dataDirFile = Join-Path $repoBase "app\data_dir.txt"
if (Test-Path $dataDirFile) {
    $dataDir = Get-Content $dataDirFile -Raw | ForEach-Object { $_.Trim() }
    if (-not (Test-Path $dataDir)) {
        Write-Host "Warning: Data directory specified in data_dir.txt does not exist: $dataDir" -ForegroundColor Yellow
        $dataDir = Join-Path $repoBase "app\data"
    }
} else {
    $dataDir = Join-Path $repoBase "app\data"
}

Write-Host "Data directory: $dataDir" -ForegroundColor Cyan
Write-Host ""

# Create temporary directory
$tempDir = Join-Path ([System.IO.Path]::GetTempPath()) ([System.IO.Path]::GetRandomFileName())
$backupDir = Join-Path $tempDir "config-backup"
New-Item -ItemType Directory -Path $backupDir -Force | Out-Null

# Copy configuration files and secrets (excluding logs)
Write-Host "Collecting configuration files..." -ForegroundColor Green

if (Test-Path $dataDir) {
    $dataBackupDir = Join-Path $backupDir "data"
    New-Item -ItemType Directory -Path $dataBackupDir -Force | Out-Null

    # Get all files excluding logs directories
    # Normalize dataDir to avoid trailing backslash issues
    $normalizedDataDir = $dataDir.TrimEnd('\')
    Get-ChildItem -Path $dataDir -Recurse -File | Where-Object {
        $_.FullName -notmatch '\\logs\\' -and
        $_.FullName -notmatch '\\logs_out\\' -and
        $_.FullName -notmatch '\\logs_in\\' -and
        $_.Extension -ne '.log'
    } | ForEach-Object {
        $relativePath = $_.FullName.Substring($normalizedDataDir.Length + 1)
        $targetPath = Join-Path $dataBackupDir $relativePath
        $targetDir = Split-Path $targetPath -Parent

        if (-not (Test-Path $targetDir)) {
            New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
        }

        Copy-Item $_.FullName -Destination $targetPath -Force
    }

    Write-Host "✓ Configuration files copied" -ForegroundColor Green
} else {
    Write-Host "Warning: Data directory not found: $dataDir" -ForegroundColor Yellow
}

# Copy data_dir.txt if it exists
if (Test-Path $dataDirFile) {
    Copy-Item $dataDirFile -Destination $backupDir -Force
    Write-Host "✓ data_dir.txt copied" -ForegroundColor Green
}

# Create README from template
$templatePath = Join-Path $repoBase "scripts\templates\readme-backup.txt"
if (Test-Path $templatePath) {
    Copy-Item $templatePath -Destination (Join-Path $backupDir "README.txt") -Force
} else {
    Write-Host "Warning: README template not found at $templatePath" -ForegroundColor Yellow
}
Write-Host "✓ README created" -ForegroundColor Green

# Create the zip archive
Write-Host ""
Write-Host "Creating backup archive..." -ForegroundColor Green

# Remove old backup if it exists
if (Test-Path $OutputPath) {
    Remove-Item $OutputPath -Force
}

Compress-Archive -Path "$backupDir\*" -DestinationPath $OutputPath -CompressionLevel Optimal

# Clean up
Remove-Item $tempDir -Recurse -Force

# Display summary
$fileSize = (Get-Item $OutputPath).Length
$fileSizeMB = [math]::Round($fileSize / 1MB, 2)

Write-Host ""
Write-Host "============================================" -ForegroundColor Green
Write-Host "Configuration backup created!" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Green
Write-Host ""
Write-Host "Backup location: " -NoNewline
Write-Host "$OutputPath" -ForegroundColor Yellow
Write-Host "Backup size: " -NoNewline
Write-Host "$fileSizeMB MB" -ForegroundColor Yellow
Write-Host ""
Write-Host "This backup includes:" -ForegroundColor Cyan
Write-Host "  - Configuration files from data directory"
Write-Host "  - API tokens and secrets"
Write-Host "  - data_dir.txt (if present)"
Write-Host ""
Write-Host "Excluded from backup:" -ForegroundColor Yellow
Write-Host "  - Log files (logs, logs_out, logs_in directories)"
Write-Host "  - *.log files"
Write-Host ""
Write-Host "Keep this backup secure!" -ForegroundColor Cyan
Write-Host ""

# Display command summary
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host "Execution Summary" -ForegroundColor Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host ""
Write-Host "Command executed:" -ForegroundColor Green
Write-Host "  .\backup-config.ps1 -OutputPath $OutputPath" -ForegroundColor Yellow
Write-Host ""
Write-Host "To run this command again:" -ForegroundColor Green
Write-Host "  cd $repoBase\scripts\win && .\backup-config.ps1" -ForegroundColor Yellow
Write-Host ""
Write-Host "Schedule with Task Scheduler (weekly on Sunday):" -ForegroundColor Green
Write-Host "  schtasks /create /tn `"Backup Silo Config`" /tr `"powershell -File '$PSCommandPath' -NonInteractive`" /sc weekly /d SUN /st 00:00" -ForegroundColor Yellow
Write-Host ""
