#!/usr/bin/env bash

#==============================================================================
# Display Container Error Information
#==============================================================================
# Shows common container runtime issues on Red Hat/Linux systems
# Usage: ./show-error-container.sh [error_type]
#   error_type: run, build, load (optional, defaults to run)

# ANSI color codes
RED='\033[0;31m'
YELLOW='\033[0;33m'
RESET='\033[0m'

ERROR_TYPE="${1:-run}"

echo ""
echo -e "${RED}Container operation failed.${RESET}"
echo ""
echo -e "${YELLOW}Common issues on Red Hat systems:${RESET}"
echo "  • fapolicyd blocking container runtime"
echo "  • Rootless mode not configured (check /proc/sys/user/max_user_namespaces)"

if [ "$ERROR_TYPE" = "run" ]; then
    echo "  • SELinux blocking volume mounts (add :Z flag)"
elif [ "$ERROR_TYPE" = "build" ]; then
    echo "  • SELinux blocking operations"
elif [ "$ERROR_TYPE" = "load" ]; then
    echo "  • SELinux blocking operations"
fi

echo ""
echo -e "${YELLOW}For detailed troubleshooting, see:${RESET}"
echo "  docs/container-guide.md"
echo "  docs/offline-systems.md"
