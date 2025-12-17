#!/usr/bin/env bash

#==============================================================================
# Prepare Offline Bundle Package
#
# Creates a comprehensive offline bundle with optional Python dependencies,
# container image, and log files. Supports both interactive menu mode and
# command-line flags.
#
# Usage:
#   ./prepare-offline-bundle.sh [OPTIONS]
#
# Options:
#   --python          Include Python dependencies
#   --container       Include container image
#   --logs            Include existing logs
#   --non-interactive Run without prompts (requires explicit flags)
#   --output PATH     Output path for bundle
#
# Examples:
#   ./prepare-offline-bundle.sh
#     Interactive mode with prompts
#
#   ./prepare-offline-bundle.sh --python --logs
#     Create bundle with Python dependencies and logs
#
#   ./prepare-offline-bundle.sh --container --non-interactive
#     Create container-only bundle without prompts
#==============================================================================

set -e

# ANSI color codes
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
GRAY='\033[0;90m'
RESET='\033[0m'

REPOBASE="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TEMP_DIR="${REPOBASE}/.offline-temp-bundle"
OUTPUT_PATH=""
INCLUDE_PYTHON=false
INCLUDE_CONTAINER=false
INCLUDE_LOGS=false
NON_INTERACTIVE=false

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --python)
            INCLUDE_PYTHON=true
            shift
            ;;
        --container)
            INCLUDE_CONTAINER=true
            shift
            ;;
        --logs)
            INCLUDE_LOGS=true
            shift
            ;;
        --non-interactive)
            NON_INTERACTIVE=true
            shift
            ;;
        --output)
            OUTPUT_PATH="$2"
            shift 2
            ;;
        *)
            echo -e "${RED}Unknown option: $1${RESET}"
            echo "Usage: $0 [--python] [--container] [--logs] [--non-interactive] [--output PATH]"
            exit 1
            ;;
    esac
done

# Interactive mode if no flags provided
if [ "$NON_INTERACTIVE" = false ] && [ "$INCLUDE_PYTHON" = false ] && [ "$INCLUDE_CONTAINER" = false ]; then
    echo ""
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${CYAN}║          Silo Log Pull - Offline Bundle Generator            ║${RESET}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${RESET}"
    echo ""
    echo -e "${YELLOW}What would you like to include in the offline bundle?${RESET}"
    echo ""
    echo -e "  ${RESET}[1] Python deployment (with dependencies)${RESET}"
    echo -e "  ${RESET}[2] Container deployment (Docker/Podman image)${RESET}"
    echo -e "  ${RESET}[3] Both Python and Container${RESET}"
    echo -e "  ${RESET}[4] Custom selection${RESET}"
    echo ""
    echo -n "Choice [1-4]: "
    read -r choice

    case $choice in
        1)
            INCLUDE_PYTHON=true
            INCLUDE_CONTAINER=false
            ;;
        2)
            INCLUDE_PYTHON=false
            INCLUDE_CONTAINER=true
            ;;
        3)
            INCLUDE_PYTHON=true
            INCLUDE_CONTAINER=true
            ;;
        4)
            echo ""
            echo -n "Include Python dependencies? [Y/n]: "
            read -r response
            if [ "$response" != "n" ] && [ "$response" != "N" ]; then
                INCLUDE_PYTHON=true
            fi

            echo -n "Include container image? [Y/n]: "
            read -r response
            if [ "$response" != "n" ] && [ "$response" != "N" ]; then
                INCLUDE_CONTAINER=true
            fi
            ;;
        *)
            echo -e "${RED}Invalid choice. Exiting.${RESET}"
            exit 1
            ;;
    esac
fi

# Set default output path if not provided
if [ -z "$OUTPUT_PATH" ]; then
    if [ "$INCLUDE_PYTHON" = true ] && [ "$INCLUDE_CONTAINER" = true ]; then
        OUTPUT_PATH="${REPOBASE}/silo-log-pull-full-offline.zip"
    elif [ "$INCLUDE_CONTAINER" = true ]; then
        OUTPUT_PATH="${REPOBASE}/silo-log-pull-container-offline.zip"
    else
        OUTPUT_PATH="${REPOBASE}/silo-log-pull-offline.zip"
    fi
