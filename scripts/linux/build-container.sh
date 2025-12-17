#!/usr/bin/env bash

#==============================================================================
# Build Local Container
#==============================================================================

set -e

REPOBASE="$(cd "$(dirname "${BASH_SOURCE[0]}")"/../.. && pwd)"

# ANSI color codes
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
RESET='\033[0m'

# Determine which container runtime to use
CONTAINER_CMD=""
if command -v docker >/dev/null 2>&1; then
    CONTAINER_CMD="docker"
elif command -v podman >/dev/null 2>&1; then
    CONTAINER_CMD="podman"
else
    echo -e "${RED}Error: Neither docker nor podman is installed${RESET}"
    echo ""
    echo "Please install a container runtime first:"
    echo "  Ubuntu/Debian: sudo apt install docker.io"
    echo "  RHEL/CentOS:   sudo dnf install docker"
    echo "  Or install Podman: sudo dnf install podman"
    exit 1
fi

echo -e "${GREEN}Using container runtime: ${CONTAINER_CMD}${RESET}"
echo ""
echo -e "${GREEN}Building container image 'silo-log-pull'...${RESET}"
echo ""

cd "${REPOBASE}"
${CONTAINER_CMD} build -t silo-log-pull .

echo ""
echo -e "${GREEN}============================================${RESET}"
echo -e "${GREEN}Build complete!${RESET}"
echo -e "${GREEN}============================================${RESET}"
echo ""
echo "To run the container:"
echo "  cd ${REPOBASE}/app"
echo "  ${CONTAINER_CMD} run --rm -v \$(pwd)/data:/data silo-log-pull"
