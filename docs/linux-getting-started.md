# Getting Started on Linux

This guide will help you set up and run silo-log-pull on Linux using either Docker, Podman, or Python directly.

## Prerequisites

- Linux system (RHEL, Ubuntu, Debian, Fedora, or similar)
- Root or sudo access
- Your Silo organization name
- Your Silo API token (32-character base64 string)
- Either python or a container runtime like docker

---

## Initial Setup (All Methods)

First, download and extract the repository, then configure your settings:

1. **Download and extract the repository:**
   ```bash
   wget https://github.com/yourusername/silo-log-pull/archive/refs/heads/main.zip
   unzip main.zip
   cd silo-log-pull-main
   ```

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

**Once you have completed this initial setup, Choose your deployment method:**

- [**Docker**](#option-1-using-docker) - Standard container runtime, widely used
- [**Podman**](#option-2-using-podman) - Daemonless container engine, drop-in Docker replacement, rootless capable
- [**Python**](#option-3-using-python-directly) - Direct execution without containers


---

## Option 1: Using Docker
Before beginning ensure that your container system is working:
```bash
docker --version
docker-compose --version
```

If it is not, you should install it.
- Ubuntu/Debian: 
```bash
sudo apt update
sudo apt install docker.io docker-compose
sudo systemctl enable --now docker
sudo usermod -aG docker $USER
```

- RHEL/CentOS/Fedora

```bash
sudo dnf install docker docker-compose
sudo systemctl enable --now docker
sudo usermod -aG docker $USER
```

Log out and back in for group changes to take effect.


### Build and Run

After completing the [Initial Setup](#initial-setup-all-methods) above:

1. **Build or pull the Docker image:**
   ```bash
   # EITHER: Build locally...
   docker build -t silo-log-pull .

   # OR: Pull from GitLab...
   docker pull registry.gitlab.com/breakwaterlabs/silo-log-pull:latest

   # OR: Load the container image from a tar file
   docker image load -i silo-log-pull.tar

   # Then confirm that the image exists on your system:
   docker images
   ```

2. **Run the container:**
   ```bash
   docker run --rm -v $(pwd)/data:/data silo-log-pull
   ```

3. **View your logs:**
   ```bash
   ls -lh data/logs/
   ```

---

## Option 2: Using Podman

Podman is a daemonless container engine that's commandline-compatible with Docker commands. In most cases you can simply use the same commands as docker, because Red Hat systems alias `docker` to `podman`. Otherwise you can simply substitute `podman` in docker commands:

```bash
podman --version
podman images
```

If these commands work, you should simply follow the [Using Docker](#option-1-using-docker) instructions above, swapping in `podman` for `docker` in all commands.

### Troubleshooting
Podman should be installed by default on Red Hat-based systems. If it is not:

- RHEL/CentOS/Fedora
```bash
sudo dnf install podman
```

- Ubuntu/Debian
```bash
sudo apt update
sudo apt install podman
```

---

## Option 3: Using Python Directly

### Install Python and Dependencies

- Ubuntu/Debian

```bash
sudo apt update
sudo apt install python3 python3-pip python3-dev gcc libgmp-dev
```

- RHEL/CentOS/Fedora

```bash
sudo dnf install python3 python3-pip python3-devel gcc gmp-devel
```

### Set Up and Run

After completing the [Initial Setup](#initial-setup-all-methods) above:

1. **Navigate to the app directory:**
   ```bash
   cd app
   ```

2. **Install Python dependencies (if using encryption):**
   ```bash
   pip3 install -r requirements.txt
   ```

   For system-wide installation, use sudo. For user installation:
   ```bash
   pip3 install --user -r requirements.txt
   ```

3. **Run the script:**
   ```bash
   python3 silo_batch_pull.py
   ```

4. **View your logs:**
   ```bash
   ls -lh data/logs/
   ```

---

## Troubleshooting

### Permission Denied (Docker/Podman)

If you get permission errors with Docker:
```bash
sudo usermod -aG docker $USER
```
Then log out and back in.

### SELinux Issues (RHEL/CentOS/Fedora)

If you encounter SELinux permission errors with Podman:
```bash
podman run --rm -v $(pwd)/data:/data:Z silo-log-pull
```

Or temporarily set SELinux to permissive mode to see whether that is the issue:
```bash
sudo setenforce 0
```

### Python Dependency Installation Issues

If gmpy2 fails to install, ensure development tools are installed:

**Ubuntu/Debian:**
```bash
sudo apt install build-essential libgmp-dev
```

**RHEL/CentOS/Fedora:**
```bash
sudo dnf groupinstall "Development Tools"
sudo dnf install gmp-devel
```

For offline installation, see the main README troubleshooting section.

---

## Advanced Usage

### Scheduled Execution with Cron

Add to crontab for daily execution at 2 AM:

```bash
crontab -e
```

Add this line (adjust path as needed):
```
0 2 * * * cd /path/to/silo-log-pull/app && docker run --rm -v $(pwd)/data:/data silo-log-pull
```

Or for Python:
```
0 2 * * * cd /path/to/silo-log-pull/app && python3 silo_batch_pull.py
```

### Using systemd for Scheduled Runs

Create a systemd service and timer:

```bash
sudo nano /etc/systemd/system/silo-log-pull.service
```

```ini
[Unit]
Description=Silo Log Pull Service
After=network.target

[Service]
Type=oneshot
User=youruser
WorkingDirectory=/path/to/silo-log-pull/app
ExecStart=/usr/bin/docker run --rm -v /path/to/silo-log-pull/app/data:/data silo-log-pull

[Install]
WantedBy=multi-user.target
```

Create a timer:

```bash
sudo nano /etc/systemd/system/silo-log-pull.timer
```

```ini
[Unit]
Description=Run Silo Log Pull Daily

[Timer]
OnCalendar=daily
Persistent=true

[Install]
WantedBy=timers.target
```

Enable and start:

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now silo-log-pull.timer
```

### Override Settings with Environment Variables

Override any configuration setting without editing files:

```bash
docker run --rm \
  -v $(pwd)/data:/data \
  -e SILO_DATE_START="2024-01-01" \
  -e SILO_FETCH_NUM_DAYS=30 \
  -e SILO_OUTPUT_CSV=true \
  silo-log-pull
```

Available environment variables use the format `SILO_<SETTING_NAME>` in uppercase. See the main README for a complete list.

---

## Next Steps

- Review the [Configuration Reference](../README.md#configuring-the-script) for all available settings
- Check out [Example Configs](example_configs/README.md) for different usage scenarios
- Set up automated scheduled pulls using cron or systemd
