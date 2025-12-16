# Configuration Reference

This document provides detailed information about all configuration settings available in silo-log-pull.

## Configuration File Location

By default, the script looks for `data/silo_config.json`. You can override this using the `SILO_DATA_DIR` and `SILO_SETTINGS_FILE` environment variables.

## Initial Configuration Steps
1. **Download the script package and set up locally.** See the platform-specific help guides on doing this.
2. **Edit the configuration file:**

   The `app/data/` directory already contains an [`example_silo_config.json`](../app/data/example_silo_config.json) file. Edit this file to set your organization name and adjust any other settings you need:

   ```bash
   nano app/data/silo_config.json
   ```

   Set `"api_org_name"` to your organization name, save and exit.


3. **(Optional) Add API token for log download:**

   Log download from the internet requires an API key from Authentic8 in `token.txt`. See [`example_token.txt`](../app/data/example_token.txt) for format:

   ```bash
   nano app/data/token.txt
   ```

   Paste your token, save and exit.

4. **(Optional) Add seccure passphrase if using encryption:**

   Decrypting encrypted logs requires a seccure decryption passphrase. See [`example_seccure_key.txt`](../../app/data/example_seccure_key.txt) for format:

   ```bash
   nano app/data/seccure_key.txt
   ```

   Paste in your plaintext passphrase, save and exit.

---

See the [command reference](configuration-reference.md) and the [general oneshot configuration example](example_configs/general-oneshot-download-and-decrypt/) for configuration help.


## All Available Settings

Below are all available settings with their default values:

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

## Setting Descriptions

| Setting | Type | Default | Description |
|---------|------|---------|-------------|
| `data_dir` | string | `"data"` | Base directory for config files and logs. All relative paths are resolved from here. |
| `settings_file` | string | `"silo_config.json"` | Path to config file (relative to `data_dir` if not absolute). |
| `non_interactive` | boolean | `false` | Disable interactive prompts for automated execution. |
| `log_in_directory` | string | `"logs"` | Directory to import logs from when `api_download_logs` is false (relative to `data_dir` if not absolute). |
| `log_out_directory` | string | `"logs"` | Directory where processed logs are saved (relative to `data_dir` if not absolute). |
| `api_download_logs` | boolean | `true` | If true, download logs from Silo API. If false, process existing logs from `log_in_directory`. |
| `api_endpoint` | string | `"extapi.authentic8.com"` | Silo API endpoint. |
| `api_org_name` | string | `""` | **Required.** Your organization name as shown in Silo Admin portal. |
| `api_token_file` | string | `"token.txt"` | File containing your API token (relative to `data_dir` if not absolute). |
| `log_type` | string | `"ENC"` | Log type to download. Options: `"ENC"` (encrypted), `"LOG"` (plaintext). |
| `date_start` | string | `""` | Start date in `YYYY-MM-DD` format. Leave blank for today. |
| `fetch_num_days` | integer | `7` | Number of days to fetch, counting back from `date_start`. |
| `seccure_passphrase_file` | string | `"seccure_key.txt"` | File containing seccure passphrase for decryption (relative to `data_dir` if not absolute). |
| `seccure_decrypt_logs` | boolean | `false` | Decrypt logs during processing. Requires seccure passphrase file. |
| `seccure_show_pubkey` | boolean | `false` | Display the public key for your passphrase. |
| `output_csv` | boolean | `false` | Save processed logs as CSV files. |
| `output_json` | boolean | `true` | Save processed logs as JSON files. |
| `output_console` | boolean | `true` | Display logs in console output. |
| `web_interface` | boolean | `true` | Enable web interface (future feature). |
| `web_interface_port` | integer | `8080` | Port for web interface. |

## Environment Variable Overrides

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

## Path Resolution

Paths in the configuration are resolved as follows:

- **Absolute paths** (e.g., `C:\secrets\token.txt` or `/etc/silo/token.txt`) are used as-is
- **Relative paths** (e.g., `token.txt` or `logs/`) are resolved relative to `data_dir`
- The `data_dir` itself can be absolute or relative to the script location

### Examples

If `data_dir` is `"data"` and `api_token_file` is `"token.txt"`:
- Full path: `data/token.txt`

If `api_token_file` is `"/etc/silo/token.txt"`:
- That absolute path is used regardless of `data_dir`

If `data_dir` is `"/opt/silo"` and `log_in_directory` is `"logs"`:
- Full path: `/opt/silo/logs`

## Common Configuration Patterns

### Minimal Configuration (Download Only)

```json
{
   "api_org_name": "YourOrganization"
}
```

All other settings will use defaults. This downloads the last 7 days of encrypted logs.

### Download and Decrypt

```json
{
   "api_org_name": "YourOrganization",
   "seccure_decrypt_logs": true,
   "output_csv": true
}
```

### Process Existing Logs (No Download)

```json
{
   "api_download_logs": false,
   "log_in_directory": "encrypted_logs",
   "log_out_directory": "decrypted_logs",
   "seccure_decrypt_logs": true
}
```

### Automated/Scheduled Runs

```json
{
   "non_interactive": true,
   "api_org_name": "YourOrganization",
   "output_console": false,
   "fetch_num_days": 1
}
```

### Custom Date Range

```json
{
   "api_org_name": "YourOrganization",
   "date_start": "2024-01-01",
   "fetch_num_days": 90
}
```

## Using Environment Variables with Docker

When running in Docker, environment variables are particularly useful:

```bash
docker run --rm \
  -v $(pwd)/data:/data \
  -e SILO_API_ORG_NAME="YourOrg" \
  -e SILO_FETCH_NUM_DAYS=30 \
  -e SILO_DATE_START="2024-01-01" \
  -e SILO_SECCURE_DECRYPT_LOGS=true \
  silo-log-pull
```

This allows you to keep a minimal config file and override settings per run.

## Validation and Error Handling

The script validates configuration on startup:

- **Missing required settings** - Will prompt to add `api_org_name` if missing
- **Type mismatches** - Will use defaults and warn if setting has wrong type
- **Invalid paths** - Will create missing directories or error if files are inaccessible
- **Bad API tokens** - Will validate format (32-character base64) before attempting API calls

If the configuration file is invalid JSON or has issues, the script will:
1. Report the specific problem
2. Create a backup of the bad config
3. Generate a corrected config file with defaults
