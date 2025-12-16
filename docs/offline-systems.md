# Offline and Air-Gapped Systems Guide

This guide explains how to deploy silo-log-pull on systems without internet access. Docker is generally the easier option for offline deployments as you only need to transfer one container image rather than multiple Python dependencies.

## Option 1: Docker Image Transfer (Recommended for Offline Systems)

Docker images can be easily exported on a system with internet access and imported on the offline system.

### On a System with Internet Access

#### 1. Build or Pull the Image

Build the image:
```bash
docker build -t silo-log-pull .
```

Or if you're using a pre-built image:
```bash
docker pull your-registry/silo-log-pull:latest
docker tag your-registry/silo-log-pull:latest silo-log-pull
```

#### 2. Export the Image to a TAR File

```bash
docker save silo-log-pull -o silo-log-pull.tar
```

This creates a `silo-log-pull.tar` file containing the entire image.

#### 3. Verify the Export

Check the file size (should be 100-200 MB):
```bash
ls -lh silo-log-pull.tar
```

#### 4. Transfer to Offline System

Transfer the TAR file using approved media:
- USB drive
- CD/DVD
- Approved file transfer mechanisms
- Secure network file copy

### On the Offline System

#### 1. Import the Image

```bash
docker load -i silo-log-pull.tar
```

Verify the image loaded:
```bash
docker images | grep silo-log-pull
```

#### 2. Set Up Your Data Directory

```bash
mkdir -p data/logs
```

Copy an example config:
```bash
cp docs/example_configs/general-oneshot-download-and-decrypt/silo_config.json data/
```

Create your token file (if downloading from API):
```bash
echo "YOUR_TOKEN_HERE" > data/token.txt
```

Create your passphrase file (if using encryption):
```bash
echo "YOUR_PASSPHRASE_HERE" > data/seccure_key.txt
```

#### 3. Run the Container

```bash
docker run --rm -v $(pwd)/data:/data silo-log-pull
```

### Using Podman Instead of Docker

Podman works the same way:

**Export:**
```bash
podman save silo-log-pull -o silo-log-pull.tar
```

**Import:**
```bash
podman load -i silo-log-pull.tar
```

**Run:**
```bash
podman run --rm -v $(pwd)/data:/data silo-log-pull
```

---

## Option 2: Python Dependencies Transfer

If you prefer to run Python directly without containers, you'll need to transfer the Python dependencies.

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

Create a transfer package with the script and dependencies:
```bash
cd ..
mkdir silo-log-pull-offline
cp silo_batch_pull.py silo-log-pull-offline/
cp requirements.txt silo-log-pull-offline/
cp -r silo-dependencies silo-log-pull-offline/
cp -r docs silo-log-pull-offline/
```

Create a tarball:
```bash
tar -czf silo-log-pull-offline.tar.gz silo-log-pull-offline/
```

Or create a ZIP file (Windows-friendly):
```bash
zip -r silo-log-pull-offline.zip silo-log-pull-offline/
```

#### 3. Transfer the Package

Transfer `silo-log-pull-offline.tar.gz` or `.zip` to the offline system.

### On the Offline System

#### 1. Extract the Package

```bash
tar -xzf silo-log-pull-offline.tar.gz
cd silo-log-pull-offline
```

Or on Windows:
```powershell
Expand-Archive silo-log-pull-offline.zip
cd silo-log-pull-offline
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

```bash
mkdir -p data/logs
cp docs/example_configs/general-oneshot-download-and-decrypt/silo_config.json data/
```

Create your token and passphrase files as needed.

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

---

## Tips for Offline Deployments

### Use Docker When Possible

Docker is almost always easier for offline deployments:
- **Single file to transfer** - One TAR file vs multiple wheel files
- **No system dependencies** - Everything is self-contained
- **Consistent across systems** - Same image works everywhere
- **Easier updates** - Just replace the TAR file

### Verify Before Transfer

Always verify file integrity before transferring to offline systems:

```bash
# Create checksum
sha256sum silo-log-pull.tar > silo-log-pull.tar.sha256

# Verify after transfer
sha256sum -c silo-log-pull.tar.sha256
```

### Consider Image Compression

If transfer size is a concern, compress the TAR file:

```bash
gzip silo-log-pull.tar
# Creates silo-log-pull.tar.gz (typically 30-50% smaller)
```

Decompress on the offline system:
```bash
gunzip silo-log-pull.tar.gz
docker load -i silo-log-pull.tar
```

### Plan for Updates

When updates are needed:
- **Docker**: Build new image, export, transfer, load
- **Python**: Download updated dependencies, transfer, reinstall

Maintain version numbers in filenames:
```bash
silo-log-pull-v1.2.tar
silo-dependencies-v1.2.tar.gz
```

### Test on a Similar System First

Before deploying to the air-gapped system:
1. Test the export/import process on a non-critical system
2. Verify all functionality works after import
3. Document any platform-specific issues

---

## Example: Complete Offline Deployment Workflow

### Phase 1: Preparation (Internet-Connected System)

```bash
# Build Docker image
docker build -t silo-log-pull .

# Export image
docker save silo-log-pull -o silo-log-pull.tar

# Create checksum
sha256sum silo-log-pull.tar > silo-log-pull.tar.sha256

# Package everything for transfer
mkdir transfer-package
cp silo-log-pull.tar transfer-package/
cp silo-log-pull.tar.sha256 transfer-package/
cp -r docs/example_configs transfer-package/
cp README.md transfer-package/
tar -czf silo-transfer.tar.gz transfer-package/
```

### Phase 2: Transfer

Transfer `silo-transfer.tar.gz` using approved methods.

### Phase 3: Deployment (Offline System)

```bash
# Extract package
tar -xzf silo-transfer.tar.gz
cd transfer-package

# Verify integrity
sha256sum -c silo-log-pull.tar.sha256

# Load image
docker load -i silo-log-pull.tar

# Set up configuration
mkdir -p data/logs
cp example_configs/general-oneshot-download-and-decrypt/silo_config.json data/
echo "YOUR_TOKEN" > data/token.txt
echo "YOUR_PASSPHRASE" > data/seccure_key.txt

# Edit config
nano data/silo_config.json
# Set api_org_name

# Test run
docker run --rm -v $(pwd)/data:/data silo-log-pull
```

---

## Next Steps

After successful offline deployment:
- Set up scheduled execution (cron, Task Scheduler, systemd)
- Configure log rotation for the `data/logs/` directory
- Establish a process for regular updates
- Document your specific deployment process