fi

# Prompt for logs if not specified
if [ "$NON_INTERACTIVE" = false ]; then
    SCRIPT_DIR="$(dirname "${BASH_SOURCE[0]}")"
    LOG_DETAILS=$("${SCRIPT_DIR}/get-log-details.sh")

    echo ""
    echo -e "${YELLOW}Do you want to include existing logs in the offline bundle?${RESET}"
    echo "$LOG_DETAILS"
    echo -n "Include logs? [y/N]: "
    read -r response
    if [ "$response" = "y" ] || [ "$response" = "Y" ]; then
        INCLUDE_LOGS=true
    fi
fi

# Display configuration
echo ""
echo -e "${CYAN}Bundle Configuration:${RESET}"
if [ "$INCLUDE_PYTHON" = true ]; then
    echo -e "  Python dependencies: ${GREEN}Yes${RESET}"
else
    echo -e "  Python dependencies: ${GRAY}No${RESET}"
fi
if [ "$INCLUDE_CONTAINER" = true ]; then
    echo -e "  Container image:     ${GREEN}Yes${RESET}"
else
    echo -e "  Container image:     ${GRAY}No${RESET}"
fi
if [ "$INCLUDE_LOGS" = true ]; then
    echo -e "  Logs:                ${GREEN}Yes${RESET}"
else
    echo -e "  Logs:                ${GRAY}No${RESET}"
fi
echo -e "  Output:              ${RESET}$OUTPUT_PATH${RESET}"
echo ""

# Validate prerequisites
if [ "$INCLUDE_PYTHON" = true ]; then
    if ! command -v python3 >/dev/null 2>&1; then
        echo -e "${RED}Error: Python 3 is not installed${RESET}"
        echo "Python is required for --python option"
        exit 1
    fi
    PYTHON_VERSION=$(python3 --version)
    echo -e "${GREEN}✓ Python found: $PYTHON_VERSION${RESET}"

    if ! python3 -m pip --version >/dev/null 2>&1; then
        echo -e "${RED}Error: pip is not available${RESET}"
        exit 1
    fi
fi

if [ "$INCLUDE_CONTAINER" = true ]; then
    CONTAINER_CMD=""
    if command -v docker >/dev/null 2>&1; then
        CONTAINER_CMD="docker"
    elif command -v podman >/dev/null 2>&1; then
        CONTAINER_CMD="podman"
    else
        echo -e "${RED}Error: Neither docker nor podman is installed${RESET}"
        echo "A container runtime is required for --container option"
        exit 1
    fi
    echo -e "${GREEN}✓ Container runtime found: $CONTAINER_CMD${RESET}"

    # Check if image exists
    if ! ${CONTAINER_CMD} image inspect silo-log-pull >/dev/null 2>&1; then
        echo -e "${RED}Error: Container image 'silo-log-pull' not found${RESET}"
        echo ""
        echo -e "${YELLOW}Please build or pull the image first:${RESET}"
        echo "  Option 1: Run 'Build local container' from the menu"
        echo "  Option 2: Run 'Pull container from registry' from the menu"
        exit 1
    fi
    echo -e "${GREEN}✓ Container image 'silo-log-pull' found${RESET}"
fi

# Check if zip is installed
if ! command -v zip >/dev/null 2>&1; then
    echo -e "${RED}Error: zip command is not installed${RESET}"
    echo "Please install zip: sudo apt install zip"
    exit 1
fi

echo ""

# Create staging directory structure
echo -e "${GREEN}Creating staging directory...${RESET}"
rm -rf "$TEMP_DIR"
mkdir -p "$TEMP_DIR"

# Copy repository files (excluding data, venv, pycache, git)
echo -e "${GREEN}Copying repository files...${RESET}"
cd "$REPOBASE"
find . -maxdepth 1 -type f \
    ! -name 'data_dir.txt' \
    ! -name '*.zip' \
    ! -name '.git*' \
    -exec cp {} "$TEMP_DIR/" \;

