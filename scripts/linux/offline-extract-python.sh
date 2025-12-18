#!/usr/bin/env bash

#==============================================================================
# Offline Python Package Extraction Script
#==============================================================================

set -e

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
RESET='\033[0m'

# Parse arguments
DO_INSTALL=false
DO_RUN=false
CONFIGURE_DATA_DIR=true

while [[ $# -gt 0 ]]; do
    case $1 in
        --install)
            DO_INSTALL=true
            shift
            ;;
        --run)
            DO_RUN=true
            shift
            ;;
        --no-configure)
            CONFIGURE_DATA_DIR=false
            shift
            ;;
        *)
            echo -e "${RED}Unknown option: $1${RESET}"
            echo "Usage: $0 [--install] [--run] [--no-configure]"
            echo "  --install       Install dependencies only"
            echo "  --run           Run script only (assumes already installed)"
            echo "  --no-configure  Skip data directory configuration"
            echo "  (no flags)      Install only"
            exit 1
            ;;
    esac
done

# Default: do install if no flags specified
if [ "$DO_INSTALL" = false ] && [ "$DO_RUN" = false ]; then
    DO_INSTALL=true
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"
APP_DIR="${REPO_DIR}/app"
VENV_DIR="${APP_DIR}/venv"

if [ "$DO_INSTALL" = true ]; then
    echo -e "${CYAN}=======================================${RESET}"
    echo -e "${CYAN}  silo-log-pull Offline Setup${RESET}"
    echo -e "${CYAN}=======================================${RESET}"
    echo ""

    # Check if Python 3 is installed
    if ! command -v python3 >/dev/null 2>&1; then
        echo -e "${RED}Error: Python 3 is not installed${RESET}"
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
    pip install --upgrade pip --quiet

    echo -e "${GREEN}Installing dependencies from offline packages...${RESET}"
    pip install --no-index --find-links "${APP_DIR}/silo-dependencies" -r "${APP_DIR}/requirements.txt"

    echo ""
    echo -e "${GREEN}============================================${RESET}"
    echo -e "${GREEN}Installation complete!${RESET}"
    echo -e "${GREEN}============================================${RESET}"
    echo ""

    # Configure data directory
    if [ "$CONFIGURE_DATA_DIR" = true ]; then
        echo -e "${CYAN}Data Directory Configuration${RESET}"
        echo -e "${CYAN}----------------------------${RESET}"
        echo ""
        echo "Where would you like to store configuration files and logs?"
        echo ""
        echo "  [1] Default location (${APP_DIR}/data/)"
        echo "  [2] Custom location"
        echo ""
        echo -n "Choice [1-2]: "
        read -r choice

        case $choice in
            2)
                echo ""
                echo -n "Enter full path for data directory: "
                read -r custom_path

                # Expand tilde and environment variables
                custom_path=$(eval echo "$custom_path")

                # Validate or create directory
                if [ ! -d "$custom_path" ]; then
                    echo ""
                    echo -e "${YELLOW}Directory does not exist: $custom_path${RESET}"
                    echo -n "Create it now? [Y/n]: "
                    read -r create
                    if [ -z "$create" ] || [ "$create" = "Y" ] || [ "$create" = "y" ]; then
                        mkdir -p "$custom_path"
                        echo -e "${GREEN}Created: $custom_path${RESET}"
                    else
                        echo -e "${RED}Cannot continue without data directory${RESET}"
                        exit 1
                    fi
                fi

                # Create subdirectories
                mkdir -p "${custom_path}/logs"
                mkdir -p "${custom_path}/logs_out"

                # Write data_dir.txt
                echo "$custom_path" > "${APP_DIR}/data_dir.txt"
                echo ""
                echo -e "${GREEN}Data directory configured: $custom_path${RESET}"
                echo -e "${GRAY}(Saved to ${APP_DIR}/data_dir.txt)${RESET}"
                ;;
            *)
                echo ""
                echo -e "${GREEN}Using default data directory: ${APP_DIR}/data/${RESET}"
                ;;
        esac
        echo ""
    fi
fi

if [ "$DO_RUN" = true ]; then
    if [ ! -d "${VENV_DIR}" ]; then
        echo -e "${RED}Error: Virtual environment not found${RESET}"
        echo "Please run with --install first"
        exit 1
    fi

    echo -e "${CYAN}Running silo-log-pull...${RESET}"
    echo ""
    source "${VENV_DIR}/bin/activate"
    cd "${APP_DIR}"
    python silo_batch_pull.py
else
    echo "To run silo-log-pull:"
    echo "  cd ${APP_DIR}"
    echo "  source venv/bin/activate"
    echo "  python silo_batch_pull.py"
    echo ""
    echo "Or use: ${SCRIPT_DIR}/$(basename "${BASH_SOURCE[0]}") --run"
    echo ""
    echo "See the docs/ directory for complete documentation."
fi
