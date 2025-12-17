#!/usr/bin/env bash

#==============================================================================
# Install as systemd Service
#==============================================================================

REPOBASE="$(cd "$(dirname "${BASH_SOURCE[0]}")"/../.. && pwd)"
APP_DIR="${REPOBASE}/app"
CURRENT_USER="${USER}"

# ANSI color codes
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
RESET='\033[0m'

echo -e "${CYAN}=======================================${RESET}"
echo -e "${CYAN}  Install as systemd Service${RESET}"
echo -e "${CYAN}=======================================${RESET}"
echo ""

# Check if podman is available
if ! command -v podman >/dev/null 2>&1; then
    echo -e "${RED}Note: This option is recommended for use with Podman.${RESET}"
    echo ""
    if command -v docker >/dev/null 2>&1; then
        echo "Docker is installed. You can adapt these instructions for Docker,"
        echo "but Podman is preferred for systemd integration."
    else
        echo "Neither Podman nor Docker is installed."
    fi
    echo ""
    echo "To install Podman:"
    echo "  Ubuntu/Debian: sudo apt install podman"
    echo "  RHEL/CentOS:   sudo dnf install podman"
    echo ""
fi

# Determine container command
CONTAINER_CMD="podman"
if ! command -v podman >/dev/null 2>&1; then
    if command -v docker >/dev/null 2>&1; then
        CONTAINER_CMD="docker"
    fi
fi

echo -e "${GREEN}1. Create the service file:${RESET}"
echo "   sudo nano /etc/systemd/system/silo-log-pull.service"
echo ""
echo -e "${GREEN}2. Paste this content:${RESET}"
echo ""
echo -e "${YELLOW}---[Service File]---${RESET}"
cat <<EOF
[Unit]
Description=Silo Log Pull Service
After=network.target

[Service]
Type=oneshot
User=${CURRENT_USER}
WorkingDirectory=${APP_DIR}
ExecStart=/usr/bin/${CONTAINER_CMD} run --rm -v ${APP_DIR}/data:/data silo-log-pull

[Install]
WantedBy=multi-user.target
EOF
echo -e "${YELLOW}---[End Service File]---${RESET}"
echo ""

echo -e "${GREEN}3. Create the timer file:${RESET}"
echo "   sudo nano /etc/systemd/system/silo-log-pull.timer"
echo ""
echo -e "${GREEN}4. Paste this content:${RESET}"
echo ""
echo -e "${YELLOW}---[Timer File]---${RESET}"
cat <<EOF
[Unit]
Description=Run Silo Log Pull Daily

[Timer]
OnCalendar=daily
Persistent=true

[Install]
WantedBy=timers.target
EOF
echo -e "${YELLOW}---[End Timer File]---${RESET}"
echo ""

echo -e "${GREEN}5. Enable and start the timer:${RESET}"
echo "   sudo systemctl daemon-reload"
echo "   sudo systemctl enable --now silo-log-pull.timer"
echo ""

echo -e "${GREEN}6. Check status:${RESET}"
echo "   systemctl status silo-log-pull.timer"
echo "   systemctl list-timers"
echo ""

echo -e "${GREEN}7. Manual run (for testing):${RESET}"
echo "   sudo systemctl start silo-log-pull.service"
echo ""

echo "Timer schedule options (OnCalendar=):"
echo "  daily          - Every day at midnight"
echo "  weekly         - Every Monday at midnight"
echo "  *-*-* 02:00:00 - Every day at 2:00 AM"
echo "  *-*-* *:0/6:00 - Every 6 hours"
