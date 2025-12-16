# Getting Started on Windows with Rancher Desktop

This guide will help you set up and run silo-log-pull on Windows using Rancher Desktop as your container runtime.

## Why Rancher Desktop?

Rancher Desktop is an open-source alternative to Docker Desktop that provides container management capabilities. Unlike Docker Desktop, Rancher Desktop is free for commercial use and doesn't require a paid subscription for business environments.

## Prerequisites

- Windows 10/11 (64-bit)
- Administrator access for initial installation
- Your Silo organization name
- Your Silo API token (32-character base64 string)

## Step 1: Install Rancher Desktop

1. Download Rancher Desktop from: https://rancherdesktop.io/
2. Run the installer and follow the installation wizard
3. Choose **dockerd (moby)** as the container runtime when prompted (this provides Docker compatibility)
4. Launch Rancher Desktop and wait for it to initialize (this may take a few minutes on first run)

## Step 2: Verify Installation

Open PowerShell and verify Docker is available:

```powershell
docker --version
docker-compose --version
```

You should see version information for both commands.

## Step 3: Set Up Your Project

   1. Download the ZIP file from the repository
   2. Extract it to a location like `C:\silo-log-pull`
   3. Create your configuration files -- See the [command reference](configuration-reference.md#initial-configuration-steps) for details.
   4. Open PowerShell and navigate to the app directory:
   ```powershell
   cd C:\silo-log-pull\app
   ```

## Step 4: Build and Run

Build the Docker image:

```powershell
docker build -t silo-log-pull .
```

Run the container:

```powershell
docker run --rm -v ${PWD}/data:/data silo-log-pull
```

## Step 5: View Your Logs

After the script completes, your logs will be in the `data\logs\` directory:

```powershell
dir data\logs
```

## Troubleshooting

### Rancher Desktop Not Starting

- Check that Virtualization is enabled in your BIOS/UEFI
- Try restarting your computer
- Check Rancher Desktop logs in the settings panel

### "Docker not found" Error

- Make sure Rancher Desktop is fully started (green indicator in system tray)
- Restart PowerShell after installing Rancher Desktop
- Ensure dockerd (moby) runtime is selected in Rancher Desktop settings

### Volume Mount Issues on Windows

If you encounter path issues, try using the full path:

```powershell
docker run --rm -v C:\silo-log-pull\app\data:/data silo-log-pull
```

### Permission Errors

Make sure the `data` directory has write permissions. If needed:

```powershell
icacls data /grant Everyone:F /T
```

## Advanced Usage

### Using Docker Compose for Repeated Runs

If you plan to run this regularly, Docker Compose makes it easier:

1. Create a `.env` file:
   ```powershell
   notepad .env
   ```

2. Add your organization name (this overrides the config file):
   ```
   SILO_API_ORG_NAME=YourOrgName
   ```

3. Run with Docker Compose:
   ```powershell
   docker-compose up
   ```

   To run in the background:
   ```powershell
   docker-compose up -d
   ```

### Override Settings with Environment Variables

You can override any configuration setting without editing the config file:

```powershell
docker run --rm `
  -v ${PWD}/data:/data `
  -e SILO_DATE_START="2024-01-01" `
  -e SILO_FETCH_NUM_DAYS=30 `
  -e SILO_SECCURE_DECRYPT_LOGS=true `
  -e SILO_OUTPUT_CSV=true `
  silo-log-pull
```

Available environment variables use the format `SILO_<SETTING_NAME>` in uppercase. See the main README for a complete list.

### Scheduled Execution

Use Windows Task Scheduler to run the container on a schedule:

1. Open Task Scheduler
2. Create a new task with the action:
   - Program: `C:\Program Files\Rancher Desktop\resources\resources\win32\bin\docker.exe`
   - Arguments: `run --rm -v C:\silo-log-pull\app\data:/data silo-log-pull`
   - Start in: `C:\silo-log-pull\app`

## Next Steps

- Review the [Configuration Reference](../README.md#configuring-the-script) for all available settings
- Check out [Example Configs](example_configs/README.md) for different usage scenarios
- Set up scheduled automated pulls using Task Scheduler
