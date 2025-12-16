# silo-log-pull

A Python script for downloading and processing Silo logs from Authentic8. This script provides an improved, production-ready alternative to the original Python 2 examples, with support for automated workflows, Docker containers, and separation of duties scenarios.

## Features

- **Flexible Configuration** - JSON-based configuration with environment variable overrides
- **Multiple Deployment Options** - Run with Python, Docker, or Podman
- **Automated Workflows** - Designed for scheduled/unattended execution
- **Separation of Duties** - Support for low-side download / high-side decrypt workflows
- **Robust Error Handling** - Resilient to misconfiguration with helpful error messages
- **Cross-Platform** - Works on Windows and Linux

## Quick Start

Choose your platform and preferred method:

### Windows
- **[Windows with Rancher Desktop](docs/windows-rancher-desktop.md)** - Free container solution for business use
- **[Windows with Python](docs/windows-python.md)** - Direct Python execution

### Linux
- **[Linux Getting Started](docs/linux-getting-started.md)** - Docker, Podman, or Python options

### Basic Setup (All Platforms)

1. Download and extract this repository
2. Create a `data/` directory for configuration and logs
3. Copy an example config from `docs/example_configs/` to `data/silo_config.json`
4. Add your API token to `data/token.txt`
5. Edit `data/silo_config.json` to set your organization name
6. Run the script (see platform guides above for details)

The script uses a `data/` directory structure by default:
- `data/silo_config.json` - Main configuration file
- `data/token.txt` - Your Silo API token (32-character base64 string)
- `data/seccure_key.txt` - Your seccure passphrase (only needed if using encryption)
- `data/logs/` - Where logs are downloaded and processed

## Configuration Reference

### Configuration File Settings

The script reads settings from `data/silo_config.json` by default. All settings are optional except `api_org_name`. Below are all available settings with their default values:

```json
{
   "data_dir": "data",
   "settings_file": "silo_config.json",
   "non_interactive": false,
   "log_in_directory": "logs",
   "log_out_directory": "logs",
   "api_download_logs": true,
   "api_endpoint": "extapi.authentic8.com",
   "api_org_name": "",
   "api_token_file": "token.txt",
   "log_type": "ENC",
   "date_start": "",
   "fetch_num_days": 7,
   "seccure_passphrase_file": "seccure_key.txt",
   "seccure_decrypt_logs": false,
   "seccure_show_pubkey": false,
   "output_csv": false,
   "output_json": true,
   "output_console": true,
   "web_interface": true,
   "web_interface_port": 8080
}
```

### Setting Descriptions

| Setting | Type | Description |
|---------|------|-------------|
| `data_dir` | string | Base directory for config files and logs. All relative paths are resolved from here. Default: `"data"` |
| `settings_file` | string | Path to config file (relative to `data_dir` if not absolute). Default: `"silo_config.json"` |
| `non_interactive` | boolean | Disable interactive prompts for automated execution. Default: `false` |
| `log_in_directory` | string | Directory to import logs from when `api_download_logs` is false (relative to `data_dir` if not absolute). Default: `"logs"` |
| `log_out_directory` | string | Directory where processed logs are saved (relative to `data_dir` if not absolute). Default: `"logs"` |
| `api_download_logs` | boolean | If true, download logs from Silo API. If false, process existing logs from `log_in_directory`. Default: `true` |
| `api_endpoint` | string | Silo API endpoint. Default: `"extapi.authentic8.com"` |
| `api_org_name` | string | **Required.** Your organization name as shown in Silo Admin portal. |
| `api_token_file` | string | File containing your API token (relative to `data_dir` if not absolute). Default: `"token.txt"` |
| `log_type` | string | Log type to download. Options: `"ENC"` (encrypted), `"LOG"` (plaintext). Default: `"ENC"` |
| `date_start` | string | Start date in `YYYY-MM-DD` format. Leave blank for today. Default: `""` |
| `fetch_num_days` | integer | Number of days to fetch, counting back from `date_start`. Default: `7` |
| `seccure_passphrase_file` | string | File containing seccure passphrase for decryption (relative to `data_dir` if not absolute). Default: `"seccure_key.txt"` |
| `seccure_decrypt_logs` | boolean | Decrypt logs during processing. Requires seccure passphrase file. Default: `false` |
| `seccure_show_pubkey` | boolean | Display the public key for your passphrase. Default: `false` |
| `output_csv` | boolean | Save processed logs as CSV files. Default: `false` |
| `output_json` | boolean | Save processed logs as JSON files. Default: `true` |
| `output_console` | boolean | Display logs in console output. Default: `true` |
| `web_interface` | boolean | Enable web interface (future feature). Default: `true` |
| `web_interface_port` | integer | Port for web interface. Default: `8080` |

