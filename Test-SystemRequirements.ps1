#Requires -Version 5.1

<#
.SYNOPSIS
    Tests system requirements for the silo-log-pull application.

.DESCRIPTION
    This script checks system requirements for both Python mode and Container mode deployments.
    It provides visual feedback with checkmarks/X marks and collects informational data.

.PARAMETER Mode
    The deployment mode to test: 'Python', 'Container', or 'All' (default).

.EXAMPLE
    .\Test-SystemRequirements.ps1
    Tests all requirements for both deployment modes.

.EXAMPLE
    .\Test-SystemRequirements.ps1 -Mode Python
    Tests only Python mode requirements.
#>

[CmdletBinding()]
param(
    [Parameter()]
    [ValidateSet('Python', 'Container', 'All')]
    [string]$Mode = 'All'
)

# Information hashtable
$script:Info = @{}
$script:Failures = 0

function Write-TestResult {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('Pass', 'Fail', 'Info')]
        [string]$Status,

        [Parameter(Mandatory)]
        [string]$Message,

        [Parameter()]
        [string]$Value,

        [Parameter()]
        [string]$InfoName,

        [Parameter()]
        [string]$InfoValue
    )

    # Store in info hashtable if InfoName is provided
    if ($InfoName) {
        $valueToStore = if ($InfoValue) { $InfoValue } else { $Value }
        $script:Info[$InfoName] = $valueToStore
    }

    # ANSI color codes
    $Green = "`e[32m"
    $Red = "`e[31m"
    $Blue = "`e[34m"
    $Yellow = "`e[33m"
    $Reset = "`e[0m"

    # Unicode symbols
    $CheckMark = [char]0x2713  # ✓
    $XMark = [char]0x2717      # ✗
    $InfoMark = [char]0x2139   # ℹ

    $symbol = switch ($Status) {
        'Pass' { "$Green$CheckMark$Reset" }
        'Fail' { 
            "$Red$XMark$Reset"
            $script:Failures++ 
        }
        'Info' { "$Blue$InfoMark$Reset" }
    }

    if ($Value) {
        Write-Host "$symbol $Message`: $Yellow$Value$Reset"
    } else {
        Write-Host "$symbol $Message"
    }
}

function Write-SectionHeader {
    param(
        [Parameter(Mandatory)]
        [string]$Title,

        [Parameter()]
        [switch]$Major
    )

    if ($Major) {
        Write-Host "`n========================================" -ForegroundColor Blue
        Write-Host "  $Title" -ForegroundColor Blue
        Write-Host "========================================" -ForegroundColor Blue
    } else {
        Write-Host "`n=== $Title ===" -ForegroundColor Blue
    }
}

# ============================================================================
# General System Checks
# ============================================================================

function Test-WindowsVersion {
    Write-SectionHeader "General System Information"

    try {
        $os = Get-CimInstance Win32_OperatingSystem
        $version = $os.Caption
        $build = $os.BuildNumber
        $winver = "$version (Build $build)"

        Write-TestResult -Status Info -Message "Windows Version" -Value $winver -InfoName 'winver'
    } catch {
        Write-TestResult -Status Fail -Message "Unable to detect Windows version"
    }
}

function Test-PowerShellVersion {
    try {
        $psVersion = $PSVersionTable.PSVersion.ToString()

        Write-TestResult -Status Info -Message "PowerShell Version" -Value $psVersion -InfoName 'psver'
    } catch {
        Write-TestResult -Status Fail -Message "Unable to detect PowerShell version"
    }
}

# ============================================================================
# Python Mode Checks
# ============================================================================

function Test-PythonInstalled {
    Write-SectionHeader "Python Mode Requirements"

    try {
        $pythonVersion = & python --version 2>&1
        if ($pythonVersion -match 'Python\s+(\d+)\.') {
            $majorVersion = [int]$Matches[1]
            if ($majorVersion -ge 3) {
                Write-TestResult -Status Info -Message "Python 3 is installed, Version" -Value $pythonVersion -InfoName 'pyver'
                return $true
            } else {
                Write-TestResult -Status Fail -Message "Python 3 is required, found python" -value $majorVersion -InfoName 'pyver'
                return $false
            }
        }
    } catch {
        Write-TestResult -Status Fail -Message "Python 3 is not installed (or missing from PATH)"
        return $false
    }
}