# Copy directories excluding unwanted ones
for dir in app docs scripts; do
    if [ -d "$dir" ]; then
        cp -r "$dir" "$TEMP_DIR/"
    fi
done

# Create clean data directory structure
echo -e "${GREEN}Creating clean data directory structure...${RESET}"
mkdir -p "$TEMP_DIR/app/data/logs"
mkdir -p "$TEMP_DIR/app/data/logs_out"

# Copy example config
if [ -f "${REPOBASE}/app/data/example_silo_config.json" ]; then
    cp "${REPOBASE}/app/data/example_silo_config.json" "$TEMP_DIR/app/data/"
fi

# Conditionally include Python dependencies
if [ "$INCLUDE_PYTHON" = true ]; then
    echo ""
    echo -e "${GREEN}Downloading Python dependencies...${RESET}"
    echo -e "${YELLOW}This may take a few minutes...${RESET}"

    mkdir -p "$TEMP_DIR/app/silo-dependencies"

    cd "${REPOBASE}/app"
    python3 -m pip download -r requirements.txt -d "$TEMP_DIR/app/silo-dependencies"
fi

# Conditionally include container image
if [ "$INCLUDE_CONTAINER" = true ]; then
    echo ""
    echo -e "${GREEN}Exporting container image...${RESET}"
    echo -e "${YELLOW}This may take a few minutes...${RESET}"

    OUTPUT_TAR="$TEMP_DIR/silo-log-pull.tar"
    ${CONTAINER_CMD} save silo-log-pull -o "$OUTPUT_TAR"

    if [ $? -ne 0 ]; then
        echo -e "${RED}Error: Failed to export container image${RESET}"
        rm -rf "$TEMP_DIR"
        exit 1
    fi
fi

# Conditionally include logs
if [ "$INCLUDE_LOGS" = true ]; then
    echo ""
    echo -e "${GREEN}Bundling logs...${RESET}"

    SCRIPT_DIR="$(dirname "${BASH_SOURCE[0]}")"
    "${SCRIPT_DIR}/bundle-logs.sh" \
        --output "$TEMP_DIR/app/data" \
        --source-path "$REPOBASE"
fi

# Create extraction scripts and README
echo ""
echo -e "${GREEN}Creating extraction scripts and README...${RESET}"

# Determine which extraction scripts to create based on what's included
if [ "$INCLUDE_PYTHON" = true ]; then
    # Create Python extraction script
    cat > "$TEMP_DIR/offline-extract.sh" <<'EXTRACT_PYTHON_EOF'
#!/usr/bin/env bash

#==============================================================================
# Offline Python Package Extraction Script
#==============================================================================

set -e

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
RESET='\033[0m'

echo -e "${CYAN}=======================================${RESET}"
echo -e "${CYAN}  silo-log-pull Offline Setup${RESET}"
echo -e "${CYAN}=======================================${RESET}"
echo ""

# Check if Python 3 is installed
if ! command -v python3 >/dev/null 2>&1; then
    echo -e "${RED}Error: Python 3 is not installed${RESET}"
    echo ""
    echo "Please install Python 3 first:"
    echo "  Ubuntu/Debian: sudo apt install python3 python3-pip python3-venv python3-dev gcc libgmp-dev"
    echo "  RHEL/CentOS:   sudo dnf install python3 python3-pip python3-devel gcc gmp-devel"
    exit 1
fi

APP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/app" && pwd)"
VENV_DIR="${APP_DIR}/venv"

echo -e "${GREEN}Creating virtual environment...${RESET}"
python3 -m venv "${VENV_DIR}"

echo -e "${GREEN}Activating virtual environment...${RESET}"
source "${VENV_DIR}/bin/activate"

echo -e "${GREEN}Upgrading pip...${RESET}"
pip install --upgrade pip --quiet

echo -e "${GREEN}Installing dependencies from offline packages...${RESET}"
pip install --no-index --find-links "${APP_DIR}/silo-dependencies" -r "${APP_DIR}/requirements.txt"

