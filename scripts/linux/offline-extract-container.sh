#!/usr/bin/env bash

#==============================================================================
# Offline Container Package Extraction Script
#==============================================================================

set -e

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
GRAY='\033[0;90m'
RESET='\033[0m'

# Parse arguments
DO_LOAD=false
DO_RUN=false
CONFIGURE_DATA_DIR=true

while [[ $# -gt 0 ]]; do
    case $1 in
        --load)
            DO_LOAD=true
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
            echo "Usage: $0 [--load] [--run] [--no-configure]"
            echo "  --load          Load container image only"
            echo "  --run           Run container only (assumes already loaded)"
            echo "  --no-configure  Skip data directory configuration"
            echo "  (no flags)      Load only"
            exit 1
            ;;
    esac
done

# Default: do load if no flags specified
if [ "$DO_LOAD" = false ] && [ "$DO_RUN" = false ]; then
    DO_LOAD=true
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"
APP_DIR="${REPO_DIR}/app"

# Determine which container runtime to use
CONTAINER_CMD=""
if command -v podman >/dev/null 2>&1; then
    CONTAINER_CMD="podman"
elif command -v docker >/dev/null 2>&1; then
    CONTAINER_CMD="docker"
else
    echo -e "${RED}Error: Neither podman nor docker is installed${RESET}"
    echo ""
    echo "Please install a container runtime first:"
    echo "  Ubuntu/Debian: sudo apt install docker.io"
    echo "  RHEL/CentOS:   sudo dnf install docker"
    echo "  Or install Podman: sudo dnf install podman"
    exit 1
fi

if [ "$DO_LOAD" = true ]; then
    echo -e "${CYAN}=======================================${RESET}"
    echo -e "${CYAN}  silo-log-pull Offline Setup${RESET}"
    echo -e "${CYAN}=======================================${RESET}"
    echo ""
    echo -e "${GREEN}Found ${CONTAINER_CMD}${RESET}"

    TAR_FILE="${REPO_DIR}/silo-log-pull.tar"

    if [ ! -f "${TAR_FILE}" ]; then
        echo -e "${RED}Error: Container image file not found: ${TAR_FILE}${RESET}"
        exit 1
    fi

    echo ""
    echo -e "${GREEN}Loading container image...${RESET}"
    echo "This may take a few minutes..."
    echo ""

    if ! ${CONTAINER_CMD} load -i "${TAR_FILE}"; then
        "${SCRIPT_DIR}/show-error-container.sh" load
        exit 1
    fi

    echo ""
    echo -e "${GREEN}============================================${RESET}"
    echo -e "${GREEN}Container image loaded successfully!${RESET}"
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
    # Verify image is loaded
    if ! ${CONTAINER_CMD} image inspect silo-log-pull >/dev/null 2>&1; then
        echo -e "${RED}Error: Container image not loaded${RESET}"
        echo "Please run with --load first"
        exit 1
    fi

    # Resolve data directory
    DATA_MOUNT_PATH="${APP_DIR}/data"
    if [ -f "${APP_DIR}/data_dir.txt" ]; then
        DATA_MOUNT_PATH=$(cat "${APP_DIR}/data_dir.txt")
    fi

    echo -e "${CYAN}Running silo-log-pull...${RESET}"
    echo -e "${GRAY}Data directory: ${DATA_MOUNT_PATH}${RESET}"
    echo ""

    # Run container with full path
    if ! ${CONTAINER_CMD} run --rm -v "${DATA_MOUNT_PATH}:/data" silo-log-pull; then
        "${SCRIPT_DIR}/show-error-container.sh" run
        exit 1
    fi
else
    # Resolve data directory for display
    DATA_MOUNT_PATH="${APP_DIR}/data"
    if [ -f "${APP_DIR}/data_dir.txt" ]; then
        DATA_MOUNT_PATH=$(cat "${APP_DIR}/data_dir.txt")
    fi

    echo "To run silo-log-pull:"
    echo "  ${CONTAINER_CMD} run --rm -v \"${DATA_MOUNT_PATH}:/data\" silo-log-pull"
    echo ""
    echo "Or use: ${SCRIPT_DIR}/$(basename "${BASH_SOURCE[0]}") --run"
    echo ""
    echo "See the docs/ directory for complete documentation."
fi