function Test-PythonInPath {
    try {
        $pythonCmd = Get-Command python -ErrorAction Stop
        $pythonPath = Split-Path $pythonCmd.Source

        if ($env:PATH -like "*$pythonPath*") {
            Write-TestResult -Status Pass -Message "PATH includes Python binary location"
            return $true
        } else {
            Write-TestResult -Status Fail -Message "Python binary location not properly in PATH"
            return $false
        }
    } catch {
        Write-TestResult -Status Fail -Message "Python binary not found in PATH"
        return $false
    }
}

function Test-PythonRequirements {
    $requirementsPath = Join-Path $PSScriptRoot "app\requirements.txt"

    if (-not (Test-Path $requirementsPath)) {
        Write-TestResult -Status Fail -Message "requirements.txt not found at $requirementsPath"
        return $false
    }

    try {
        # Try to get pip list
        $pipList = & python -m pip list --format=json 2>&1 | ConvertFrom-Json
        $installedPackages = @{}
        foreach ($pkg in $pipList) {
            $installedPackages[$pkg.name.ToLower()] = $pkg.version
        }

        # Parse requirements.txt
        $requirements = Get-Content $requirementsPath
        $allMet = $true
        $missingPackages = @()

        foreach ($req in $requirements) {
            $req = $req.Trim()
            if ($req -and -not $req.StartsWith('#')) {
                # Parse package name (handle ~=, ==, >=, etc.)
                if ($req -match '^([a-zA-Z0-9\-_]+)') {
                    $packageName = $Matches[1].ToLower()

                    if (-not $installedPackages.ContainsKey($packageName)) {
                        $missingPackages += $packageName
                        $allMet = $false
                    }
                }
            }
        }

        if ($allMet) {
            Write-TestResult -Status Pass -Message "All requirements.txt dependencies are met"
            return $true
        } else {
            Write-TestResult -Status Fail -Message "Missing packages: $($missingPackages -join ', ')"
            return $false
        }
    } catch {
        Write-TestResult -Status Fail -Message "Unable to verify Python dependencies: $_"
        return $false
    }
}

# ============================================================================
# Container Mode Checks
# ============================================================================

function Test-VirtualizationEnabled {
    Write-SectionHeader "Container Mode Requirements"

    try {
        # Check if virtualization is enabled using systeminfo
        $systemInfo = systeminfo
        $virtLine = $systemInfo | Select-String "Virtualization Enabled In Firmware"

        if ($virtLine -match "Yes") {
            Write-TestResult -Status Pass -Message "Virtualization is enabled in BIOS/UEFI"
            return $true
        } else {
            Write-TestResult -Status Fail -Message "Virtualization is NOT enabled in BIOS/UEFI"
            return $false
        }
    } catch {
        # Fallback: Check Hyper-V feature
        $hyperV = Get-WindowsOptionalFeature -FeatureName Microsoft-Hyper-V-All -Online -ErrorAction SilentlyContinue
        if ($hyperV -and $hyperV.State -eq 'Enabled') {
            Write-TestResult -Status Pass -Message "Virtualization appears to be enabled (Hyper-V detected)"
            return $true
        } else {
            Write-TestResult -Status Fail -Message "Unable to confirm virtualization status"
            return $false
        }
    }
}

function Test-WSLInstalled {
    try {
        $wslVersion = & wsl --version 2>&1

        if ($LASTEXITCODE -eq 0) {
            # Store WSL version info
            $wslver = $null
            if ($wslVersion -match "WSL\s+version:\s+(.+)") {
                $wslver = $Matches[1].Trim()
            }

            if ($wslver) {
                Write-TestResult -Status Pass -Message "WSL is installed" -InfoName 'wslver' -InfoValue $wslver
            } else {
                Write-TestResult -Status Pass -Message "WSL is installed"
            }

            return $true
        } else {
            Write-TestResult -Status Fail -Message "WSL is installed but not functioning properly"
            return $false
        }
    } catch {
        Write-TestResult -Status Fail -Message "WSL is not installed"
        return $false
    }
}

