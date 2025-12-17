# Offline and Air-Gapped Systems Guide

This guide covers deploying silo-log-pull on systems without internet access.

## Automated Offline Packaging (Recommended)

The repository includes a unified script to automate offline package creation. You can include Python dependencies, container images, and logs in any combination:

### Interactive Mode (Default)

**Windows PowerShell:**
```powershell
.\scripts\win\prepare-offline-bundle.ps1
```

**Linux/macOS:**
```bash
./scripts/linux/prepare-offline-bundle.sh
```

When run without parameters, you'll see an interactive menu:

```
╔══════════════════════════════════════════════════════════════╗
║          Silo Log Pull - Offline Bundle Generator            ║
╚══════════════════════════════════════════════════════════════╝

What would you like to include in the offline bundle?

  [1] Python deployment (with dependencies)
  [2] Container deployment (Docker/Podman image)
  [3] Both Python and Container
  [4] Custom selection

Choice [1-4]: _
```

The script will then show you the log files it finds and ask if you want to include them.

### Command-Line Mode

For automation or scripting, use command-line flags:

**Windows PowerShell:**
```powershell
# Python only
.\scripts\win\prepare-offline-bundle.ps1 -IncludePython

# Container only
.\scripts\win\prepare-offline-bundle.ps1 -IncludeContainer

# Both with logs
.\scripts\win\prepare-offline-bundle.ps1 -IncludePython -IncludeContainer -IncludeLogs

# Non-interactive container bundle
.\scripts\win\prepare-offline-bundle.ps1 -IncludeContainer -NonInteractive
```

**Linux/macOS:**
```bash
# Python only
./scripts/linux/prepare-offline-bundle.sh --python

# Container only
./scripts/linux/prepare-offline-bundle.sh --container

# Both with logs
./scripts/linux/prepare-offline-bundle.sh --python --container --logs

# Non-interactive container bundle
./scripts/linux/prepare-offline-bundle.sh --container --non-interactive
```

### Output Files

The script creates appropriately named packages based on what you include:

- `silo-log-pull-offline.zip` - Python dependencies only
- `silo-log-pull-container-offline.zip` - Container image only
- `silo-log-pull-full-offline.zip` - Both Python and container

Each package includes:
- Application files (excluding sensitive data)
- Clean `app/data/` structure with empty `logs/` and `logs_out/` directories
- Example configuration files
- Platform-specific extraction scripts
- Complete documentation
- README-OFFLINE.txt with setup instructions

### Log Bundling

**When logs are included:**
- Logs are copied from their actual locations (determined by `data_dir.txt` and `silo_config.json`)
- Works correctly even if logs are redirected to custom directories
- Useful for:
  - Air-gapped two-step workflows (download on lowside, decrypt on highside)
  - Backup and archival purposes
  - Development and testing across multiple systems

**When logs are excluded:**
- Package contains empty log directories ready for use
- Smaller package size
- No risk of accidentally including sensitive log data

## Container Image Transfer

For container deployments, export the image on a connected system and import on the offline system. See [Building Images - Exporting for Offline Systems](building-images.md#exporting-images-for-offline-systems) for instructions.

On the offline system after importing:
1. Configure per the [Configuration Reference](configuration-reference.md#initial-configuration-steps)
2. See the [2-step High side](example_configs/2-step_highside/) example configuration for typical air-gapped setups
3. Run: `docker run --rm -v $(pwd)/data:/data silo-log-pull`

## Python Dependencies Transfer

If you prefer to run Python directly without containers, you'll need to transfer the Python dependencies. From the root of the downloaded silo-log-pull:

### On a System with Internet Access

#### 1. Download Dependencies

Create a directory for dependencies:
```bash
mkdir silo-dependencies
cd silo-dependencies
```

Download all dependencies (including sub-dependencies):
```bash
pip download -r ../requirements.txt -d .
```

This downloads wheel files for:
- seccure
- pycryptodome
- gmpy2
- setuptools
- six (dependency of seccure)

#### 2. Create a Complete Package

The `app` directory should now contain a "silo-dependencies" directory with files in it. 
Create an archive (.zip or .tar.gz) of the entire `app` directory. In Linux:

```bash
cd ..
# Linux tarball
tar -czf silo-log-pull-offline.tar.gz app/

# Or create a ZIP file (Windows-friendly):
zip -r silo-log-pull-offline.zip app/
```

#### 3. Transfer the Package

Transfer `silo-log-pull-offline.tar.gz` or `.zip` to the offline system.

### On the Offline System

#### 1. Extract the Package

```bash
tar -xzf silo-log-pull-offline.tar.gz
cd silo-log-pull-offline/app
```

Or on Windows:
```powershell
Expand-Archive silo-log-pull-offline.zip
cd silo-log-pull-offline\app
```

#### 2. Install Dependencies

**Linux:**
```bash
pip3 install --no-index --find-links silo-dependencies -r requirements.txt
```

**Windows:**
```powershell
python -m pip install --no-index --find-links silo-dependencies -r requirements.txt
```

#### 3. Set Up Configuration

See [Set up your data directory](#2-set-up-your-data-directory) above for details

#### 4. Run the Script

```bash
python3 silo_batch_pull.py
```

---

## Troubleshooting Offline Installations

### Docker Image Won't Load

**Error: "open /var/lib/docker/tmp/...: no space left on device"**
- Check available disk space: `df -h`
- Clean up old Docker images: `docker system prune -a`

**Error: "Error processing tar file"**
- The TAR file may be corrupted during transfer
- Verify checksums before and after transfer:
  ```bash
  sha256sum silo-log-pull.tar
  ```

### Python Dependency Issues

**Error: "No matching distribution found"**

The wheel files may not match your platform. You need to download platform-specific wheels.

Check your platform tags:
```bash
python -m pip debug --verbose | grep compatible_tags
```

On the internet-connected system, download for the specific platform:
```bash
pip download --platform manylinux2014_x86_64 --only-binary=:all: -r requirements.txt -d silo-dependencies/
```

**Error: "gmpy2 requires GMP library"**

If you get build errors, you're likely missing system dependencies. On the offline system, you may need to install system packages first:

**RHEL/CentOS/Fedora:**
```bash
sudo dnf install gmp-devel python3-devel gcc
```

**Ubuntu/Debian:**
```bash
sudo apt install libgmp-dev python3-dev gcc
```

If you can't install system packages, consider using Docker instead - it includes all required libraries.

**Error: "Platform wheel ... is not compatible"**

Some wheel files may need renaming. For example:
```bash
cd silo-dependencies
mv gmpy2-2.1.5-cp36-cp36m-manylinux_2_17_x86_64.manylinux2014_x86_64.whl \
   gmpy2-2.1.5-cp36-cp36m-linux_x86_64.whl
```

Then install:
```bash
pip3 install --no-index --find-links . -r ../requirements.txt
```