### Environment Variable Overrides

All settings can be overridden using environment variables with the format `SILO_<SETTING_NAME>` in uppercase:

```bash
export SILO_API_ORG_NAME="MyOrganization"
export SILO_FETCH_NUM_DAYS=30
export SILO_DATE_START="2024-01-01"
export SILO_SECCURE_DECRYPT_LOGS=true
```

Environment variables are applied in this order (later overrides earlier):
1. Script defaults
2. Environment variables
3. Configuration file settings

### Path Resolution

Paths in the configuration are resolved as follows:

- **Absolute paths** (e.g., `C:\secrets\token.txt` or `/etc/silo/token.txt`) are used as-is
- **Relative paths** (e.g., `token.txt` or `logs/`) are resolved relative to `data_dir`
- The `data_dir` itself can be absolute or relative to the script location

Example:
- If `data_dir` is `"data"` and `api_token_file` is `"token.txt"`, the full path is `data/token.txt`
- If `api_token_file` is `"/etc/silo/token.txt"`, that absolute path is used regardless of `data_dir`

## Installation

See the platform-specific guides for detailed installation instructions:
- [Windows with Rancher Desktop](docs/windows-rancher-desktop.md)
- [Windows with Python](docs/windows-python.md)
- [Linux Getting Started](docs/linux-getting-started.md)

### Requirements

**For Docker/Podman:**
- Docker or Podman container runtime
- No Python installation required on host

**For Python:**
- Python 3.6 or later (tested on 3.6 and 3.12)
- Optional: `seccure` package (only if using encryption features)

Install Python dependencies:
```bash
pip install -r requirements.txt
```

