#!/usr/bin/env bash

#==============================================================================
# silo-log-pull Setup Script for Linux/macOS
#==============================================================================
# This script provides a menu-driven interface for managing silo-log-pull
# deployment options including Python and container-based setups.
#
# Usage: ./setup.sh

set -e

REPOBASE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS_DIR="${REPOBASE}/scripts/linux"

# ANSI color codes
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
RESET='\033[0m'

show_header() {
    clear
    echo -e "${CYAN}=======================================${RESET}"
    echo -e "${CYAN}  silo-log-pull Setup Menu${RESET}"
    echo -e "${CYAN}=======================================${RESET}"
    echo ""
}

show_menu() {
    show_header
    echo "1. Run systems test"
    echo "2. Install Python dependencies (venv)"
    echo "3. Build local container"
    echo "4. Pull container from registry"
    echo "5. Prepare offline bundle"
    echo "6. Schedule execution (cron)"
    echo "7. Install as systemd service"
    echo "8. Run script (Python or Container)"
    echo "9. Exit"
    echo ""
    echo -n "Select an option [1-9]: "
}

pause() {
    echo ""
    echo -n "Press Enter to continue..."
    read -r
}

main() {
    while true; do
        show_menu
        read -r choice
        echo ""

        case $choice in
            1)
                echo -e "${GREEN}Running systems test...${RESET}"
                echo ""
                bash "${SCRIPTS_DIR}/system-test.sh"
                pause
                ;;
            2)
                echo -e "${GREEN}Installing Python dependencies...${RESET}"
                echo ""
                bash "${SCRIPTS_DIR}/install-python.sh"
                pause
                ;;
            3)
                echo -e "${GREEN}Building local container...${RESET}"
                echo ""
                bash "${SCRIPTS_DIR}/build-container.sh"
                pause
                ;;
            4)
                echo -e "${GREEN}Pulling container from registry...${RESET}"
                echo ""
                bash "${SCRIPTS_DIR}/pull-container.sh"
                pause
                ;;
            5)
                echo -e "${GREEN}Preparing offline bundle...${RESET}"
                echo ""
                bash "${SCRIPTS_DIR}/prepare-offline-bundle.sh"
                pause
                ;;
            6)
                echo -e "${GREEN}Showing schedule execution instructions...${RESET}"
                echo ""
                bash "${SCRIPTS_DIR}/schedule-cron.sh"
                pause
                ;;
            7)
                echo -e "${GREEN}Showing systemd service installation...${RESET}"
                echo ""
                bash "${SCRIPTS_DIR}/install-systemd-service.sh"
                pause
                ;;
            8)
                bash "${SCRIPTS_DIR}/run-script.sh"
                ;;
            9)
                echo -e "${GREEN}Exiting...${RESET}"
                exit 0
                ;;
            *)
                echo -e "${RED}Invalid option. Please select 1-9.${RESET}"
                pause
                ;;
        esac
    done
}

main "$@"
