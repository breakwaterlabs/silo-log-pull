# Getting Started on Windows with Rancher Desktop

This guide covers running silo-log-pull on Windows using Rancher Desktop as a container runtime. Rancher Desktop is a free, open-source alternative to Docker Desktop.

## Prerequisites

- Windows 10/11 (64-bit)
- Administrator access for installation
- Your Silo organization name and API token

## Step 1: Install Rancher Desktop

1. Download from https://rancherdesktop.io/
2. Run the installer
3. Select **dockerd (moby)** as the container runtime
4. Wait for initialization to complete

## Step 2: Verify Installation

```powershell
docker --version
```

## Step 3: Set Up Your Project

1. Download and extract the repository to `C:\silo-log-pull`
2. Configure per the [Configuration Reference](configuration-reference.md#initial-configuration-steps)

## Step 4: Build and Run

```powershell
cd C:\silo-log-pull\app
docker build -t silo-log-pull .
docker run --rm -v ${PWD}/data:/data silo-log-pull
```

Logs are written to `data\logs\`.

## Troubleshooting

### Rancher Desktop Not Starting
- Verify Virtualization is enabled in BIOS/UEFI
- Restart your computer

### "Docker not found" Error
- Ensure Rancher Desktop is running (green indicator in system tray)
- Restart PowerShell after installation
- Verify dockerd (moby) runtime is selected in Rancher Desktop settings

### Volume Mount Issues
Use full paths if relative paths fail:
```powershell
docker run --rm -v C:\silo-log-pull\app\data:/data silo-log-pull
```

## Advanced Usage

### Environment Variable Overrides

Override settings at runtime without editing configuration files:

```powershell
docker run --rm -v ${PWD}/data:/data `
  -e SILO_DATE_START="2024-01-01" `
  -e SILO_FETCH_NUM_DAYS=30 `
  silo-log-pull
```

See [Environment Variable Overrides](configuration-reference.md#environment-variable-overrides) for details.

### Scheduled Execution

Use Windows Task Scheduler:
- Program: `C:\Program Files\Rancher Desktop\resources\resources\win32\bin\docker.exe`
- Arguments: `run --rm -v C:\silo-log-pull\app\data:/data silo-log-pull`
- Start in: `C:\silo-log-pull\app`

## Next Steps

- Review the [Configuration Reference](configuration-reference.md) for all available settings
- See [Example Configs](example_configs/) for different usage scenarios
