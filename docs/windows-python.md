# Getting Started on Windows with Python

This guide will help you set up and run silo-log-pull on Windows using Python directly (without Docker/containers).

## Prerequisites

- Windows 10/11 (64-bit)
- Python 3.6 or later
- Your Silo organization name
- Your Silo API token (32-character base64 string)

## Step 1: Install Python

1. Download Python from: https://www.python.org/downloads/
2. Run the installer
3. **Important:** Check "Add Python to PATH" during installation
4. Complete the installation

## Step 2: Verify Installation

Open PowerShell or Command Prompt and verify Python is installed:

```powershell
python --version
```

You should see Python 3.6 or later.

## Step 3: Set Up Your Project

1. **Download this repository:**
   - Download the ZIP file from the repository
   - Extract it to a location like `C:\silo-log-pull`
   - Open PowerShell and navigate to the app directory:
   ```powershell
   cd C:\silo-log-pull\app
   ```

2. **Install Python dependencies:**

   If you will be using encryption/decryption features:
   ```powershell
   python -m pip install -r requirements.txt
   ```

   If you're only downloading logs without decryption, no additional dependencies are needed.

3. **Create your configuration files** -- See the [command reference](configuration-reference.md#initial-configuration-steps) for details.


## Step 4: Run the Script

```powershell
python silo_batch_pull.py
```

The script will:
- Read your configuration from `data\silo_config.json`
- Download logs from the Silo API
- Process and save them to `data\logs\`

## Step 5: View Your Logs

After the script completes, your logs will be in the `data\logs\` directory:

```powershell
dir data\logs
```

## Troubleshooting

### Python Not Found

If you get "python is not recognized":
- Make sure Python is installed
- Reinstall Python and check "Add Python to PATH"
- Restart PowerShell/Command Prompt after installation
- Try using `py` instead of `python`

### Installing Dependencies in Offline Environments

If your system doesn't have internet access, you'll need to download dependencies on another machine:

On a machine with internet:
```powershell
mkdir dependencies
python -m pip download -r requirements.txt -d dependencies
```

Copy the `dependencies` folder to your target machine, then:
```powershell
python -m pip install --no-index --find-links dependencies -r requirements.txt
```

### Dependency Installation Errors

If `pip install` fails with gmpy2 or pycryptodome errors, try installing with binary-only mode:

```powershell
python -m pip install --only-binary=:all: --trusted-host pypi.python.org --trusted-host files.pythonhosted.org gmpy2
python -m pip install --trusted-host pypi.python.org --trusted-host files.pythonhosted.org seccure
```

### Missing Config File Error

If you see an error about missing `silo_config.json`:
- The script will create a default config file at `data\silo_config.json`
- Edit this file to add your organization name
- Run the script again

### API Token Errors

If you see "Check your API token" errors:
- Verify your token is exactly 32 characters
- Make sure there are no extra spaces or newlines in `token.txt`
- Confirm you're using the correct token for your organization

## Advanced Usage

### Override Settings via Environment Variables

You can override configuration settings without editing the config file:

```powershell
$env:SILO_DATE_START="2024-01-01"
$env:SILO_FETCH_NUM_DAYS="30"
python silo_batch_pull.py
```

Available environment variables use the format `SILO_<SETTING_NAME>` in uppercase. See the main README for a complete list.

### Non-Interactive Mode

For automated/scheduled runs, use non-interactive mode to disable prompts:

Edit `data\silo_config.json` and set:
```json
"non_interactive": true
```

Or use an environment variable:
```powershell
$env:SILO_NON_INTERACTIVE="true"
python silo_batch_pull.py
```

### Scheduled Execution

Use Windows Task Scheduler to run the script automatically:

1. Open Task Scheduler
2. Create a new task with the action:
   - Program: `C:\Users\YourUser\AppData\Local\Programs\Python\Python3XX\python.exe`
   - Arguments: `silo_batch_pull.py`
   - Start in: `C:\silo-log-pull\app`

Or create a batch file for easier scheduling:

```powershell
notepad run_silo.bat
```

Add:
```batch
@echo off
cd /d C:\silo-log-pull\app
python silo_batch_pull.py
```

Then schedule the batch file in Task Scheduler.

## Next Steps

- Review the [Configuration Reference](../README.md#configuring-the-script) for all available settings
- Check out [Example Configs](example_configs/README.md) for different usage scenarios
- Set up scheduled automated pulls using Task Scheduler
