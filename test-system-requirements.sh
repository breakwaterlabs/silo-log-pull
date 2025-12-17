#!/usr/bin/env bash

#==============================================================================
# System Requirements Test Script for Linux/macOS
#==============================================================================
# This script checks system requirements for silo-log-pull application.
# It identifies available deployment modes based on installed software.
#
# Usage: ./test-system-requirements.sh

set -o pipefail

# ANSI color codes
GREEN='\033[0;32m'
RED='\033[0;31m'
CYAN='\033[0;34m'
CYAN='\e[0;36m'
YELLOW='\033[0;33m'
RESET='\033[0m'

# Terminal-compatible symbols
CHECK_MARK= " + " #"✅" #"✓"
X_MARK= " X " #"✗"
INFO_MARK=" ? " #"ℹ"

# Global variables
declare -A INFO
FAILURES=0
AVAILABLE_MODES=()

#==============================================================================
# Helper Functions
#==============================================================================

write_test_result() {
    local status="$1"
    local message="$2"
    local value="$3"
    local info_name="$4"
    local info_value="${5:-$value}"
    local indent="${6:-}"

    # Store in info array if info_name is provided
    if [[ -n "$info_name" ]]; then
        INFO["$info_name"]="$info_value"
    fi

    # Set color and symbol based on status
    local color symbol
    case "$status" in
        Pass)
            color=$GREEN
            symbol="+"
            ;;
        Fail)
            color=$RED
            symbol="X"
            ((FAILURES++))
            ;;
        Info)
            color=$RESET
            symbol="-"
            ;;
        Warn)
            color=$YELLOW
            symbol="!"
            ;;
    esac

    # Calculate width for alignment at column 45
    # Format: [indent] [symbol]  [message with padding]: [value]
    local width=$((50 - ${#indent} - 4 - 2))  # 45 - indent - " X  " - ": "

    # Output with or without value
    if [[ -n "$value" ]]; then
        printf "${indent}${color} %s  %-${width}s${RESET}: ${YELLOW}%s${RESET}\n" "$symbol" "$message" "$value"
    else
        printf "${indent}${color} %s  %s${RESET}\n" "$symbol" "$message"
    fi
}

write_section_header() {
    local title="$1"
    local major="$2"
    local color=$CYAN

    if [[ "$major" == "true" ]]; then
        echo -e "\n${color}========================================${RESET}"
        echo -e "${color}  ${title}${RESET}"
        echo -e "${CYAN}========================================${RESET}"
    else
        echo -e "\n${CYAN}=== ${title} ===${RESET}"
    fi
}

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

#==============================================================================
# General System Checks
#==============================================================================

test_os_version() {
    write_section_header "General System Information"

    local os_info
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        local macos_version
        macos_version=$(sw_vers -productVersion 2>/dev/null)
        local macos_name
        macos_name=$(sw_vers -productName 2>/dev/null)
        os_info="${macos_name} ${macos_version}"
        write_test_result "Info" "Operating System" "$os_info" "os_version"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        # Linux
        if [[ -f /etc/os-release ]]; then
            # shellcheck disable=SC1091
            source /etc/os-release
            os_info="${NAME} ${VERSION_ID:-}"
        else
            os_info="Linux (unknown distribution)"
        fi
        write_test_result "Info" "Operating System" "$os_info" "os_version"
    else
        write_test_result "Info" "Operating System" "Unknown (${OSTYPE})" "os_version"
    fi

    # Kernel version
    local kernel_version
    kernel_version=$(uname -r 2>/dev/null)
    if [[ -n "$kernel_version" ]]; then
        write_test_result "Info" "Kernel Version" "$kernel_version" "kernel_version"
    fi
}

test_shell_version() {
    if [[ -n "$BASH_VERSION" ]]; then
        write_test_result "Info" "Shell Version" "bash ${BASH_VERSION}" "shell_version"
    else
        write_test_result "Info" "Shell Version" "$(basename "$SHELL")" "shell_version"
    fi
}

#==============================================================================
# Python Mode Checks
#==============================================================================

test_python_installed() {
    write_section_header "Python Mode Availability"

    if command_exists python3; then
        local python_version
        python_version=$(python3 --version 2>&1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')

        if [[ -n "$python_version" ]]; then
            write_test_result "Pass" "Python 3 is installed, Version" "$python_version" "python_version"
            AVAILABLE_MODES+=("Python")
            return 0
        fi
    elif command_exists python; then
        local python_version
        python_version=$(python --version 2>&1)

        if [[ "$python_version" =~ Python\ 3\. ]]; then
            python_version=$(echo "$python_version" | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')
            write_test_result "Pass" "Python 3 is installed, Version" "$python_version" "python_version"
            AVAILABLE_MODES+=("Python")
            return 0
        fi
    fi

    write_test_result "Fail" "Python 3 is not installed or not in PATH" "" "python_available" "false"
    return 1
}

test_python_requirements() {
    local requirements_path="${BASH_SOURCE%/*}/app/requirements.txt"

    # If running from a different directory, try to find requirements.txt
    if [[ ! -f "$requirements_path" ]]; then
        requirements_path="./app/requirements.txt"
    fi

    if [[ ! -f "$requirements_path" ]]; then
        write_test_result "Info" "requirements.txt not found, skipping dependency check"
        return 1
    fi

    local python_cmd
    if command_exists python3; then
        python_cmd="python3"
    elif command_exists python; then
        python_cmd="python"
    else
        return 1
    fi

    # Try to check installed packages
    if ! $python_cmd -m pip --version >/dev/null 2>&1; then
        write_test_result "Warn" "pip is not available to verify dependencies"
        return 1
    fi

    local installed_packages
    installed_packages=$($python_cmd -m pip list --format=freeze 2>/dev/null | tr '[:upper:]' '[:lower:]')

    local missing_packages=()
    while IFS= read -r line; do
        # Skip comments and empty lines
        [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue

        # Extract package name (before any version specifier)
        local package_name
        package_name=$(echo "$line" | sed -E 's/([a-zA-Z0-9_-]+).*/\1/' | tr '[:upper:]' '[:lower:]')

        if ! echo "$installed_packages" | grep -iq "^${package_name}=="; then
            missing_packages+=("$package_name")
        fi
    done < "$requirements_path"

    if [[ ${#missing_packages[@]} -eq 0 ]]; then
        write_test_result "Pass" "All requirements.txt dependencies are met"
        return 0
    else
        write_test_result "Fail" "Missing Python packages" "${missing_packages[*]}"
        return 1
    fi
}

#==============================================================================
# Container Mode Checks
#==============================================================================

test_container_tools() {
    write_section_header "Container Mode Availability"

    local has_docker=false
    local has_podman=false
    local has_compose=false
    local docker_daemon_ok=false

    # Check for Docker
    if command_exists docker; then
        local docker_version
        docker_version=$(docker --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)

        if [[ -n "$docker_version" ]]; then
            write_test_result "Pass" "Docker is installed, Version" "$docker_version" "docker_version"
            has_docker=true

            # Check if Docker daemon is reachable (sub-check)
            if docker info >/dev/null 2>&1; then
                write_test_result "Pass" "Docker daemon is reachable" "" "docker_running" "true" "  "
                docker_daemon_ok=true
            else
                write_test_result "Fail" "Docker daemon is not reachable" "" "docker_running" "false" "  "
            fi
        fi
    else
        write_test_result "Fail" "Docker is not installed" "" "docker_available" "false"
    fi

    # Check for Podman
    if command_exists podman; then
        local podman_version
        podman_version=$(podman --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')

        if [[ -n "$podman_version" ]]; then
            write_test_result "Pass" "Podman is installed, Version" "$podman_version" "podman_version"
            has_podman=true
        fi
    else
        write_test_result "Fail" "Podman is not installed" "" "podman_available" "false"
    fi

    # Check for Docker Compose (standalone binary)
    if command_exists docker-compose; then
        local compose_version
        compose_version=$(docker-compose --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')

        if [[ -n "$compose_version" ]]; then
            write_test_result "Pass" "Docker Compose (standalone) is installed" "$compose_version" "docker_compose_version"
            has_compose=true
        fi
    # Check for docker compose plugin (only if standalone not found)
    elif command_exists docker && docker compose version >/dev/null 2>&1; then
        local compose_version
        compose_version=$(docker compose version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')

        if [[ -n "$compose_version" ]]; then
            write_test_result "Pass" "Docker Compose (plugin) is installed" "$compose_version" "docker_compose_plugin_version"
            has_compose=true
        fi
    else
        write_test_result "Warn" "Docker Compose is not installed" "" "docker_compose_available" "false"
    fi

    # Determine if Container Mode is available
    if [[ "$has_docker" == "true" && "$docker_daemon_ok" == "true" ]] || [[ "$has_podman" == "true" ]]; then
        
        INFO["container_mode_available"]="true"

        # Set which specific tools are available
        if [[ "$has_docker" == "true" && "$docker_daemon_ok" == "true" ]]; then
            AVAILABLE_MODES+=("Container (Docker)")
            INFO["docker_usable"]="true"
        fi
        if [[ "$has_podman" == "true" ]]; then
            AVAILABLE_MODES+=("Container (Podman)")
            INFO["podman_usable"]="true"
        fi
    else
        INFO["container_mode_available"]="false"
    fi

    return 0
}

#==============================================================================
# Architecture and CPU Checks
#==============================================================================

test_architecture() {
    write_section_header "Architecture Information"

    local arch
    arch=$(uname -m)
    write_test_result "Info" "CPU Architecture" "$arch" "architecture"

    # Check for virtualization support on Linux
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if [[ -f /proc/cpuinfo ]]; then
            if grep -qE '(vmx|svm)' /proc/cpuinfo; then
                write_test_result "Pass" "CPU supports virtualization (VMX/SVM)"
                INFO["virtualization_support"]="true"
            else
                write_test_result "Warn" "CPU virtualization support not detected" "" "virtualization_support" "false"
            fi
        fi
    fi
}

#==============================================================================
# Summary
#==============================================================================

print_summary() {
    write_section_header "Summary" "true"
    
    #write_section_header "System Information"
    #for key in "${!INFO[@]}"; do
        # Only print informational keys that are user-friendly
    #    case "$key" in
    #        os_version|kernel_version|shell_version|python_version|docker_version|podman_version|architecture)
    #            echo -e "  ${key}: ${INFO[$key]}"
    #            ;;
    #    esac
    #done

    write_section_header "Available Installation Modes"
    if [[ ${#AVAILABLE_MODES[@]} -eq 0 ]]; then
        echo -e "  ${YELLOW}No installation modes detected${RESET}"
        echo -e "  You may need to install Python 3 or a container runtime (Docker/Podman)"
    else
        for mode in "${AVAILABLE_MODES[@]}"; do
            echo -e "${GREEN} + ${mode} ${RESET}"
        done
    fi



    if [[ $FAILURES -gt 0 ]]; then
        echo -e "\n${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
        echo -e "${RED}You have ${FAILURES} failure(s).${RESET}"
        echo -e "${RED}Please review the issues above.${RESET}"
        echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
        echo -e "\nReview the documentation here:"
        echo -e "https://gitlab.com/breakwaterlabs/silo-log-pull/-/tree/main/docs"
    else
        echo -e "\n${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
        echo -e "${GREEN}All checks completed successfully!${RESET}"
        echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    fi
}

#==============================================================================
# Main Execution
#==============================================================================

main() {
    write_section_header "System Requirements Check" "true"

    # General checks
    test_os_version
    test_shell_version
    test_architecture

    # Python mode checks
    if test_python_installed; then
        test_python_requirements
    fi

    # Container mode checks
    test_container_tools

    # Print summary
    print_summary

    # Exit with appropriate code
    if [[ $FAILURES -gt 0 ]]; then
        exit 1
    else
        exit 0
    fi
}

# Run main function
main "$@"
