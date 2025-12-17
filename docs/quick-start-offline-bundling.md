# Quick Start: Offline Bundle Creation

## Overview

The unified offline bundle script allows you to create customized packages for air-gapped systems, choosing Python dependencies, container images, and optionally including logs.

## Quick Start - Interactive Mode (Recommended)

**Windows:**
```powershell
.\scripts\win\prepare-offline-bundle.ps1
```

**Linux/macOS:**
```bash
./scripts/linux/prepare-offline-bundle.sh
```

You'll see an interactive menu:
```
╔══════════════════════════════════════════════════════════════╗
║          Silo Log Pull - Offline Bundle Generator            ║
╚══════════════════════════════════════════════════════════════╝

What would you like to include in the offline bundle?

  [1] Python deployment (with dependencies)
  [2] Container deployment (Docker/Podman image)
  [3] Both Python and Container
  [4] Custom selection

Choice [1-4]:
```

After selecting what to include, you'll be prompted about logs:
```
Do you want to include existing logs in the offline bundle?
   Files: 23            Path: C:\silo_data\logs
   Files: 45            Path: C:\silo_data\logs_out
Include logs? [y/N]:
```

## Command-Line Mode

For automation or when you know exactly what you need:

### Python Only

**Windows:**
```powershell
# Without logs
.\scripts\win\prepare-offline-bundle.ps1 -IncludePython -NonInteractive

# With logs
.\scripts\win\prepare-offline-bundle.ps1 -IncludePython -IncludeLogs -NonInteractive
```

**Linux:**
```bash
# Without logs
./scripts/linux/prepare-offline-bundle.sh --python --non-interactive

# With logs
./scripts/linux/prepare-offline-bundle.sh --python --logs --non-interactive
```

### Container Only

**Windows:**
```powershell
# Without logs
.\scripts\win\prepare-offline-bundle.ps1 -IncludeContainer -NonInteractive

# With logs
.\scripts\win\prepare-offline-bundle.ps1 -IncludeContainer -IncludeLogs -NonInteractive
```

**Linux:**
```bash
# Without logs
./scripts/linux/prepare-offline-bundle.sh --container --non-interactive

# With logs
./scripts/linux/prepare-offline-bundle.sh --container --logs --non-interactive
```

### Both Python and Container

**Windows:**
```powershell
.\scripts\win\prepare-offline-bundle.ps1 -IncludePython -IncludeContainer -IncludeLogs
```

**Linux:**
```bash
./scripts/linux/prepare-offline-bundle.sh --python --container --logs
```

## What Gets Bundled

### Output Files

The script creates appropriately named packages:
- **Python only:** `silo-log-pull-offline.zip`
- **Container only:** `silo-log-pull-container-offline.zip`
- **Both:** `silo-log-pull-full-offline.zip`

### Package Contents

**Always included:**
- Application code (`silo_batch_pull.py`, etc.)
- Clean `app/data/` directory structure with empty `logs/` and `logs_out/` directories
- Example configuration (`example_silo_config.json`)
- Complete documentation
- Platform-specific extraction scripts (`offline-extract.ps1`, `offline-extract.sh`)
- README-OFFLINE.txt with setup instructions

**Optionally included (based on your selections):**
- **Python dependencies:** Pre-downloaded wheel files in `app/silo-dependencies/`
- **Container image:** Docker/Podman image as `silo-log-pull.tar`
- **Logs:** Both directories if requested:
  - `logs/` - Encrypted logs downloaded from API
  - `logs_out/` - Decrypted/processed logs

**NEVER included (for security):**
- `silo_config.json` (actual config with potentially sensitive data)
- `token.txt`
- `seccure_key.txt`
- `data_dir.txt`

These must be configured separately on the target system.

### Log Path Detection

When logs are included, they're automatically discovered from their actual locations:
- Reads `data_dir.txt` if present (supports redirected data directories)
- Parses `silo_config.json` for custom log directory names
- Works correctly even if logs are in non-standard locations like `C:\silo_secrets\logs`

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

### 1. Extract the Bundle

**Windows:**
```powershell
Expand-Archive silo-log-pull-offline.zip
cd silo-log-pull-offline
```

**Linux/macOS:**
```bash
unzip silo-log-pull-offline.zip
cd silo-log-pull-offline
```

### 2. Run the Extraction Script

The package includes extraction scripts for each deployment type.

**Python deployment:**

Windows:
```powershell
.\offline-extract.ps1
```

Linux/macOS:
```bash
./offline-extract.sh
```

**Container deployment:**

If you bundled both Python and Container, you'll have two extraction scripts:

Windows:
```powershell
.\offline-extract.ps1              # Python
.\offline-extract-container.ps1    # Container
```

Linux/macOS:
```bash
./offline-extract.sh               # Python
./offline-extract-container.sh     # Container
```

If you bundled only container, there's just `offline-extract.ps1` / `offline-extract.sh`.

### 3. Configure Credentials

Add the necessary configuration files:
- `app/data/silo_config.json` - Your organization and log settings
- `app/data/token.txt` - API token (if downloading more logs)
- `app/data/seccure_key.txt` - Decryption key (if decrypting logs)

### 4. Access Bundled Logs

If you included logs in the bundle:
- Encrypted logs: `app/data/logs/`
- Decrypted logs: `app/data/logs_out/`

### 5. Run the Application

**Python deployment:**
```bash
cd app
source venv/bin/activate    # Linux/macOS
# or
.\venv\Scripts\Activate.ps1  # Windows

python silo_batch_pull.py
```

**Container deployment:**
```bash
cd app
docker run --rm -v $(pwd)/data:/data silo-log-pull
```

## See Also

- [Offline Systems Guide](offline-systems.md) - Complete offline deployment documentation
- [Configuration Reference](configuration-reference.md) - All configuration options
- [2-Step Example Configs](example_configs/2-step_lowside/) - Air-gapped workflow examples
