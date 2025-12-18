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

$script:repoBase = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)

# Information hashtable
$script:Info = @{}
$script:Failures = 0
$script:AvailableModes = @()
$script:IsAdmin = $false
$script:ContainerEngineNotRunning = $false

function Write-TestResult {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('Pass', 'Fail', 'Info', 'Warn')]
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

    # Set color and symbol based on status
    $colorName = switch ($Status) {
        'Pass' {
            'Green'
            $symbol = "+"
        }
        'Fail' {
            $script:Failures++
            'Red'
            $symbol = "X"
        }
        'Warn' {
            'Yellow'
            $symbol = "!"
        }
        'Info' {
            'White'
            $symbol = "-"
        }
    }

    # Fixed-width alignment at column 50
    # Format: [symbol]  [message with padding]: [value]
    $width = 50 - 4 - 2  # 50 - " X  " - ": "

    if ($Value) {
        $paddedMessage = $Message.PadRight($width)
        Write-Host -ForegroundColor $colorName " $symbol  ${paddedMessage}: $Value"
    } else {
        Write-Host -ForegroundColor $colorName " $symbol  $Message"
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
        Write-Host "`n========================================" -ForegroundColor Cyan
        Write-Host "  $Title" -ForegroundColor Cyan
        Write-Host "========================================" -ForegroundColor Cyan
    } else {
        Write-Host "`n=== $Title ===" -ForegroundColor Cyan
    }
}

