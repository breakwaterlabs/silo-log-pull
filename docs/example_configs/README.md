# Example Configurations

Each example directory contains configuration files for different usage scenarios:

- **`silo_config.json`** - Main configuration
- **`token.txt`** - API token (if downloading from API)
- **`seccure_key.txt`** - Decryption passphrase (if decrypting)

## Usage

1. Copy the example files to your `app/data/` directory
2. Edit `silo_config.json` to set your organization name
3. Add credentials to `token.txt` and/or `seccure_key.txt` as needed
4. Run the script

See [Configuration Reference](../configuration-reference.md) for path resolution and all available settings.

## Available Examples

- **general-oneshot-download-and-decrypt/** - Single-system download and decrypt
- **2-step_lowside/** - Download encrypted logs without decryption keys
- **2-step_highside/** - Decrypt previously downloaded logs on a secure system
