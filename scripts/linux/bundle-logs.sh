#!/usr/bin/env bash

#===============================================================================
# Bundle logs for offline deployment
#
# Copies log files from actual locations (determined by data_dir.txt and config)
# to bundle output directory. Non-interactive - all decisions made by calling script.
#
# Usage:
#   ./bundle-logs.sh --output PATH [--source-path PATH] [--compress]
#
# Options:
#   --output PATH        Destination directory for bundled logs (required)
#   --source-path PATH   Override source directory for get-log-details (optional)
#   --compress           Compress the bundled logs into a tar.gz archive
#===============================================================================

set -e

# ANSI color codes
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
GRAY='\033[0;90m'
RESET='\033[0m'

OUTPUT_PATH=""
SOURCE_PATH="$(pwd)"
COMPRESS=false

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --output)
            OUTPUT_PATH="$2"
            shift 2
            ;;
        --source-path)
            SOURCE_PATH="$2"
            shift 2
            ;;
        --compress)
            COMPRESS=true
            shift
            ;;
        *)
            echo -e "${RED}Unknown option: $1${RESET}"
            echo "Usage: $0 --output PATH [--source-path PATH] [--compress]"
            exit 1
            ;;
    esac
done

# Validate required parameters
if [ -z "$OUTPUT_PATH" ]; then
    echo -e "${RED}Error: --output parameter is required${RESET}"
    echo "Usage: $0 --output PATH [--source-path PATH]"
    exit 1
fi

# Get log details from the source location
echo -e "${CYAN}Discovering log files...${RESET}"

SCRIPT_DIR="$(dirname "${BASH_SOURCE[0]}")"
cd "$SOURCE_PATH"
LOG_DETAILS=$("${SCRIPT_DIR}/get-log-details.sh")
cd - > /dev/null

if [ -z "$LOG_DETAILS" ]; then
    echo -e "${YELLOW}No log locations found.${RESET}"
    exit 0
fi

# Parse log details output and copy files
TOTAL_FILES_COPIED=0

while IFS= read -r line; do
    # Parse the line format: "23 files     /path/to/logs"
    # or "(not found)  /path/to/logs"

    if [[ $line =~ ^([0-9]+)\ files\ +(.+)$ ]]; then
        # Files found
        FILE_COUNT="${BASH_REMATCH[1]}"
        SOURCE_DIR="${BASH_REMATCH[2]}"

        # Determine destination directory name
        if [[ $SOURCE_DIR =~ logs_out|log_out ]]; then
            DEST_DIR="logs_out"
        else
            DEST_DIR="logs"
        fi

        DEST_PATH="${OUTPUT_PATH}/${DEST_DIR}"

        echo -e "${GRAY}Copying ${FILE_COUNT} file(s) from:${RESET}"
        echo -e "${GRAY}  Source: ${SOURCE_DIR}${RESET}"
        echo -e "${GRAY}  Dest:   ${DEST_PATH}${RESET}"

        # Ensure destination exists
        mkdir -p "$DEST_PATH"

        # Copy all files
        if cp -r "$SOURCE_DIR"/* "$DEST_PATH" 2>/dev/null; then
            TOTAL_FILES_COPIED=$((TOTAL_FILES_COPIED + FILE_COUNT))
            echo -e "${GREEN}  ✓ Copied successfully${RESET}"
        else
            echo -e "${RED}  ✗ Error copying files${RESET}"
        fi

    elif [[ $line =~ ^\(not\ found\)\ +(.+)$ ]]; then
        # Directory not found
        SOURCE_DIR="${BASH_REMATCH[1]}"
        echo -e "${YELLOW}Skipping (not found): ${SOURCE_DIR}${RESET}"
    fi
done <<< "$LOG_DETAILS"

echo ""
echo -e "${GREEN}Log bundling complete.${RESET}"
echo -e "${CYAN}Total files bundled: ${TOTAL_FILES_COPIED}${RESET}"

# Optionally compress the bundled logs
if [ "$COMPRESS" = true ] && [ $TOTAL_FILES_COPIED -gt 0 ]; then
    echo ""
    echo -e "${CYAN}Compressing bundled logs...${RESET}"

    TIMESTAMP=$(date +%Y%m%d-%H%M%S)
    OUTPUT_PARENT=$(dirname "$OUTPUT_PATH")
    TAR_PATH="${OUTPUT_PARENT}/bundled-logs-${TIMESTAMP}.tar.gz"

    ITEMS_TO_COMPRESS=""
    if [ -d "${OUTPUT_PATH}/logs" ]; then
        ITEMS_TO_COMPRESS="${ITEMS_TO_COMPRESS} logs"
    fi
    if [ -d "${OUTPUT_PATH}/logs_out" ]; then
        ITEMS_TO_COMPRESS="${ITEMS_TO_COMPRESS} logs_out"
    fi

    if [ -n "$ITEMS_TO_COMPRESS" ]; then
        cd "$OUTPUT_PATH"
        if tar -czf "$TAR_PATH" $ITEMS_TO_COMPRESS 2>/dev/null; then
            TAR_SIZE=$(du -h "$TAR_PATH" | cut -f1)
            echo -e "${GREEN}  ✓ Compressed to: ${TAR_PATH}${RESET}"
            echo -e "${GREEN}  ✓ Archive size: ${TAR_SIZE}${RESET}"
        else
            echo -e "${RED}  ✗ Error compressing logs${RESET}"
        fi
        cd - > /dev/null
    fi
fi
