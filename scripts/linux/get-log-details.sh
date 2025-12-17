#!/usr/bin/env bash

#==============================================================================
# Get log directory details for offline bundling
# Returns formatted information about log directories including file counts
#==============================================================================

get_data_dir() {
    local script_base="$(cd "$(dirname "${BASH_SOURCE[0]}")"/../.. && pwd)"
    local data_dir_file="${script_base}/app/data_dir.txt"

    if [ -f "$data_dir_file" ]; then
        local data_dir_path=$(head -n1 "$data_dir_file" | tr -d '[:space:]')
        if [ -n "$data_dir_path" ] && [ -d "$data_dir_path" ] && [ -r "$data_dir_path" ]; then
            echo "$data_dir_path"
            return
        fi
    fi
    echo "${script_base}/app/data"
}

get_log_directories() {
    local data_dir="$1"
    local config_file="${data_dir}/silo_config.json"
    local log_in="logs"
    local log_out="logs"

    if [ -f "$config_file" ]; then
        # Use python to parse JSON if available
        if command -v python3 >/dev/null 2>&1; then
            log_in=$(python3 -c "import json; f=open('$config_file'); c=json.load(f); print(c.get('log_in_directory', 'logs'))" 2>/dev/null || echo "logs")
            log_out=$(python3 -c "import json; f=open('$config_file'); c=json.load(f); print(c.get('log_out_directory', 'logs'))" 2>/dev/null || echo "logs")
        fi
    fi

    # Resolve relative paths
    if [[ ! "$log_in" = /* ]]; then
        log_in="${data_dir}/${log_in}"
    fi
    if [[ ! "$log_out" = /* ]]; then
        log_out="${data_dir}/${log_out}"
    fi

    echo "$log_in|$log_out"
}

get_file_count_display() {
    local path="$1"
    if [ -d "$path" ]; then
        local count=$(find "$path" -maxdepth 1 -type f 2>/dev/null | wc -l)
        printf "%-13s" "$count files"
    else
        printf "%-13s" "(not found)"
    fi
}

# Main execution
DATA_DIR=$(get_data_dir)
LOG_DIRS=$(get_log_directories "$DATA_DIR")
LOG_IN=$(echo "$LOG_DIRS" | cut -d'|' -f1)
LOG_OUT=$(echo "$LOG_DIRS" | cut -d'|' -f2)

echo "$(get_file_count_display "$LOG_IN")$LOG_IN"
echo "$(get_file_count_display "$LOG_OUT")$LOG_OUT"
