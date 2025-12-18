# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**silo-log-pull** is a cross-platform tool for downloading and processing Silo audit logs from Authentic8. It supports both container-based (Docker/Podman) and native Python execution, with special considerations for air-gapped/offline systems and separation-of-duties workflows.

### Core Application

- **Primary script**: `app/silo_batch_pull.py` - Single Python file that handles all log downloading, decryption, and processing
- **Container**: Multi-stage Alpine-based Dockerfile for minimal footprint
- **Dependencies**: pycryptodome, seccure (for log decryption), setuptools

### Platform-Specific Setup Menus

The repository provides interactive setup menus for both platforms:

- **Linux/macOS**: `setup-linux.sh` - Bash-based menu (11 options)
- **Windows**: `setup-win.ps1` - PowerShell-based menu (10 options)

These menus provide access to installation, building, bundling, scheduling, and execution.

## Architecture & Key Design Patterns

### Data Directory Resolution (Critical)

The application uses a **three-tier override system** for locating configuration and data files:

1. **Default**: `app/data/` directory
2. **data_dir.txt override**: File in `app/` directory containing alternate path
3. **Environment variable override**: `SILO_DATA_DIR` environment variable (highest priority)

All scripts and the Python application implement this resolution order consistently. The `data_dir.txt` file is the recommended method for custom paths as it persists across sessions without environment configuration.

### Configuration Priority (Environment Variable Overrides)

The Python application supports **three layers of configuration**:

1. **Hard-coded defaults** in `silo_batch_pull.py`
2. **Environment variables** prefixed with `SILO_` (e.g., `SILO_API_ORG_NAME`)
3. **JSON configuration file** (`silo_config.json`) - **highest priority**

When running in Docker (`IS_DOCKER=True`), the application expects configuration at `/data` mount point.

### Cross-Platform Script Organization

Scripts follow a **parallel structure** across platforms:

```
scripts/
├── linux/          # Bash scripts (*.sh)
└── win/            # PowerShell scripts (*.ps1)
```

Each platform has identical functionality but platform-specific implementations. Scripts are designed to be **standalone-capable** (can run outside the menu system).

### Podman vs Docker Preference

All Linux container scripts **prefer Podman over Docker** when both are available. This design supports:
- Better systemd integration
- Rootless containers by default
- No daemon requirement

Detection pattern used throughout:
```bash
if command -v podman >/dev/null 2>&1; then
    CONTAINER_CMD="podman"
elif command -v docker >/dev/null 2>&1; then
    CONTAINER_CMD="docker"
fi
```

### Offline/Air-Gapped Support

The repository has extensive offline capabilities via `prepare-offline-bundle.sh/ps1`:

- **Python mode**: Downloads pip dependencies to `silo-dependencies/`
- **Container mode**: Exports container image as tar
- **Combined mode**: Both Python and container in single bundle
- All bundles extract to `silo-log-pull/` toplevel directory
- Extraction scripts support parameterized execution (`--install`, `--run`, `--load`)

### Silent/Non-Interactive Execution

All user-facing scripts support `--non-interactive` (bash) or `-NonInteractive` (PowerShell) flags for automated/scheduled execution. The core Python application honors `non_interactive` config setting or `SILO_NON_INTERACTIVE` environment variable.

## Development Commands

### Building Container Images

```bash
# Local build
docker build -t silo-log-pull .

# Using menu system (Linux)
./setup-linux.sh
# Select: 3. Build local container

# Using menu system (Windows)
.\setup-win.ps1
# Select: 3. Build local container
```

### Python Development Setup

**Linux/macOS:**
```bash
cd app
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt

# Run directly
python silo_batch_pull.py
```

**Windows:**
```powershell
cd app
python -m venv venv
.\venv\Scripts\Activate.ps1
pip install -r requirements.txt

# Run directly
python silo_batch_pull.py
```

### Testing System Capabilities

```bash
# Linux - Detects Python, containers, git, exports environment variables
./scripts/linux/system-test.sh

# Windows - PowerShell equivalent
.\scripts\win\system-test.ps1
```

These scripts export mode availability as environment variables:
- `PYTHON_AVAILABLE`, `PYTHON_VERSION`, `PYTHON_DECRYPTION_SUPPORT`
- `DOCKER_AVAILABLE`, `PODMAN_AVAILABLE`, `CONTAINER_MODE_AVAILABLE`
- `GIT_AVAILABLE`, `GIT_VERSION`

### Creating Offline Bundles

