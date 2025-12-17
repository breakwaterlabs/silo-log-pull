#!/usr/bin/env bash

#==============================================================================
# Run silo-log-pull Script Menu
#==============================================================================
# Provides a menu to run silo-log-pull using Python (venv) or Container,
# showing the command and offering to execute it.
#
# Usage: ./run-script.sh

set -e

REPOBASE="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
APP_DIR="${REPOBASE}/app"

# ANSI color codes
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
RESET='\033[0m'

show_header() {
    clear
    echo -e "${CYAN}=======================================${RESET}"
    echo -e "${CYAN}  Run silo-log-pull Script${RESET}"
    echo -e "${CYAN}=======================================${RESET}"
    echo ""
}

pause() {
    echo ""
    echo -n "Press Enter to continue..."
    read -r
}

show_run_script_menu() {
    while true; do
        show_header
        echo -e "${CYAN}Run Script Options:${RESET}"
        echo ""
        echo "1. Run with Python (venv)"
        echo "2. Run with Container"
        echo "3. Back to main menu"
        echo ""
        echo -n "Select an option [1-3]: "
        read -r choice
        echo ""

        case $choice in
            1)
                local venv_python="${APP_DIR}/venv/bin/python"
                local python_cmd="python silo_batch_pull.py"

                if [ -f "$venv_python" ]; then
                    python_cmd="venv/bin/python silo_batch_pull.py"
                fi

                echo -e "${GREEN}To run with Python:${RESET}"
                echo -e "${CYAN}  cd ${APP_DIR}${RESET}"
                echo -e "${CYAN}  ${python_cmd}${RESET}"
                echo ""
                echo -n "Would you like to run it now? [Y/n]: "
                read -r run

                if [ -z "$run" ] || [ "$run" = "Y" ] || [ "$run" = "y" ]; then
                    echo ""
                    echo -e "${GREEN}Running Python script...${RESET}"
                    echo ""
                    cd "${APP_DIR}"
                    if [ -f "$venv_python" ]; then
                        "$venv_python" "silo_batch_pull.py"
                    else
                        python "silo_batch_pull.py"
                    fi
                fi

                pause
                ;;
            2)
                local container_cmd='docker run --rm -v "${PWD}/data:/data" silo-log-pull'

                echo -e "${GREEN}To run with Container:${RESET}"
                echo -e "${CYAN}  cd ${APP_DIR}${RESET}"
                echo -e "${CYAN}  ${container_cmd}${RESET}"
                echo ""
                echo -n "Would you like to run it now? [Y/n]: "
                read -r run

                if [ -z "$run" ] || [ "$run" = "Y" ] || [ "$run" = "y" ]; then
                    echo ""
                    echo -e "${GREEN}Running container...${RESET}"
                    echo ""
                    cd "${APP_DIR}"
                    docker run --rm -v "${PWD}/data:/data" silo-log-pull
                fi

                pause
                ;;
            3)
                return
                ;;
            *)
                echo -e "${RED}Invalid option. Please select 1-3.${RESET}"
                pause
                ;;
        esac
    done
}

# Run the menu
show_run_script_menu
