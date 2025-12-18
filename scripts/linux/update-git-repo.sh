#!/usr/bin/env bash

#==============================================================================
# Update Repository via Git
#==============================================================================
# Performs git pull to update the repository to latest version
#
# Usage:
#   ./update-git-repo.sh [--non-interactive]

set -e

REPOBASE="$(cd "$(dirname "${BASH_SOURCE[0]}")"/../.. && pwd)"
NON_INTERACTIVE=false

# ANSI color codes
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
RESET='\033[0m'

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --non-interactive)
            NON_INTERACTIVE=true
            shift
            ;;
        *)
            echo -e "${RED}Unknown option: $1${RESET}"
            echo "Usage: $0 [--non-interactive]"
            exit 1
            ;;
    esac
done

echo -e "${CYAN}=======================================${RESET}"
echo -e "${CYAN}  Update Repository via Git${RESET}"
echo -e "${CYAN}=======================================${RESET}"
echo ""

# Check if git is installed
if ! command -v git >/dev/null 2>&1; then
    echo -e "${RED}Error: Git is not installed${RESET}"
    echo ""
    echo "Please install git first:"
    echo "  Ubuntu/Debian: sudo apt install git"
    echo "  RHEL/CentOS:   sudo dnf install git"
    exit 1
fi

# Check if we're in a git repository
cd "${REPOBASE}"
if ! git rev-parse --git-dir >/dev/null 2>&1; then
    echo -e "${RED}Error: Not a git repository${RESET}"
    echo ""
    echo "This directory does not appear to be a git repository."
    echo "Repository updates via git are only available for git clones."
    exit 1
fi

# Check for uncommitted changes
if ! git diff-index --quiet HEAD -- 2>/dev/null; then
    echo -e "${YELLOW}Warning: You have uncommitted changes${RESET}"
    echo ""
    git status --short
    echo ""

    if [ "$NON_INTERACTIVE" = false ]; then
        echo -n "Continue with update? This may cause conflicts. [y/N]: "
        read -r response
        if [ "$response" != "y" ] && [ "$response" != "Y" ]; then
            echo -e "${YELLOW}Update cancelled${RESET}"
            exit 0
        fi
    else
        echo -e "${YELLOW}Non-interactive mode: Continuing despite uncommitted changes${RESET}"
    fi
fi

# Get current branch
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
echo -e "${CYAN}Current branch: ${CURRENT_BRANCH}${RESET}"

# Get remote info
REMOTE_URL=$(git remote get-url origin 2>/dev/null || echo "No remote configured")
echo -e "${CYAN}Remote: ${REMOTE_URL}${RESET}"
echo ""

# Perform git fetch
echo -e "${GREEN}Fetching latest changes...${RESET}"
if ! git fetch origin 2>&1; then
    echo ""
    echo -e "${RED}Error: Failed to fetch from remote${RESET}"
    echo ""
    echo "Possible issues:"
    echo "  - No network connection"
    echo "  - Authentication required"
    echo "  - Remote repository not accessible"
    exit 1
fi

# Check if there are updates available
LOCAL=$(git rev-parse @)
REMOTE=$(git rev-parse @{u} 2>/dev/null || echo "")
BASE=$(git merge-base @ @{u} 2>/dev/null || echo "")

if [ -z "$REMOTE" ]; then
    echo -e "${YELLOW}Warning: No upstream branch configured${RESET}"
    echo "Cannot determine if updates are available"
    exit 1
elif [ "$LOCAL" = "$REMOTE" ]; then
    echo -e "${GREEN}Already up to date!${RESET}"
    exit 0
elif [ "$LOCAL" = "$BASE" ]; then
    # Need to pull
    echo -e "${GREEN}Updates available, pulling changes...${RESET}"
    echo ""

    if git pull origin "${CURRENT_BRANCH}" 2>&1; then
        echo ""
        echo -e "${GREEN}============================================${RESET}"
        echo -e "${GREEN}Repository updated successfully!${RESET}"
        echo -e "${GREEN}============================================${RESET}"
        echo ""
        echo "Updated to latest version on branch: ${CURRENT_BRANCH}"

        # Display command summary
        echo ""
        echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
        echo -e "${CYAN}Execution Summary${RESET}"
        echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
        echo ""
        echo -e "${GREEN}Command executed:${RESET}"
        echo -e "  ${YELLOW}cd ${REPOBASE} && git pull origin ${CURRENT_BRANCH}${RESET}"
        echo ""
        echo -e "${GREEN}To run this command again:${RESET}"
        echo -e "  ${YELLOW}cd ${REPOBASE} && git pull${RESET}"
        echo ""
        echo -e "${GREEN}Schedule with cron (weekly on Sunday at midnight):${RESET}"
        echo -e "  ${YELLOW}0 0 * * 0 cd ${REPOBASE} && git pull${RESET}"
        echo ""

        exit 0
    else
        echo ""
        echo -e "${RED}Error: Failed to pull changes${RESET}"
        echo ""
        echo "There may be merge conflicts. Please resolve manually:"
        echo "  git status"
        echo "  git merge --abort  (to cancel the merge)"
        exit 1
    fi
elif [ "$REMOTE" = "$BASE" ]; then
    echo -e "${YELLOW}Local branch is ahead of remote${RESET}"
    echo "You have local commits that haven't been pushed"
    exit 0
else
    echo -e "${YELLOW}Branches have diverged${RESET}"
    echo "Your local branch and the remote branch have different changes"
    echo "Manual intervention required - consider git pull --rebase or merge"
    exit 1
fi
