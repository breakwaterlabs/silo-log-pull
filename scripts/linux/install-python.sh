#!/usr/bin/env bash

#==============================================================================
# Install Python Dependencies (Virtual Environment)
#==============================================================================

set -e

REPOBASE="$(cd "$(dirname "${BASH_SOURCE[0]}")"/../.. && pwd)"
APP_DIR="${REPOBASE}/app"
VENV_DIR="${APP_DIR}/venv"

# ANSI color codes
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
RESET='\033[0m'

# Check if Python 3 is installed
if ! command -v python3 >/dev/null 2>&1; then
    echo -e "${RED}Error: Python 3 is not installed or not in PATH${RESET}"
    echo ""
    echo "Please install Python 3 first:"
    echo "  Ubuntu/Debian: sudo apt install python3 python3-pip python3-venv python3-dev gcc libgmp-dev"
    echo "  RHEL/CentOS:   sudo dnf install python3 python3-pip python3-devel gcc gmp-devel"
    exit 1
fi

echo -e "${GREEN}Creating virtual environment...${RESET}"
python3 -m venv "${VENV_DIR}"

echo -e "${GREEN}Activating virtual environment...${RESET}"
source "${VENV_DIR}/bin/activate"

echo -e "${GREEN}Upgrading pip...${RESET}"
pip install --upgrade pip

echo -e "${GREEN}Installing dependencies from requirements.txt...${RESET}"
pip install -r "${APP_DIR}/requirements.txt"

echo ""
echo -e "${GREEN}============================================${RESET}"
echo -e "${GREEN}Installation complete!${RESET}"
echo -e "${GREEN}============================================${RESET}"
echo ""
echo "To run silo-log-pull:"
echo "  cd ${APP_DIR}"
echo "  source venv/bin/activate"
echo "  python silo_batch_pull.py"
echo ""
echo "To deactivate the virtual environment when done:"
echo "  deactivate"
