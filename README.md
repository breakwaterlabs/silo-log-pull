# silo-log-pull

A Python script for downloading and processing Silo logs from Authentic8. Provides an improved, production-ready alternative to the original Python 2 examples with support for automated workflows, Docker containers, and separation of duties scenarios.

## Features

- JSON-based configuration with environment variable overrides
- Multiple deployment options: Python, Docker, or Podman
- Designed for scheduled/unattended execution
- Support for low-side download / high-side decrypt workflows
- Cross-platform: Windows and Linux

## Docker vs Python: Which Should I Use?

**Use Docker/Podman if:**
- You want isolated, reproducible deployments
- You're on an offline/air-gapped system (easier to transfer one image than multiple Python dependencies)
- You want to avoid Python dependency issues
- You're already using containers in your environment

**Use Python directly if:**
- You don't want to install Docker/Podman
- You're on a lightweight system without container support
- You prefer simpler, direct execution
- You're only downloading logs without decryption (no dependencies needed)

## Getting Started

**→ [Complete Documentation Hub](docs/README.md)** - Browse all guides and documentation

### Quick Links to Platform Guides

**Windows:**
- [Windows with Rancher Desktop](docs/windows-rancher-desktop.md) - Free container solution for business use
- [Windows with Python](docs/windows-python.md) - Direct Python execution

**Linux:**
- [Linux Getting Started](docs/linux-getting-started.md) - Docker, Podman, or Python options

**Offline/Air-Gapped Systems:**
- [Offline Systems Guide](docs/offline-systems.md) - Transfer Docker images or Python dependencies

### 2. Quick Setup Summary

All methods follow this pattern:

1. Download and extract this repository
2. Create a `data/` directory
3. Add your configuration files to `data/`:
   - `silo_config.json` (copy from `docs/example_configs/`)
   - `token.txt` (your API token)
   - `seccure_key.txt` (optional, for encryption)
4. Edit `silo_config.json` to set your organization name
5. Run the script

The script uses a unified `data/` directory for all configuration and logs.

### 3. Example Configurations

Ready-to-use configs for common scenarios are in `docs/example_configs/`:
- **general-oneshot-download-and-decrypt** - Single system, download and decrypt
- **2-step_lowside** - Download encrypted logs (no decryption keys)
- **2-step_highside** - Decrypt previously downloaded logs (no API access)

See [Example Configs README](docs/example_configs/README.md) for details.

## Configuration

The script reads settings from `data/silo_config.json`. The only required setting is `api_org_name` (your Silo organization name). All other settings have sensible defaults.

**Most common settings:**
- `api_org_name` - Your organization name (required)
- `fetch_num_days` - How many days of logs to download (default: 7)
- `date_start` - Start date in YYYY-MM-DD format (default: today)
- `seccure_decrypt_logs` - Decrypt logs during processing (default: false)
- `output_csv` - Also save logs as CSV files (default: false)

**See the complete [Configuration Reference](docs/configuration-reference.md)** for all 19 available settings, environment variable overrides, and path resolution details.

## Requirements

**Docker/Podman:**
- Docker, Podman, or Rancher Desktop
- No Python needed on host

**Python:**
- Python 3.6+ (tested on 3.6 and 3.12)
- Dependencies: Only needed if using encryption features
  ```bash
  pip install -r requirements.txt
  ```

**For detailed installation instructions, see the platform guides above.**

For offline/air-gapped systems, see the [Offline Systems Guide](docs/offline-systems.md).



## Quick Usage Examples

**Python:**
```bash
python3 silo_batch_pull.py
```

**Docker (build locally):**
```bash
docker build -t silo-log-pull .
docker run --rm -v $(pwd)/data:/data silo-log-pull
```

**Docker (use pre-built image):**
```bash
docker pull registry.gitlab.com/YOUR_USERNAME/silo-log-pull:latest
docker run --rm -v $(pwd)/data:/data registry.gitlab.com/YOUR_USERNAME/silo-log-pull:latest
```
See [Using Pre-Built Images](docs/using-prebuilt-images.md) for details.

**Docker Compose:**
```bash
docker-compose up
```

See the platform guides for detailed instructions and troubleshooting.

## Roadmap
 - [x] Update filesystem code to use cross-OS native code (current code relies on Windows conventions)
 - [x] Support arbitrary date ranges
 - [x] Support alternate directories for import and download

## License
See the LICENSE.md file for details.

## Project status
Active as of 2024-12-16
