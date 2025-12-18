#Requires -Version 5.1

<#
.SYNOPSIS
    Updates the repository via git pull.

.DESCRIPTION
    Performs git pull to update the repository to the latest version.
    Includes checks for uncommitted changes and provides detailed error handling.

.PARAMETER NonInteractive
    Run without prompts for automated/scheduled execution.

.EXAMPLE
    .\update-git-repo.ps1
    Runs interactively, prompting for confirmation if there are uncommitted changes.

.EXAMPLE
    .\update-git-repo.ps1 -NonInteractive
    Runs silently without prompts, suitable for scheduled tasks.
#>

[CmdletBinding()]
param(
    [Parameter()]
    [switch]$NonInteractive
)

$repoBase = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "  Update Repository via Git" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

# Check if git is installed
try {
    $null = & git --version 2>&1
} catch {
    Write-Host "Error: Git is not installed" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please install git first:"
    Write-Host "  Download from: https://git-scm.com/download/win"
    exit 1
}

# Check if we're in a git repository
Push-Location $repoBase
try {
    $null = & git rev-parse --git-dir 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Error: Not a git repository" -ForegroundColor Red
        Write-Host ""
        Write-Host "This directory does not appear to be a git repository."
        Write-Host "Repository updates via git are only available for git clones."
        exit 1
    }
} catch {
    Write-Host "Error: Not a git repository" -ForegroundColor Red
    exit 1
}

# Check for uncommitted changes
try {
    & git diff-index --quiet HEAD -- 2>&1 | Out-Null
    $hasChanges = $LASTEXITCODE -ne 0

    if ($hasChanges) {
        Write-Host "Warning: You have uncommitted changes" -ForegroundColor Yellow
        Write-Host ""
        & git status --short
        Write-Host ""

        if (-not $NonInteractive) {
            $response = Read-Host "Continue with update? This may cause conflicts. [y/N]"
            if ($response -ne 'y' -and $response -ne 'Y') {
                Write-Host "Update cancelled" -ForegroundColor Yellow
                Pop-Location
                exit 0
            }
        } else {
            Write-Host "Non-interactive mode: Continuing despite uncommitted changes" -ForegroundColor Yellow
        }
    }
} catch {
    # If diff-index fails, continue anyway
}

# Get current branch
$currentBranch = & git rev-parse --abbrev-ref HEAD 2>&1
Write-Host "Current branch: $currentBranch" -ForegroundColor Cyan

# Get remote info
try {
    $remoteUrl = & git remote get-url origin 2>&1
    if ($LASTEXITCODE -ne 0) {
        $remoteUrl = "No remote configured"
    }
} catch {
    $remoteUrl = "No remote configured"
}
Write-Host "Remote: $remoteUrl" -ForegroundColor Cyan
Write-Host ""

# Perform git fetch
Write-Host "Fetching latest changes..." -ForegroundColor Green
try {
    $fetchOutput = & git fetch origin 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Host ""
        Write-Host "Error: Failed to fetch from remote" -ForegroundColor Red
        Write-Host ""
        Write-Host "Possible issues:"
        Write-Host "  - No network connection"
        Write-Host "  - Authentication required"
        Write-Host "  - Remote repository not accessible"
        Pop-Location
        exit 1
    }
} catch {
    Write-Host "Error: Failed to fetch: $_" -ForegroundColor Red
    Pop-Location
    exit 1
}

# Check if there are updates available
$local = & git rev-parse @ 2>&1
$remote = & git rev-parse '@{u}' 2>&1
$remoteSuccess = $LASTEXITCODE -eq 0

if (-not $remoteSuccess) {
    Write-Host "Warning: No upstream branch configured" -ForegroundColor Yellow
    Write-Host "Cannot determine if updates are available"
    Pop-Location
    exit 1
}

$base = & git merge-base @ '@{u}' 2>&1

if ($local -eq $remote) {
    Write-Host "Already up to date!" -ForegroundColor Green
    Pop-Location
    exit 0
} elseif ($local -eq $base) {
    # Need to pull
    Write-Host "Updates available, pulling changes..." -ForegroundColor Green
    Write-Host ""

    $pullOutput = & git pull origin $currentBranch 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host ""
        Write-Host "============================================" -ForegroundColor Green
        Write-Host "Repository updated successfully!" -ForegroundColor Green
        Write-Host "============================================" -ForegroundColor Green
        Write-Host ""
        Write-Host "Updated to latest version on branch: $currentBranch"

        # Display command summary
        Write-Host ""
        Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
        Write-Host "Execution Summary" -ForegroundColor Cyan
        Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "Command executed:" -ForegroundColor Green
        Write-Host "  cd $repoBase && git pull origin $currentBranch" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "To run this command again:" -ForegroundColor Green
        Write-Host "  cd $repoBase && git pull" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Schedule with Task Scheduler (weekly on Sunday at midnight):" -ForegroundColor Green
        Write-Host "  schtasks /create /tn `"Update Silo Log Pull`" /tr `"powershell -File '$PSCommandPath' -NonInteractive`" /sc weekly /d SUN /st 00:00" -ForegroundColor Yellow
        Write-Host ""

        Pop-Location
        exit 0
    } else {
        Write-Host ""
        Write-Host "Error: Failed to pull changes" -ForegroundColor Red
        Write-Host ""
        Write-Host "There may be merge conflicts. Please resolve manually:"
        Write-Host "  git status"
        Write-Host "  git merge --abort  (to cancel the merge)"
        Pop-Location
        exit 1
    }
} elseif ($remote -eq $base) {
    Write-Host "Local branch is ahead of remote" -ForegroundColor Yellow
    Write-Host "You have local commits that haven't been pushed"
    Pop-Location
    exit 0
} else {
    Write-Host "Branches have diverged" -ForegroundColor Yellow
    Write-Host "Your local branch and the remote branch have different changes"
    Write-Host "Manual intervention required - consider git pull --rebase or merge"
    Pop-Location
    exit 1
}
