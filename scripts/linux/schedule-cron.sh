#!/usr/bin/env bash

#==============================================================================
# Schedule Execution (Cron)
#==============================================================================

REPOBASE="$(cd "$(dirname "${BASH_SOURCE[0]}")"/../.. && pwd)"
APP_DIR="${REPOBASE}/app"

# ANSI color codes
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[0;33m'
RESET='\033[0m'

echo -e "${CYAN}=======================================${RESET}"
echo -e "${CYAN}  Schedule Execution with Cron${RESET}"
echo -e "${CYAN}=======================================${RESET}"
echo ""
echo "To schedule silo-log-pull to run automatically, add one of the"
echo "following lines to your crontab."
echo ""
echo -e "${GREEN}1. Edit crontab:${RESET}"
echo "   crontab -e"
echo ""

# Detect available runtimes
HAS_DOCKER=false
HAS_PODMAN=false
HAS_PYTHON=false
CONTAINER_CMD=""

if command -v docker >/dev/null 2>&1; then
    HAS_DOCKER=true
    CONTAINER_CMD="docker"
fi

if command -v podman >/dev/null 2>&1; then
    HAS_PODMAN=true
    if [ -z "$CONTAINER_CMD" ]; then
        CONTAINER_CMD="podman"
    fi
fi

if command -v python3 >/dev/null 2>&1; then
    HAS_PYTHON=true
fi

echo -e "${GREEN}2. Add one of these lines (runs daily at 2 AM):${RESET}"
echo ""

if [ "$HAS_DOCKER" = true ] || [ "$HAS_PODMAN" = true ]; then
    echo -e "${YELLOW}Container mode (${CONTAINER_CMD}):${RESET}"
    echo "0 2 * * * cd ${APP_DIR} && ${CONTAINER_CMD} run --rm -v \$(pwd)/data:/data silo-log-pull"
    echo ""
fi

if [ "$HAS_PYTHON" = true ]; then
    if [ -d "${APP_DIR}/venv" ]; then
        echo -e "${YELLOW}Python mode (with venv):${RESET}"
        echo "0 2 * * * cd ${APP_DIR} && source venv/bin/activate && python silo_batch_pull.py"
        echo ""
    else
        echo -e "${YELLOW}Python mode (system Python):${RESET}"
        echo "0 2 * * * cd ${APP_DIR} && python3 silo_batch_pull.py"
        echo ""
    fi
fi

if [ "$HAS_DOCKER" = false ] && [ "$HAS_PODMAN" = false ] && [ "$HAS_PYTHON" = false ]; then
    echo -e "${YELLOW}No container runtime or Python 3 detected.${RESET}"
    echo "Please install docker, podman, or Python 3 first."
    echo ""
fi

echo -e "${GREEN}3. Save and exit the editor${RESET}"
echo ""
echo "Cron schedule format: minute hour day month weekday"
echo "Example schedules:"
echo "  0 2 * * *     - Daily at 2:00 AM"
echo "  0 */6 * * *   - Every 6 hours"
echo "  0 0 * * 0     - Weekly on Sunday at midnight"
echo ""
echo "To view current crontab: crontab -l"
echo "To remove crontab: crontab -r"
