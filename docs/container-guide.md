# Container Deployment Guide

This guide covers running silo-log-pull using Docker or Podman on any operating system.

## Prerequisites

- A container runtime (Docker, Podman, or Rancher Desktop)
- Your Silo organization name and API token

## Container Runtime Installation

### Linux

Verify your container runtime:
```bash
docker --version
```

If not installed:

**Ubuntu/Debian:**
```bash
sudo apt update
sudo apt install docker.io
sudo systemctl enable --now docker
sudo usermod -aG docker $USER
```

**RHEL/CentOS/Fedora:**
```bash
sudo dnf install docker
sudo systemctl enable --now docker
sudo usermod -aG docker $USER
```

Log out and back in for group changes to take effect.

### Windows

Install [Rancher Desktop](https://rancherdesktop.io/) and select **dockerd (moby)** as the container runtime.

## Setup

1. Download and extract the repository
2. Configure per the [Configuration Reference](configuration-reference.md#initial-configuration-steps)

## Pull and Run

Pull the pre-built image:
```bash
docker pull registry.gitlab.com/breakwaterlabs/silo-log-pull:latest
```

Optionally tag locally for convenience:
```bash
docker tag registry.gitlab.com/breakwaterlabs/silo-log-pull:latest silo-log-pull
```

Run the container:

**Linux/macOS:**
```bash
docker run --rm -v $(pwd)/data:/data silo-log-pull
```

**Windows PowerShell:**
```powershell
docker run --rm -v ${PWD}/data:/data silo-log-pull
```

Logs are written to `data/logs/`.

## Using Podman

Podman is a drop-in replacement for Docker. Substitute `podman` for `docker` in all commands.

Podman is pre-installed on most RHEL-based systems. If not:

**RHEL/CentOS/Fedora:**
```bash
sudo dnf install podman
```

**Ubuntu/Debian:**
```bash
sudo apt install podman
```

## Environment Variable Overrides

Override settings at runtime:

**Linux/macOS:**
```bash
docker run --rm -v $(pwd)/data:/data \
  -e SILO_DATE_START="2024-01-01" \
  -e SILO_FETCH_NUM_DAYS=30 \
  silo-log-pull
```

**Windows PowerShell:**
```powershell
docker run --rm -v ${PWD}/data:/data `
  -e SILO_DATE_START="2024-01-01" `
  -e SILO_FETCH_NUM_DAYS=30 `
  silo-log-pull
```

See [Environment Variable Overrides](configuration-reference.md#environment-variable-overrides) for all options.

## Troubleshooting

### Permission Denied (Linux)
```bash
sudo usermod -aG docker $USER
```
Log out and back in.

### SELinux Issues (RHEL/CentOS/Fedora)
Add the `:Z` flag to the volume mount:
```bash
docker run --rm -v $(pwd)/data:/data:Z silo-log-pull
```

### Volume Mount Issues (Windows)
Use full paths if relative paths fail:
```powershell
docker run --rm -v C:\silo-log-pull\app\data:/data silo-log-pull
```

### Rancher Desktop Not Starting (Windows)
- Verify Virtualization is enabled in BIOS/UEFI
- Ensure dockerd (moby) runtime is selected in Rancher Desktop settings

## Next Steps

- Review the [Configuration Reference](configuration-reference.md) for all settings
- See [Example Configs](example_configs/) for usage scenarios
- See [Scheduled Execution](scheduled-execution.md) for automation
- See [Building Images](building-images.md) to build locally or set up CI/CD