function Test-IsAdministrator {
    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    return $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
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
    Write-SectionHeader "Python Mode Availability"

    try {
        $pythonVersion = & python --version 2>&1
        if ($pythonVersion -match 'Python\s+(\d+)\.') {
            $majorVersion = [int]$Matches[1]
            if ($majorVersion -ge 3) {
                Write-TestResult -Status Pass -Message "Python 3 is installed, Version" -Value $pythonVersion -InfoName 'pyver'
                $script:AvailableModes += "Python"
                return $true
            } else {
                Write-TestResult -Status Fail -Message "Python 3 is required, found Python" -Value $majorVersion -InfoName 'pyver'
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
    $requirementsPath = join-path $script:repoBase "app\requirements.txt"
    

    if (-not (Test-Path $requirementsPath)) {
        Write-TestResult -Status Fail -Message "requirements.txt not found at $requirementsPath"
        return $false
    }

    try {
        # Try to get pip list
        $pipList = python -m pip list --format=json 2>$null | ConvertFrom-Json 
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
            Write-TestResult -Status Warn -Message "Missing packages: $($missingPackages -join ', ')"
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
    Write-SectionHeader "Container Mode Availability"

    try {
        $VirtOn = (get-ciminstance Win32_Processor).VirtualizationFirmwareEnabled

        if ($VirtOn) {
            Write-TestResult -Status Pass -Message "Virtualization is enabled in BIOS/UEFI"
            return $true
        } else {
            Write-TestResult -Status Warn -Message "Virtualization is NOT enabled in BIOS/UEFI"
            return $false
        }
    } catch {
        # Fallback: Check Hyper-V feature
        $hyperV = Get-WindowsOptionalFeature -FeatureName Microsoft-Hyper-V-All -Online -ErrorAction SilentlyContinue
        if ($hyperV -and $hyperV.State -eq 'Enabled') {
            Write-TestResult -Status Pass -Message "Virtualization appears to be enabled (Hyper-V detected)"
            return $true
        } else {
            Write-TestResult -Status Warn -Message "Unable to confirm virtualization status"
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
    $script:DockerFound = $false
    $script:RancherFound = $false

    # Check for Rancher Desktop (preferred) - check for actual application installation
    $rancherExePath = "${env:ProgramFiles}\Rancher Desktop\Rancher Desktop.exe"
    if (Test-Path $rancherExePath) {
        $script:RancherFound = $true
        # Try to get version from rdctl if available
        $rancherCmd = Get-Command rdctl -ErrorAction SilentlyContinue
        if ($rancherCmd) {
            try {
                $rancherVersion = & rdctl version 2>&1
                if ($rancherVersion) {
                    $script:Info['rancher_version'] = $rancherVersion
                    Write-TestResult -Status Pass -Message "Rancher Desktop is installed, Version" -Value $rancherVersion -InfoName 'container_engine' -InfoValue "Rancher Desktop"
                }
            } catch {
                Write-TestResult -Status Pass -Message "Rancher Desktop is installed" -InfoName 'container_engine' -InfoValue "Rancher Desktop"
            }
        } else {
            Write-TestResult -Status Pass -Message "Rancher Desktop is installed" -InfoName 'container_engine' -InfoValue "Rancher Desktop"
        }
    }

    # Check for Docker Desktop - check for actual application installation
    $dockerExePath = "${env:ProgramFiles}\Docker\Docker\Docker Desktop.exe"
    if (Test-Path $dockerExePath) {
        $script:DockerFound = $true
        # Get Docker version
        $dockerCmd = Get-Command docker -ErrorAction SilentlyContinue
        if ($dockerCmd) {
            try {
                $dockerVersion = & docker --version 2>&1
                if ($dockerVersion -match "version\s+([\d\.]+)") {
                    $script:Info['docker_version'] = $Matches[1]
                    # Only report Docker Desktop if Rancher wasn't found (prefer Rancher)
                    if (-not $script:RancherFound) {
                        Write-TestResult -Status Pass -Message "Docker Desktop is installed, Version" -Value $Matches[1] -InfoName 'container_engine' -InfoValue "Docker Desktop"
                    } else {
                        Write-TestResult -Status Info -Message "Docker Desktop is also installed, Version" -Value $Matches[1]
                    }
                }
            } catch {
                if (-not $script:RancherFound) {
                    Write-TestResult -Status Pass -Message "Docker Desktop is installed" -InfoName 'container_engine' -InfoValue "Docker Desktop"
                } else {
                    Write-TestResult -Status Info -Message "Docker Desktop is also installed"
                }
            }
        } else {
            if (-not $script:RancherFound) {
                Write-TestResult -Status Pass -Message "Docker Desktop is installed" -InfoName 'container_engine' -InfoValue "Docker Desktop"
            } else {
                Write-TestResult -Status Info -Message "Docker Desktop is also installed"
            }
        }
    }

    if (-not $script:DockerFound -and -not $script:RancherFound) {
        Write-TestResult -Status Fail -Message "No container runtime (Docker Desktop or Rancher Desktop) found"
        return $false
    }

    return $true
}

function Test-ContainerEngineRunning {
    try {
        # Test if Docker daemon is running
        $dockerInfo = & docker info -f json 2>&1
        if ($dockerInfo -match "Access is denied.") {
            Write-TestResult -Status Warn -Message "Container engine running, but access is denied. Run the script as Administrator."
            return $false
        } 

        if ($LASTEXITCODE -eq 0) {
            Write-TestResult -Status Pass -Message "Container engine is running"

            # Add to available modes based on which runtime was found
            if ($script:DockerFound) {
                $script:AvailableModes += "Container (Docker Desktop)"
            }
            if ($script:RancherFound) {
                $script:AvailableModes += "Container (Rancher Desktop)"
            }

            return $true
        } else {
            Write-TestResult -Status Fail -Message "Container engine is not running"
            $script:ContainerEngineNotRunning = $true
            return $false
        }
    } catch {
        Write-TestResult -Status Fail -Message "Unable to check container engine status"
        $script:ContainerEngineNotRunning = $true
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

# Check admin permissions
$script:IsAdmin = Test-IsAdministrator
if ($script:IsAdmin) {
    Write-TestResult -Status Info -Message "Running with Administrator privileges"
} else {
    Write-TestResult -Status Info -Message "Running without Administrator privileges"
}

# General checks (always run)
Test-WindowsVersion
Test-PowerShellVersion

# Python mode checks
if ($Mode -eq 'Python' -or $Mode -eq 'All') {
    $pythonInstalled = Test-PythonInstalled
    if ($pythonInstalled) {
        Test-PythonInPath | out-null
        Test-PythonRequirements | out-null
    }
}

# Container mode checks
if ($Mode -eq 'Container' -or $Mode -eq 'All') {
    Test-VirtualizationEnabled | out-null
    Test-WSLInstalled | out-null
    $runtimeInstalled = Test-ContainerRuntime

    if ($runtimeInstalled) {
        $engineRunning = Test-ContainerEngineRunning
        Test-ContainerEngineInfo
    }
}

# Summary Section
Write-SectionHeader -Title "Summary" -Major

Write-SectionHeader -Title "Available  Modes"
if ($script:AvailableModes.Count -eq 0) {
    Write-Host -ForegroundColor Yellow "  No usable modes detected"
    Write-Host -ForegroundColor Yellow "  You may need to install Python 3 or a container runtime (Docker/Rancher Desktop)"
} else {
    foreach ($mode in $script:AvailableModes) {
        Write-Host -ForegroundColor Green " + $mode"
    }
}

if ($script:Failures -gt 0) {
    Write-Host ""
    Write-Host -ForegroundColor Red "=========================================="
    Write-Host -ForegroundColor Red "You have $($script:Failures) failure(s)."
    Write-Host -ForegroundColor Red "Please review the issues above."
    Write-Host -ForegroundColor Red "=========================================="
    Write-Host ""
    Write-Host "Review the documentation here:"
    Write-Host "https://gitlab.com/breakwaterlabs/silo-log-pull/-/tree/main/docs"
} else {
    Write-Host ""
    Write-Host -ForegroundColor Green "=========================================="
    Write-Host -ForegroundColor Green "All checks completed successfully!"
    Write-Host -ForegroundColor Green "=========================================="
}

# Handle container engine not running
if ($script:ContainerEngineNotRunning) {
    $fixScriptPath = Join-Path $PSScriptRoot "fix-container-engine.ps1"
    & $fixScriptPath -DockerFound $script:DockerFound -RancherFound $script:RancherFound -IsAdmin $script:IsAdmin
}