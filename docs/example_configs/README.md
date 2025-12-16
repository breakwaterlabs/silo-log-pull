# Example Configs

These directories contain example configurations demonstrating different usage scenarios for the silo-log-pull script.

## Configuration Files

Each example configuration typically includes:

- **`silo_config.json`** - Main configuration file
- **`seccure_key.txt`** - Seccure passphrase (only needed when decryption options are enabled)
- **`token.txt`** - Authentic8 API key (only needed when downloading logs from the API)

## Directory Structure and Paths

The script uses a `data_dir` setting (default: `"data"`) as the base directory for all configuration and log files. All file paths in the configuration are resolved relative to this directory unless they are absolute paths.

### Path Resolution

- If a path in the config is **relative** (e.g., `"token.txt"`), it's resolved as: `<data_dir>/<filename>`
- If a path in the config is **absolute** (e.g., `"C:\secrets\token.txt"`), it's used as-is
- The `data_dir` itself can be either relative (to the script location) or absolute

### Example Directory Layout

```
silo-log-pull/
└── app/
    ├── silo_batch_pull.py
    ├── requirements.txt
    └── data/                  # data_dir (default)
        ├── silo_config.json       # settings_file
        ├── token.txt              # api_token_file
        ├── seccure_key.txt        # seccure_passphrase_file
        └── logs/                  # log_in_directory and log_out_directory
            ├── silo_encrypted_2024-01-01.json
            └── silo_decrypted_2024-01-01.json
```

## Using Example Configs

To use an example configuration:

1. Copy the example directory contents to your `data/` directory
2. Edit `silo_config.json` to set your organization name
3. Add your API token to `token.txt` (if downloading from API)
4. Add your seccure passphrase to `seccure_key.txt` (if using decryption)
5. Run the script

## Available Examples

Descriptions of each scenario can be found in the respective README files under each directory:

- **general-oneshot-download-and-decrypt/** - Single-system download and decrypt
- **2-step_lowside/** - Download encrypted logs without decryption keys
- **2-step_highside/** - Decrypt previously downloaded logs on a secure system
