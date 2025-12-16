# Getting Started on Linux

This guide will help you set up and run silo-log-pull on Linux using either Docker, Podman, or Python directly.

## Prerequisites

- Linux system (RHEL, Ubuntu, Debian, Fedora, or similar)
- Root or sudo access
- Your Silo organization name
- Your Silo API token (32-character base64 string)

## Choose Your Method

- **Docker** - Standard container runtime, widely used
- **Podman** - Daemonless container engine, drop-in Docker replacement, rootless capable
- **Python** - Direct execution without containers

---

# Option 1: Using Docker

## Install Docker

### Ubuntu/Debian

```bash
sudo apt update
sudo apt install docker.io docker-compose
sudo systemctl enable --now docker
sudo usermod -aG docker $USER
```

Log out and back in for group changes to take effect.

### RHEL/CentOS/Fedora

```bash
sudo dnf install docker docker-compose
sudo systemctl enable --now docker
sudo usermod -aG docker $USER
```

Log out and back in for group changes to take effect.

## Verify Installation

```bash
docker --version
docker-compose --version
```

## Set Up and Run

1. **Download and extract the repository:**
   ```bash
   wget https://github.com/yourusername/silo-log-pull/archive/refs/heads/main.zip
   unzip main.zip
   cd silo-log-pull-main
   ```

2. **Set up configuration files:**
   ```bash
   cp ../docs/example_configs/general-oneshot-download-and-decrypt/silo_config.json data/
   ```

3. **Edit configuration:**
   ```bash
   nano data/silo_config.json
   # or use vi, vim, etc.
   ```

   Set `"api_org_name"` to your organization name, save and exit.

4. **(Optional) Add HTTP tokens for log download:**
   Log download from internet requires an API key from Authentic8 in token.txt:
   ```bash
   nano data/token.txt
   ```
   Paste your token (example), save and exit.

5. **(Optional) Add seccure passphrase if using encryption:**
   Decrypting encrypted logs requires a `seccure` decryption passphrase:
   ```bash
   nano data/seccure_key.txt
   ```
   Paste in your plaintext passphrase. (Example)

6. **Pull / Build and run the docker image:**
   ```bash
   # EITHER:  Build locally...
   docker build -t silo-log-pull .

   #   OR:    Pull from Gitlab
   docker pull registry.gitlab.com/breakwaterlabs/silo-log-pull:latest

   # ... And then run it
   docker run --rm -v $(pwd)/data:/data silo-log-pull
   ```

7. **View your logs:**
   ```bash
   ls -lh app/data/logs/
   ```

---

# Option 2: Using Podman

Podman is a daemonless container engine that's compatible with Docker commands. It's particularly useful in enterprise environments and supports rootless containers.

It should be installed by default, and its usage here is identical to docker usage, except that instead of `docker <command>` you would use `podman <command>`:
   ```bash
   podman pull registry.gitlab.com/breakwaterlabs/silo-log-pull:latest
   podman run --rm -v $(pwd)/data:/data silo-log-pull
   ```

## Installing podman
Podman should be installed out of the box on Red Hat. You can verify as follows:
   ```bash
   podman --version
   ```

If it is not installed, you can install it on Red Hat-based systems as follows:
```bash
sudo dnf install podman
```

# Option 3: Using Python Directly

## Install Python and Dependencies

### Ubuntu/Debian

```bash
sudo apt update
sudo apt install python3 python3-pip python3-dev gcc libgmp-dev
```

### RHEL/CentOS/Fedora

```bash
sudo dnf install python3 python3-pip python3-devel gcc gmp-devel
```

## Set Up and Run

1. **Download and extract the repository:**
   ```bash
   wget https://github.com/yourusername/silo-log-pull/archive/refs/heads/main.zip
   unzip main.zip
   cd silo-log-pull-main/app
   ```

2. **Install Python dependencies (if using encryption):**
   ```bash
   pip3 install -r requirements.txt
   ```

   For system-wide installation, use sudo. For user installation:
   ```bash
   pip3 install --user -r requirements.txt
   ```

3. **Set up configuration files:**
   ```bash
   cp ../docs/example_configs/general-oneshot-download-and-decrypt/silo_config.json data/
   ```

4. **Edit configuration:**
   ```bash
   nano data/silo_config.json
   ```

   Set `"api_org_name"` to your organization name, save and exit.

5. **Add your API token:**
   ```bash
   nano data/token.txt
   ```

6. **(Optional) Add seccure passphrase:**
   ```bash
   nano data/seccure_key.txt
   ```

7. **Run the script:**
   ```bash
   python3 silo_batch_pull.py
   ```

8. **View your logs:**
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

With Podman, you can run rootless:
```bash
podman run --rm -v $(pwd)/data:/data:Z silo-log-pull
```

### SELinux Issues (RHEL/CentOS/Fedora)

If you encounter SELinux permission errors with Podman:
```bash
podman run --rm -v $(pwd)/data:/data:Z silo-log-pull
```

Or temporarily set SELinux to permissive mode:
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
