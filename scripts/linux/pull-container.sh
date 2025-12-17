#!/usr/bin/env bash

#==============================================================================
# Pull Container from Registry
#==============================================================================

set -e

REPOBASE="$(cd "$(dirname "${BASH_SOURCE[0]}")"/../.. && pwd)"
REGISTRY_IMAGE="registry.gitlab.com/breakwaterlabs/silo-log-pull:latest"
LOCAL_TAG="silo-log-pull"

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
echo -e "${GREEN}Pulling container image from registry...${RESET}"
echo ""

${CONTAINER_CMD} pull "${REGISTRY_IMAGE}"

echo ""
echo -e "${GREEN}Tagging image as '${LOCAL_TAG}'...${RESET}"
${CONTAINER_CMD} tag "${REGISTRY_IMAGE}" "${LOCAL_TAG}"

echo ""
echo -e "${GREEN}============================================${RESET}"
echo -e "${GREEN}Pull complete!${RESET}"
echo -e "${GREEN}============================================${RESET}"
echo ""
echo "To run the container:"
echo "  cd ${REPOBASE}/app"
echo "  ${CONTAINER_CMD} run --rm -v \$(pwd)/data:/data ${LOCAL_TAG}"