echo ""
echo -e "${GREEN}============================================${RESET}"
echo -e "${GREEN}Installation complete!${RESET}"
echo -e "${GREEN}============================================${RESET}"
echo ""
echo "To run silo-log-pull:"
echo "  cd ${APP_DIR}"
echo "  source venv/bin/activate"
echo "  python silo_batch_pull.py"
echo ""
echo "See the docs/ directory for complete documentation."
EXTRACT_PYTHON_EOF

    chmod +x "$TEMP_DIR/offline-extract.sh"
fi

if [ "$INCLUDE_CONTAINER" = true ]; then
    # Create Container extraction script
    EXTRACT_FILENAME="offline-extract.sh"
    if [ "$INCLUDE_PYTHON" = true ]; then
        EXTRACT_FILENAME="offline-extract-container.sh"
    fi

    cat > "$TEMP_DIR/$EXTRACT_FILENAME" <<'EXTRACT_CONTAINER_EOF'
#!/usr/bin/env bash

#==============================================================================
# Offline Container Package Extraction Script
#==============================================================================

set -e

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
RESET='\033[0m'

echo -e "${CYAN}=======================================${RESET}"
echo -e "${CYAN}  silo-log-pull Offline Setup${RESET}"
echo -e "${CYAN}=======================================${RESET}"
echo ""

# Determine which container runtime to use
CONTAINER_CMD=""
if command -v docker >/dev/null 2>&1; then
    CONTAINER_CMD="docker"
    echo -e "${GREEN}Found Docker${RESET}"
elif command -v podman >/dev/null 2>&1; then
    CONTAINER_CMD="podman"
    echo -e "${GREEN}Found Podman${RESET}"
else
    echo -e "${RED}Error: Neither docker nor podman is installed${RESET}"
    echo ""
    echo "Please install a container runtime first:"
    echo "  Ubuntu/Debian: sudo apt install docker.io"
    echo "  RHEL/CentOS:   sudo dnf install docker"
    echo "  Or install Podman: sudo dnf install podman"
    exit 1
fi

TAR_FILE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/silo-log-pull.tar"

if [ ! -f "${TAR_FILE}" ]; then
    echo -e "${RED}Error: Container image file not found: ${TAR_FILE}${RESET}"
    exit 1
fi

echo ""
echo -e "${GREEN}Loading container image...${RESET}"
echo "This may take a few minutes..."
echo ""

${CONTAINER_CMD} load -i "${TAR_FILE}"

echo ""
echo -e "${GREEN}============================================${RESET}"
echo -e "${GREEN}Container image loaded successfully!${RESET}"
echo -e "${GREEN}============================================${RESET}"
echo ""
echo "To run silo-log-pull:"
echo "  cd app"
echo "  ${CONTAINER_CMD} run --rm -v \$(pwd)/data:/data silo-log-pull"
echo ""
echo "See the docs/ directory for complete documentation."
EXTRACT_CONTAINER_EOF

    chmod +x "$TEMP_DIR/$EXTRACT_FILENAME"
fi

# Create README
OUTPUT_BASENAME=$(basename "$OUTPUT_PATH")

cat > "$TEMP_DIR/README-OFFLINE.txt" <<README_EOF
================================================================================
silo-log-pull - Offline Package
================================================================================

This package contains everything needed to run silo-log-pull on an offline
system without internet access.

CONTENTS:
  - app/                  Python application
$(if [ "$INCLUDE_PYTHON" = true ]; then echo "  - app/silo-dependencies/  Python dependencies (offline packages)"; fi)
$(if [ "$INCLUDE_CONTAINER" = true ]; then echo "  - silo-log-pull.tar     Container image (Docker/Podman)"; fi)
  - docs/                 Complete documentation
  - scripts/              Setup and utility scripts
$(if [ "$INCLUDE_PYTHON" = true ]; then echo "  - offline-extract.sh    Python setup script"; fi)
$(if [ "$INCLUDE_CONTAINER" = true ] && [ "$INCLUDE_PYTHON" = true ]; then echo "  - offline-extract-container.sh   Container setup script"; fi)
$(if [ "$INCLUDE_CONTAINER" = true ] && [ "$INCLUDE_PYTHON" = false ]; then echo "  - offline-extract.sh    Container setup script"; fi)
  - README-OFFLINE.txt    This file

