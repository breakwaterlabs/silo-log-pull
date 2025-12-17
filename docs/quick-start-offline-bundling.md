# Quick Start: Offline Bundle with Logs

## Overview

When creating offline packages, you can optionally include existing logs for transfer to air-gapped systems.

## Python Offline Bundle

### Interactive Mode

Run the script and respond to the prompt:

**Windows:**
```powershell
.\scripts\win\prepare-offline-python.ps1
```

**Linux/macOS:**
```bash
./scripts/linux/prepare-offline-python.sh
```

You'll be prompted:
```
Do you want to include existing logs in the offline bundle?
Include logs? [y/N]:
```

### Command-Line Mode

**Windows - Include logs:**
```powershell
.\scripts\win\prepare-offline-python.ps1 -IncludeLogs
```

**Linux - Include logs:**
```bash
./scripts/linux/prepare-offline-python.sh --include-logs
```

## Container Offline Bundle

Same options available:

**Windows:**
```powershell
.\scripts\win\prepare-offline-container.ps1 [-IncludeLogs]
```

**Linux:**
```bash
./scripts/linux/prepare-offline-container.sh [--include-logs]
```

## What Gets Bundled

When you include logs, both directories are bundled:
- `logs/` - Encrypted logs downloaded from API
- `logs_out/` - Decrypted/processed logs

**Note:** Credentials are NEVER bundled for security:
- `silo_config.json` (actual config with potentially sensitive data)
- `token.txt`
- `seccure_key.txt`

These must be configured separately on the target system.

## Use Cases

### Air-Gapped Two-Step Workflow

**Lowside (connected) system:**
1. Download encrypted logs from Silo API
2. Create offline bundle with logs included
3. Transfer bundle to highside

**Highside (disconnected) system:**
1. Extract offline bundle (includes encrypted logs)
2. Add seccure passphrase to local system
3. Decrypt logs using local passphrase

See the [2-step example configurations](example_configs/) for detailed setup.

### Backup and Archive

Create periodic offline bundles with logs for:
- Long-term archival
- Compliance and audit requirements
- Disaster recovery

### Development and Testing

Bundle logs with the application for:
- Testing on different systems
- Development environment setup
- Reproducing issues

## Security Considerations

**Before bundling logs:**
- Verify logs are encrypted if required by your security policy
- Ensure you have authorization to transfer the logs
- Consider the sensitivity of the data in the logs
- Follow your organization's data handling procedures

**Transport security:**
- Use encrypted transfer methods (SFTP, secure media)
- Verify integrity of transferred packages
- Follow physical security procedures for media transfer

## Extraction and Usage

After transferring the offline bundle to the target system:

1. **Extract the bundle:**
   ```bash
   unzip silo-log-pull-offline.zip
   # or
   unzip silo-log-pull-container-offline.zip
   ```

2. **Run the extraction script (recommended):**

   **Windows:**
   ```powershell
   .\offline-extract.ps1
   ```

   **Linux/macOS:**
   ```bash
   ./offline-extract.sh
   ```

3. **Configure credentials:**
   - Add `app/data/token.txt` if downloading more logs
   - Add `app/data/seccure_key.txt` if decrypting logs
   - Configure `app/data/silo_config.json` as needed

4. **Access bundled logs:**
   - Encrypted logs will be in `app/data/logs/`
   - Decrypted logs will be in `app/data/logs_out/`

## See Also

- [Offline Systems Guide](offline-systems.md) - Complete offline deployment documentation
- [Configuration Reference](configuration-reference.md) - All configuration options
- [2-Step Example Configs](example_configs/2-step_lowside/) - Air-gapped workflow examples
