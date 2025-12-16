# Python Deployment Guide

This guide covers running silo-log-pull directly with Python on any operating system.

## Prerequisites

- Python 3.6 or later
- Your Silo organization name and API token

## Installation

### Linux

**Ubuntu/Debian:**
```bash
sudo apt update
sudo apt install python3 python3-pip python3-dev gcc libgmp-dev
```

**RHEL/CentOS/Fedora:**
```bash
sudo dnf install python3 python3-pip python3-devel gcc gmp-devel
```

### Windows

1. Download from https://www.python.org/downloads/
2. Run the installer and check "Add Python to PATH"

Verify installation:
```powershell
python --version
```

## Setup

1. Download and extract the repository
2. Configure per the [Configuration Reference](configuration-reference.md#initial-configuration-steps)

## Install Dependencies and Run

**Linux/macOS:**
```bash
cd app
pip3 install -r requirements.txt
python3 silo_batch_pull.py
```

**Windows:**
```powershell
cd app
python -m pip install -r requirements.txt
python silo_batch_pull.py
```

Logs are written to `data/logs/`.

## Environment Variable Overrides

Override settings at runtime:

**Linux/macOS:**
```bash
export SILO_DATE_START="2024-01-01"
export SILO_FETCH_NUM_DAYS=30
python3 silo_batch_pull.py
```

**Windows PowerShell:**
```powershell
$env:SILO_DATE_START="2024-01-01"
$env:SILO_FETCH_NUM_DAYS="30"
python silo_batch_pull.py
```

See [Environment Variable Overrides](configuration-reference.md#environment-variable-overrides) for all options.

## Troubleshooting

### Python Not Found (Windows)
- Reinstall Python and check "Add Python to PATH"
- Restart PowerShell after installation
- Try `py` instead of `python`

### Dependency Installation Errors

**Linux - gmpy2 fails:**
```bash
# Ubuntu/Debian
sudo apt install build-essential libgmp-dev

# RHEL/CentOS/Fedora
sudo dnf groupinstall "Development Tools"
sudo dnf install gmp-devel
```

**Windows - gmpy2/pycryptodome errors:**
```powershell
python -m pip install --only-binary=:all: gmpy2 seccure
```

### API Token Errors
- Verify token is exactly 32 characters
- Check for extra spaces or newlines in `token.txt`

### Offline Installation
See [Offline Systems Guide](offline-systems.md#option-2-python-dependencies-transfer).

## Scheduled Execution

See [Scheduled Execution Guide](scheduled-execution.md) for cron, systemd, and Task Scheduler setup.

## Next Steps

- Review the [Configuration Reference](configuration-reference.md) for all settings
- See [Example Configs](example_configs/) for usage scenarios