QUICK START:

$(if [ "$INCLUDE_PYTHON" = true ]; then cat <<PYTHON_SECTION

  Python Deployment:
    1. Extract this archive: unzip $OUTPUT_BASENAME
    2. Run setup script: ./offline-extract.sh
    3. Follow on-screen instructions
PYTHON_SECTION
fi)

$(if [ "$INCLUDE_CONTAINER" = true ]; then cat <<CONTAINER_SECTION

  Container Deployment:
    1. Extract this archive: unzip $OUTPUT_BASENAME
    2. Run setup script: ./offline-extract$(if [ "$INCLUDE_PYTHON" = true ]; then echo "-container"; fi).sh
    3. Follow on-screen instructions
CONTAINER_SECTION
fi)

CONFIGURATION:

  See docs/configuration-reference.md for complete configuration details.

  Quick start:
    1. Copy app/data/example_silo_config.json to app/data/silo_config.json
    2. Edit silo_config.json with your organization name
    3. Create app/data/token.txt with your API token

RUNNING:

$(if [ "$INCLUDE_PYTHON" = true ]; then cat <<PYTHON_RUN

  Python deployment after setup:
    cd app
    source venv/bin/activate
    python silo_batch_pull.py
PYTHON_RUN
fi)

$(if [ "$INCLUDE_CONTAINER" = true ]; then cat <<CONTAINER_RUN

  Container deployment after setup:
    cd app
    docker run --rm -v \$(pwd)/data:/data silo-log-pull
    (or: podman run --rm -v \$(pwd)/data:/data silo-log-pull)
CONTAINER_RUN
fi)

DOCUMENTATION:

  All documentation is in the docs/ directory:
    - README.md                      Documentation index
    - configuration-reference.md     All settings and options
$(if [ "$INCLUDE_PYTHON" = true ]; then echo "    - python-guide.md               Python deployment guide"; fi)
$(if [ "$INCLUDE_CONTAINER" = true ]; then echo "    - container-guide.md            Container deployment guide"; fi)
    - scheduled-execution.md        Automation setup
    - example_configs/              Example configurations

SUPPORT:

  See https://gitlab.com/breakwaterlabs/silo-log-pull for updates and support.

================================================================================
README_EOF

# Create the zip archive
echo ""
echo -e "${GREEN}Creating offline package archive...${RESET}"

# Remove old zip if it exists
rm -f "$OUTPUT_PATH"

echo -e "${GRAY}Compressing archive...${RESET}"
cd "$TEMP_DIR"
zip -r "$OUTPUT_PATH" . -x "*.pyc" "__pycache__/*" "*/__pycache__/*" "data_dir.txt" > /dev/null

# Clean up temp directory
echo -e "${GRAY}Cleaning up...${RESET}"
cd "$REPOBASE"
rm -rf "$TEMP_DIR"

# Display summary
echo ""
echo -e "${GREEN}============================================${RESET}"
echo -e "${GREEN}Offline package created!${RESET}"
echo -e "${GREEN}============================================${RESET}"
echo ""
echo -e "${RESET}Package location: $OUTPUT_PATH${RESET}"
FILE_SIZE=$(du -h "$OUTPUT_PATH" | cut -f1)
echo -e "${RESET}Package size: $FILE_SIZE${RESET}"
echo ""
echo -e "${CYAN}To use on an offline system:${RESET}"
echo ""
echo "  1. Transfer the zip file to the offline system"
echo ""
echo "  2. Extract the archive:"
echo "     unzip $OUTPUT_BASENAME"
echo ""
echo "  3. Run the appropriate extraction script:"
if [ "$INCLUDE_PYTHON" = true ]; then
    echo "     Python: ./offline-extract.sh"
fi
if [ "$INCLUDE_CONTAINER" = true ]; then
    if [ "$INCLUDE_PYTHON" = true ]; then
        echo "     Container: ./offline-extract-container.sh"
    else
        echo "     ./offline-extract.sh"
    fi
fi
echo ""
echo "  4. Configure and run - see README-OFFLINE.txt in the package"
echo ""
