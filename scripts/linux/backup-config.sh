#!/usr/bin/env bash

#==============================================================================
# Backup Configuration and Secrets
#==============================================================================
# Creates a backup of configuration files and secrets (excluding logs)
#
# Usage:
#   ./backup-config.sh [--output PATH] [--non-interactive]

set -e

REPOBASE="$(cd "$(dirname "${BASH_SOURCE[0]}")"/../.. && pwd)"
OUTPUT_PATH=""
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
        --output)
            OUTPUT_PATH="$2"
            shift 2
            ;;
        --non-interactive)
            NON_INTERACTIVE=true
            shift
            ;;
        *)
            echo -e "${RED}Unknown option: $1${RESET}"
            echo "Usage: $0 [--output PATH] [--non-interactive]"
            exit 1
            ;;
    esac
done

# Set default output path
if [ -z "$OUTPUT_PATH" ]; then
    TIMESTAMP=$(date +%Y%m%d_%H%M%S)
    OUTPUT_PATH="${REPOBASE}/silo-log-pull-config-backup-${TIMESTAMP}.zip"
fi

echo -e "${CYAN}=========================================${RESET}"
echo -e "${CYAN}  Backup Configuration and Secrets${RESET}"
echo -e "${CYAN}=========================================${RESET}"
echo ""

# Check if zip is installed
if ! command -v zip >/dev/null 2>&1; then
    echo -e "${RED}Error: zip command is not installed${RESET}"
    echo "Please install zip: sudo apt install zip"
    exit 1
fi

# Read data directory path
DATA_DIR_FILE="${REPOBASE}/app/data_dir.txt"
if [ -f "$DATA_DIR_FILE" ]; then
    DATA_DIR=$(cat "$DATA_DIR_FILE")
    if [ ! -d "$DATA_DIR" ]; then
        echo -e "${YELLOW}Warning: Data directory specified in data_dir.txt does not exist: $DATA_DIR${RESET}"
        DATA_DIR="${REPOBASE}/app/data"
    fi
else
    DATA_DIR="${REPOBASE}/app/data"
fi

echo -e "${CYAN}Data directory: ${DATA_DIR}${RESET}"
echo ""

# Create temporary directory
TEMP_DIR=$(mktemp -d)
BACKUP_DIR="${TEMP_DIR}/config-backup"
mkdir -p "$BACKUP_DIR"

# Copy configuration files and secrets (excluding logs)
echo -e "${GREEN}Collecting configuration files...${RESET}"

# Copy files from data directory, excluding logs
if [ -d "$DATA_DIR" ]; then
    cd "$DATA_DIR"
    find . -type f \
        ! -path "*/logs/*" \
        ! -path "*/logs_out/*" \
        ! -path "*/logs_in/*" \
        ! -name "*.log" \
        -exec sh -c 'mkdir -p "'"$BACKUP_DIR"'/data/$(dirname "{}")" && cp "{}" "'"$BACKUP_DIR"'/data/{}"' \;
    cd - > /dev/null
    echo -e "${GREEN}✓ Configuration files copied${RESET}"
else
    echo -e "${YELLOW}Warning: Data directory not found: $DATA_DIR${RESET}"
fi

# Copy data_dir.txt if it exists
if [ -f "$DATA_DIR_FILE" ]; then
    cp "$DATA_DIR_FILE" "$BACKUP_DIR/"
    echo -e "${GREEN}✓ data_dir.txt copied${RESET}"
fi

# Create README from template
TEMPLATE_PATH="${REPOBASE}/scripts/templates/readme-backup.txt"
if [ -f "$TEMPLATE_PATH" ]; then
    cp "$TEMPLATE_PATH" "$BACKUP_DIR/README.txt"
else
    echo "Warning: README template not found at $TEMPLATE_PATH" >&2
fi

echo -e "${GREEN}✓ README created${RESET}"

# Create the zip archive
echo ""
echo -e "${GREEN}Creating backup archive...${RESET}"
cd "$TEMP_DIR"
zip -r "$OUTPUT_PATH" config-backup > /dev/null

# Clean up
rm -rf "$TEMP_DIR"

# Display summary
FILE_SIZE=$(du -h "$OUTPUT_PATH" | cut -f1)
echo ""
echo -e "${GREEN}============================================${RESET}"
echo -e "${GREEN}Configuration backup created!${RESET}"
echo -e "${GREEN}============================================${RESET}"
echo ""
echo -e "Backup location: ${YELLOW}$OUTPUT_PATH${RESET}"
echo -e "Backup size: ${YELLOW}$FILE_SIZE${RESET}"
echo ""
echo -e "${CYAN}This backup includes:${RESET}"
echo "  - Configuration files from data directory"
echo "  - API tokens and secrets"
echo "  - data_dir.txt (if present)"
echo ""
echo -e "${YELLOW}Excluded from backup:${RESET}"
echo "  - Log files (logs, logs_out, logs_in directories)"
echo "  - *.log files"
echo ""
echo -e "${CYAN}Keep this backup secure!${RESET}"
echo ""

# Display command summary
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo -e "${CYAN}Execution Summary${RESET}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo ""
echo -e "${GREEN}Command executed:${RESET}"
echo -e "  ${YELLOW}bash $(basename $0) --output $OUTPUT_PATH${RESET}"
echo ""
echo -e "${GREEN}To run this command again:${RESET}"
echo -e "  ${YELLOW}cd ${REPOBASE}/scripts/linux && bash backup-config.sh${RESET}"
echo ""
echo -e "${GREEN}Schedule with cron (weekly on Sunday):${RESET}"
echo -e "  ${YELLOW}0 0 * * 0 cd ${REPOBASE}/scripts/linux && bash backup-config.sh --non-interactive${RESET}"
echo ""