```bash
# Interactive mode (Linux)
./scripts/linux/prepare-offline-bundle.sh

# Non-interactive with flags
./scripts/linux/prepare-offline-bundle.sh --python --container --logs --non-interactive

# Windows equivalent
.\scripts\win\prepare-offline-bundle.ps1 -IncludePython -IncludeContainer
```

### Git Operations

Scripts maintain git safety protocols:
- Never use `--force`, `--no-verify`, or `--amend` unless explicitly requested
- Avoid destructive operations on main/master branches
- All commits include co-authorship attribution

When creating commits:
```bash
# Git commits must include attribution in message
🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>
```

## File Organization

### Configuration Files

- `app/data/silo_config.json` - Main configuration (created from `example_silo_config.json`)
- `app/data/token.txt` - API token (32 characters)
- `app/data/seccure_key.txt` - Decryption passphrase (optional)
- `app/data_dir.txt` - Data directory override (optional)

### Log Directories (relative to data directory)

- `logs/` - Input logs (when not downloading from API) OR output logs (default)
- `logs_out/` - Output logs (when specified separately)

### Script Patterns

All bash scripts use:
- `set -e` for error handling
- Color codes: `GREEN`, `RED`, `YELLOW`, `CYAN`, `RESET`
- Argument parsing with `while [[ $# -gt 0 ]]` pattern
- Command summaries at end showing exact command + cron/Task Scheduler syntax

All PowerShell scripts use:
- `[CmdletBinding()]` parameter blocks
- Switch parameters for flags
- Consistent color scheme with `-ForegroundColor`
- Command summaries showing exact command + Task Scheduler syntax

## Line Endings & Platform Considerations

The repository uses `.gitattributes` to enforce:
- **LF** for: `*.sh`, `*.py`, `*.json`, `*.txt`, `*.md`, `Dockerfile`
- **CRLF + UTF-8 BOM** for: `*.ps1`
- Binary handling for: `*.zip`, `*.tar`, `*.gz`

When editing cross-platform scripts, respect these line ending conventions.

## Common Workflows

### Adding New Setup Menu Options

Both `setup-linux.sh` and `setup-win.ps1` follow the same pattern:

1. Add to `show_menu()` function with appropriate numbering
2. Add case statement in main loop
3. Call target script from `scripts/linux/` or `scripts/win/`
4. Use `Invoke-ScriptAndPause` (Windows) or direct execution with pause (Linux)

### Creating New Cross-Platform Scripts

When adding functionality:

1. Create both `scripts/linux/<name>.sh` and `scripts/win/<name>.ps1`
2. Implement identical functionality with platform-specific syntax
3. Add `--non-interactive` / `-NonInteractive` parameter
4. Include command summary display at end
5. Follow color scheme and output patterns
6. Ensure standalone execution works (test outside menu)

### Working with Offline Extraction Scripts

The offline bundle scripts generate extraction scripts dynamically via heredocs. When modifying:

- Python extraction: Support `--install` and `--run` flags (bash) or `-Install` and `-Run` (PowerShell)
- Container extraction: Support `--load` and `--run` flags (bash) or `-Load` and `-Run` (PowerShell)
- Default behavior: Install/load only (no auto-run)
- Maintain Podman preference in generated Linux scripts

## Important Implementation Notes

### Container Detection in Python

The application detects container execution via `IS_DOCKER` flag:
```python
IS_DOCKER = os.environ.get('DOCKER_CONTAINER', '').lower() in ('true', '1', 'yes')
```

When `IS_DOCKER=True`:
- Expects data at `/data` mount point
- Forces non-interactive mode
- Adjusts logging behavior

### Configuration File Updates

When modifying `silo_config.json` schema:
1. Update `default_settings` dict in `silo_batch_pull.py`
2. Update `docs/configuration-reference.md` table
3. Update `app/data/example_silo_config.json`
4. Consider environment variable mappings (prefix: `SILO_`)

### Backup Functionality

The backup scripts (`backup-config.sh/ps1`) specifically:
- Include all files from data directory
- Exclude `logs/`, `logs_out/`, `logs_in/` directories
- Exclude `*.log` files
- Include `data_dir.txt` if present
- Generate README with restoration instructions

### Execution Modes

The application supports two primary modes:

1. **API mode** (`api_download_logs: true`): Download logs from Authentic8 API
2. **Import mode** (`api_download_logs: false`): Process logs from `log_in_directory`

Both modes output to `log_out_directory` with optional CSV/JSON output and console display.
