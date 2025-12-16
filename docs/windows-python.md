# Getting Started on Windows with Python

This guide covers running silo-log-pull on Windows using Python directly (without containers).

## Prerequisites

- Windows 10/11 (64-bit)
- Python 3.6 or later
- Your Silo organization name and API token

## Step 1: Install Python

1. Download from https://www.python.org/downloads/
2. Run the installer and check "Add Python to PATH"

Verify installation:
```powershell
python --version
```

## Step 2: Set Up Your Project

1. Download and extract the repository to `C:\silo-log-pull`
2. Configure per the [Configuration Reference](configuration-reference.md#initial-configuration-steps)

## Step 3: Install Dependencies and Run

```powershell
cd C:\silo-log-pull\app
python -m pip install -r requirements.txt  # Required for encryption features
python silo_batch_pull.py
```

Logs are written to `data\logs\`.

## Troubleshooting

### Python Not Found
- Reinstall Python and check "Add Python to PATH"
- Restart PowerShell after installation
- Try `py` instead of `python`

### Dependency Installation Errors
For gmpy2 or pycryptodome errors:
```powershell
python -m pip install --only-binary=:all: gmpy2 seccure
```

### Offline Installation
See [Offline Systems Guide](offline-systems.md#option-2-python-dependencies-transfer).

### API Token Errors
- Verify token is exactly 32 characters
- Check for extra spaces or newlines in `token.txt`

## Advanced Usage

### Environment Variable Overrides

```powershell
$env:SILO_DATE_START="2024-01-01"
$env:SILO_FETCH_NUM_DAYS="30"
python silo_batch_pull.py
```

See [Environment Variable Overrides](configuration-reference.md#environment-variable-overrides) for details.

### Scheduled Execution

Use Windows Task Scheduler:
- Program: Path to `python.exe`
- Arguments: `silo_batch_pull.py`
- Start in: `C:\silo-log-pull\app`

## Next Steps

- Review the [Configuration Reference](configuration-reference.md) for all available settings
- See [Example Configs](example_configs/) for different usage scenarios
