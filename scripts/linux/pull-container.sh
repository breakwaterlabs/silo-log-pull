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

# Test container runtime connectivity
echo -e "${GREEN}Checking ${CONTAINER_CMD} daemon...${RESET}"
if ! ${CONTAINER_CMD} version >/dev/null 2>&1; then
    echo ""
    echo -e "${RED}Error: Cannot connect to ${CONTAINER_CMD} daemon${RESET}"
    echo ""
    echo -e "${YELLOW}The container runtime may not be running or you may lack permissions.${RESET}"
    echo ""
    echo -e "${GREEN}Possible solutions:${RESET}"
    echo "  1. Start the Docker/Podman service:"
    echo "     sudo systemctl start docker    (or 'podman' if using Podman)"
    echo "  2. Check service status:"
    echo "     sudo systemctl status docker"
    echo "  3. Add your user to the docker group (then logout/login):"
    echo "     sudo usermod -aG docker \$USER"
    echo "  4. Run 'System test' from the setup menu to diagnose the issue"
    exit 1
fi

echo -e "${GREEN}✓ ${CONTAINER_CMD} daemon is running${RESET}"
echo ""
echo -e "${GREEN}Pulling container image from registry...${RESET}"
echo -e "${YELLOW}This may take several minutes...${RESET}"
echo ""

# Disable set -e temporarily to capture error
set +e
PULL_OUTPUT=$(${CONTAINER_CMD} pull "${REGISTRY_IMAGE}" 2>&1)
PULL_EXIT=$?
set -e

if [ $PULL_EXIT -ne 0 ]; then
    echo ""
    echo -e "${RED}Error: Failed to pull container image${RESET}"
    echo ""

    if echo "$PULL_OUTPUT" | grep -qi "denied\|unauthorized\|authentication"; then
        echo -e "${YELLOW}Registry authentication failed.${RESET}"
        echo ""
        echo "The registry may require authentication or the image may not be publicly accessible."
        echo "Please check with your administrator for access credentials."
    elif echo "$PULL_OUTPUT" | grep -qi "not found\|no such\|does not exist"; then
        echo -e "${YELLOW}Container image not found in registry.${RESET}"
        echo ""
        echo "The image path may be incorrect or the image may not be published yet."
        echo "Registry: ${REGISTRY_IMAGE}"
    elif echo "$PULL_OUTPUT" | grep -qi "timeout\|network\|connection\|resolve"; then
        echo -e "${YELLOW}Network connection error.${RESET}"
        echo ""
        echo "Cannot reach the registry. Please check your internet connection."
    else
        echo -e "${YELLOW}Pull error details:${RESET}"
        echo "$PULL_OUTPUT"
    fi

    echo ""
    echo -e "${GREEN}Troubleshooting:${RESET}"
    echo "  1. Check your internet connection"
    echo "  2. Verify registry access: ${REGISTRY_IMAGE}"
    echo "  3. Run 'System test' from the setup menu"
    echo "  4. Try building the container locally instead (option 3 in menu)"

    exit 1
fi

echo ""
echo -e "${GREEN}Tagging image as '${LOCAL_TAG}'...${RESET}"

# Disable set -e temporarily to capture error
set +e
${CONTAINER_CMD} tag "${REGISTRY_IMAGE}" "${LOCAL_TAG}"
TAG_EXIT=$?
set -e

if [ $TAG_EXIT -ne 0 ]; then
    echo ""
    echo -e "${RED}Error: Failed to tag image${RESET}"
    echo "The image was pulled but could not be tagged locally."
    echo ""
    echo "You can try tagging it manually:"
    echo "  ${CONTAINER_CMD} tag ${REGISTRY_IMAGE} ${LOCAL_TAG}"
    exit 1
fi

echo ""
echo -e "${GREEN}============================================${RESET}"
echo -e "${GREEN}Pull complete!${RESET}"
echo -e "${GREEN}============================================${RESET}"
echo ""
echo "Container image successfully pulled and tagged as '${LOCAL_TAG}'"
echo ""
echo "To run the container:"
echo "  cd ${REPOBASE}/app"
echo "  ${CONTAINER_CMD} run --rm -v \$(pwd)/data:/data ${LOCAL_TAG}"
