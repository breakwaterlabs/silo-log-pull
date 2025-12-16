# Getting Started on Linux

This guide will help you set up and run silo-log-pull on Linux using either Docker, Podman, or Python directly.

## Prerequisites

- Linux system (RHEL, Ubuntu, Debian, Fedora, or similar)
- Root or sudo access
- Your Silo organization name
- Your Silo API token (32-character base64 string)
- Either python or a container runtime like docker

---

## Initial Setup

1. Download and extract the repository
2. Configure your settings per the [Configuration Reference](configuration-reference.md#initial-configuration-steps)

Then choose a deployment method:

- [**Docker**](#option-1-using-docker) - Standard container runtime
- [**Podman**](#option-2-using-podman) - Daemonless, rootless-capable drop-in replacement for Docker
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

```bash
# Build locally
docker build -t silo-log-pull .

# Or pull from registry
docker pull registry.gitlab.com/breakwaterlabs/silo-log-pull:latest

# Or load from tar file (for offline systems)
docker image load -i silo-log-pull.tar
```

Run the container:
```bash
docker run --rm -v $(pwd)/data:/data silo-log-pull
```

Logs are written to `data/logs/`.

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

```bash
cd app
pip3 install -r requirements.txt  # Required for encryption features
python3 silo_batch_pull.py
```

Logs are written to `data/logs/`.

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

Override configuration settings at runtime using environment variables:

```bash
docker run --rm -v $(pwd)/data:/data \
  -e SILO_DATE_START="2024-01-01" \
  -e SILO_FETCH_NUM_DAYS=30 \
  silo-log-pull
```

See [Environment Variable Overrides](configuration-reference.md#environment-variable-overrides) for details.

---

## Next Steps

- Review the [Configuration Reference](configuration-reference.md) for all available settings
- See [Example Configs](example_configs/) for different usage scenarios
