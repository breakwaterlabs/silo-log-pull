#!/usr/bin/env pwsh

<#
.SYNOPSIS
    Get log directory details for offline bundling
.DESCRIPTION
    Returns objects with log directory information including file counts and paths
.OUTPUTS
    PSCustomObject[] - Array of objects with FileCount, Path, and Exists properties
#>

function Get-DataDir {
    $scriptBase = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    $dataDirFile = Join-Path $scriptBase "app\data_dir.txt"

    if (Test-Path $dataDirFile) {
        $dataDirPath = (Get-Content $dataDirFile -First 1).Trim()
        if ($dataDirPath -and (Test-Path $dataDirPath -PathType Container)) {
            return $dataDirPath
        }
    }
    return Join-Path $scriptBase "app\data"
}

function Get-LogDirectories {
    param($DataDir)

    $configFile = Join-Path $DataDir "silo_config.json"
    $logIn = "logs"
    $logOut = "logs"

    if (Test-Path $configFile) {
        try {
            $config = Get-Content $configFile | ConvertFrom-Json
            if ($config.log_in_directory) { $logIn = $config.log_in_directory }
            if ($config.log_out_directory) { $logOut = $config.log_out_directory }
        } catch {
            # If config parsing fails, use defaults
        }
    }

    # Resolve relative paths
    if (-not [System.IO.Path]::IsPathRooted($logIn)) {
        $logIn = Join-Path $DataDir $logIn
    }
    if (-not [System.IO.Path]::IsPathRooted($logOut)) {
        $logOut = Join-Path $DataDir $logOut
    }

    return @{
        LogIn = $logIn
        LogOut = $logOut
    }
}

function Get-LogDirectoryInfo {
    param($Path)

    $exists = Test-Path $Path -PathType Container
    $fileCount = if ($exists) {
        (Get-ChildItem -Path $Path -File -Depth 0 -ErrorAction SilentlyContinue | Measure-Object).Count
    } else {
        $null
    }

    return [PSCustomObject]@{
        Path = $Path
        FileCount = $fileCount
        Exists = $exists
    }
}

# Main execution
$dataDir = Get-DataDir
$logDirs = Get-LogDirectories -DataDir $dataDir

# Return array of log directory info objects
@(
    (Get-LogDirectoryInfo -Path $logDirs.LogIn),
    (Get-LogDirectoryInfo -Path $logDirs.LogOut)
)