function Test-ContainerRuntime {
    $dockerCmd = Get-Command docker -ErrorAction SilentlyContinue
    $rancherCmd = Get-Command rdctl -ErrorAction SilentlyContinue

    $runtimeFound = $false

    # Check Docker Desktop
    if ($dockerCmd) {
        $dockerPath = Split-Path $dockerCmd.Source
        if ($env:PATH -like "*$dockerPath*" -or $env:PATH -like "*Docker*") {
            Write-TestResult -Status Pass -Message "Docker Desktop is installed and in PATH" -InfoName 'container_engine' -InfoValue "Docker Desktop"
            $runtimeFound = $true

            # Get Docker version
            try {
                $dockerVersion = & docker --version 2>&1
                if ($dockerVersion -match "version\s+([\d\.]+)") {
                    $script:Info['docker_version'] = $Matches[1]
                }
            } catch {}
        }
    }

    # Check Rancher Desktop
    if ($rancherCmd) {
        $rancherPath = Split-Path $rancherCmd.Source
        if ($env:PATH -like "*$rancherPath*" -or $env:PATH -like "*Rancher*") {
            Write-TestResult -Status Pass -Message "Rancher Desktop is installed and in PATH" -InfoName 'container_engine' -InfoValue "Rancher Desktop"
            $runtimeFound = $true

            # Get Rancher version
            try {
                $rancherVersion = & rdctl version 2>&1
                if ($rancherVersion) {
                    $script:Info['rancher_version'] = $rancherVersion
                }
            } catch {}
        }
    }

    if (-not $runtimeFound) {
        Write-TestResult -Status Fail -Message "No container runtime (Docker Desktop or Rancher Desktop) found in PATH"
    }

    return $runtimeFound
}

function Test-ContainerEngineRunning {
    try {
        # Test if Docker daemon is running
        $dockerInfo = & docker info -f json 2>&1 

        if ($LASTEXITCODE -eq 0) {
            $dockerSummary = $dockerInfo | convertfrom-json | Select-Object `
            @{n="engine";e={$_.operatingsystem}},`
            @{n="Arch";e={$_.architecture}},`
            @{n="runtime";e={$_.DefaultRuntime}},`
            @{n="kernel";e={$_.kernelVersion}}

            Write-TestResult -Status Pass -Message "Container engine is running" -InfoName docker_daemon -Value $dockerSummary
            return $true
        } else {
            Write-TestResult -Status Fail -Message "Container engine is not running"
            return $false
        }
    } catch {
        Write-TestResult -Status Fail -Message "Unable to check container engine status"
        return $false
    }
}

function Test-ContainerEngineInfo {
    # Display which container engine is in use
    if ($script:Info.ContainsKey('container_engine')) {
        $engineInfo = $script:Info['container_engine']

        if ($script:Info.ContainsKey('docker_version')) {
            $engineInfo += " v$($script:Info['docker_version'])"
        } elseif ($script:Info.ContainsKey('rancher_version')) {
            $engineInfo += " $($script:Info['rancher_version'])"
        }

        Write-TestResult -Status Info -Message "Container Engine" -Value $engineInfo
    }

    # Display WSL version
    if ($script:Info.ContainsKey('wslver')) {
        Write-TestResult -Status Info -Message "WSL Version" -Value $script:Info['wslver']
    }
}

# ============================================================================
# Main Execution
# ============================================================================

Write-SectionHeader -Title "System Requirements Check" -Major

# General checks (always run)
Test-WindowsVersion
Test-PowerShellVersion

# Python mode checks
if ($Mode -eq 'Python' -or $Mode -eq 'All') {
    $pythonInstalled = Test-PythonInstalled
    if ($pythonInstalled) {
        Test-PythonInPath
        Test-PythonRequirements
    }
}

# Container mode checks
if ($Mode -eq 'Container' -or $Mode -eq 'All') {
    Test-VirtualizationEnabled | out-null
    Test-WSLInstalled
    $runtimeInstalled = Test-ContainerRuntime

    if ($runtimeInstalled) {
        $engineRunning = Test-ContainerEngineRunning
        Test-ContainerEngineInfo
    }
}

# Return the info hashtable for scripting purposes
Write-SectionHeader -Title Summary -major 
$script:Info

if ($script:Failures -gt 0) {
    write-host -ForegroundColor red "--- You have one or more failures.  ---"
    write-host -ForegroundColor red "--- Please review the issues above. ---"
    write-host -ForegroundColor red "Review the documentation here: `n https://gitlab.com/breakwaterlabs/silo-log-pull/-/tree/main/docs"
}