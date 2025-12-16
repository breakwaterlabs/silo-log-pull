# Offline and Air-Gapped Systems Guide

This guide explains how to deploy silo-log-pull on systems without internet access. Docker is generally the easier option for offline deployments as you only need to transfer one container image rather than multiple Python dependencies.

## Option 1: Docker Image Transfer (Recommended for Offline Systems)

Docker images can be easily exported on a system with internet access and imported on the offline system.

### On a System with Internet Access
First ensure you have a working container runtime like docker or rancher-desktop. See the [Windows Rancher Desktop guide](windows-rancher-desktop.md) for details on Windows.

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

See the [2-step High side](example_configs/2-step_highside/) example configuration-- the configurations should work out of the box (depending on desired output format) and only require modifying the seccure_key.txt.

Review your settings:
```bash
nano data/silo_config.json
```

Set your decryption key:
```bash
echo "YOUR_PASSPHRASE_HERE" > data/seccure_key.txt
```

#### 3. Run the Container

```bash
docker run --rm -v $(pwd)/data:/data silo-log-pull
```

### Using Podman Instead of Docker (Linux only)

Podman works the same way, but with `podman` instead of `docker` in commands:

**Export:**
```bash
# Export
podman save silo-log-pull -o silo-log-pull.tar

# import
podman load -i silo-log-pull.tar

# run
podman run --rm -v $(pwd)/data:/data silo-log-pull
```

---

## Option 2: Python Dependencies Transfer

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