The `seccure` package has the following dependencies:
- [six](https://pypi.org/project/six/)
- [pycryptodome](https://pypi.org/project/pycryptodome/)
- [gmpy2](https://pypi.org/project/gmpy2/)

### Troubleshooting Dependencies

In cross-platform / offline scenarios, it may be necessary to compile one or more of the dependencies, which may bring in requirements for python3-devel, or to manually transfer the appropriate wheel files from pypi. It may also be necessary to rename some wheel files depending on your linux distribution.

I have found gmpy2 in particular to be problematic as it tends to prefer building from source which can work poorly in some environments. 

The following can be used to install the binary gmpy2 installation and ignore SSL errors (e.g. by upstream firewalls), which may be helpful in locked-down environments.
```
python -m  pip install --only-binary=:all: --trusted-host pypi.python.org --trusted-host files.pythonhosted.org gmpy2
python -m  pip install  --trusted-host pypi.python.org --trusted-host files.pythonhosted.org seccure
```

### Incompatible Platform

Some combinations of Linux distro and python version do not like the wheel files provided by PyPi.org (e.g. for pycryptodome) and complain of an incompatible platform.

To troubleshoot this, first determine what platform tags your version of python supports either from the command line: 

`python -m pip debug --verbose`

or from within the python interpreter

```python
import packaging.tags
tags = packaging.tags.sys_tags()
print('\n'.join([f'{tag.interpreter}-{tag.abi}-{tag.platform}' for tag in tags]))
```

Once you have that, you should be able to download the matching version from PyPi.org.

Note that some tags like `manylinux2014` and  `manylinux_2_17_x86_64` seem to be unsupported in some versions of pip. This can be worked around by renaming the problematic wheel file to a compatible tag before installing them:

```bash
cd /path/to/dependencies
mv gmpy2-2.1.5-cp36-cp36m-manylinux_2_17_x86_64.manylinux2014_x86_64.whl gmpy2-2.1.5-cp36-cp36m-linux_x86_64.whl
mv pycryptodome-3.20.0-cp35-abi3-manylinux_2_17_x86_64.manylinux2014_x86_64.whl pycryptodome-3.20.0-cp35-abi3-linux_x86_64.whl
python -m pip install --no-index --find-links /path/to/dependencies/ -r /path/to/requirements.txt
```



## Usage

### Quick Usage

**With Python:**
```bash
python3 silo_batch_pull.py
```

**With Docker:**
```bash
docker build -t silo-log-pull .
docker run --rm -v $(pwd)/data:/data silo-log-pull
```

**With Docker Compose:**
```bash
docker-compose up
```

For detailed usage instructions, see the platform-specific guides:
- [Windows with Rancher Desktop](docs/windows-rancher-desktop.md)
- [Windows with Python](docs/windows-python.md)
- [Linux Getting Started](docs/linux-getting-started.md)

### Usage Examples

#### Example 1: Download Last 30 Days of Encrypted Logs

Configuration file (`data/silo_config.json`):
```json
{
   "api_org_name": "YourOrganization",
   "fetch_num_days": 30,
   "log_type": "ENC",
   "seccure_decrypt_logs": false
}
```

#### Example 2: Download and Decrypt Logs

Configuration file (`data/silo_config.json`):
```json
{
   "api_org_name": "YourOrganization",
   "fetch_num_days": 7,
   "log_type": "ENC",
   "seccure_decrypt_logs": true,
   "seccure_show_pubkey": true,
   "output_csv": true,
   "output_json": true
}
```

Make sure your seccure passphrase is in `data/seccure_key.txt`.

#### Example 3: Process Existing Logs (No Download)

Configuration file (`data/silo_config.json`):
```json
{
   "api_download_logs": false,
   "log_in_directory": "logs",
   "log_out_directory": "logs_processed",
   "seccure_decrypt_logs": true
}
```

Place encrypted log files in `data/logs/`, and they will be decrypted to `data/logs_processed/`.

### Docker Usage Details

When running in Docker mode (detected via `DOCKER_CONTAINER=true`), the script automatically uses `/data` as the base directory for all configuration and log files.

**Basic Docker Run:**
```bash
docker run --rm -v $(pwd)/data:/data silo-log-pull
```

**With Environment Variable Overrides:**
```bash
docker run --rm \
  -v $(pwd)/data:/data \
  -e SILO_FETCH_NUM_DAYS=30 \
  -e SILO_DATE_START="2024-01-01" \
  -e SILO_OUTPUT_CSV=true \
  silo-log-pull
```

**Windows PowerShell:**
```powershell
docker run --rm -v ${PWD}/data:/data silo-log-pull
```

## Example Configurations

The `docs/example_configs/` directory contains ready-to-use configuration examples for common scenarios:

### General One-Shot Download and Decrypt
Location: `docs/example_configs/general-oneshot-download-and-decrypt/`

For single-system deployments where logs are downloaded and decrypted in one process. This is suitable for most use cases where security allows keeping the API token and decryption key on the same system.

### Two-Step Process: Low Side
Location: `docs/example_configs/2-step_lowside/`

For separation of duties workflows. This configuration downloads encrypted logs from the Silo API without decrypting them. The encrypted logs can then be transferred to a secure system for decryption.

**Use case:** System has API access but should not have decryption keys.

### Two-Step Process: High Side
Location: `docs/example_configs/2-step_highside/`

For separation of duties workflows. This configuration processes and decrypts logs that were previously downloaded on another system. No API connection is made.

**Use case:** Secure system has decryption keys but no API access.

See the [Example Configs README](docs/example_configs/README.md) for detailed information about using these configurations.

## Roadmap
 - [x] Update filesystem code to use cross-OS native code (current code relies on Windows conventions)
 - [x] Support arbitrary date ranges
 - [x] Support alternate directories for import and download

## License
See the LICENSE.md file for details.

## Project status
Active as of 2024-12-16
