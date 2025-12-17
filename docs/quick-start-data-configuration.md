# Quick Start: Data Directory Configuration

## Overview

This guide explains how to configure where silo-log-pull stores its data files, including configuration, logs, and credentials.

## Configuration Methods

### Method 1: data_dir.txt (Recommended)

The simplest method is creating a `data_dir.txt` file:

1. Create `app/data_dir.txt`
2. Add a single line with your desired path
3. Run silo-log-pull as normal

**Example - Relative Path:**
```
../shared-data
```

**Example - Absolute Path (Windows):**
```
C:\Silo\Production\Data
```

**Example - Absolute Path (Linux):**
```
/opt/silo/data
```

### Method 2: Environment Variable

Set the `SILO_DATA_DIR` environment variable:

**Windows PowerShell:**
```powershell
$env:SILO_DATA_DIR = "C:\Silo\Data"
```

**Linux/macOS:**
```bash
export SILO_DATA_DIR=/opt/silo/data
```

### Priority Order

If multiple methods are configured, this is the precedence (highest wins):
1. Environment variable (`SILO_DATA_DIR`)
2. data_dir.txt file
3. Default (`app/data/`)

## Use Cases

### Development Environment
```
# data_dir.txt
../dev-data
```

### Production Environment
```
# data_dir.txt
/opt/silo/production/data
```

### Multiple Instances
Create separate data_dir.txt for each instance pointing to different locations.

### Docker Deployments
Override the default `/data` mount:
```
# data_dir.txt
/custom-mount-point
```

## Migration from Deprecated data_dir Config

If your `silo_config.json` contains `data_dir`:

1. Note the value in your config file
2. Create `app/data_dir.txt` with that path
3. Remove the `data_dir` line from silo_config.json
4. Test to confirm redirection message appears

## Troubleshooting

**Issue:** "Warning: data_dir.txt is empty"
- **Solution:** Add a path to the file (cannot be blank)

**Issue:** "Warning: Could not create directory"
- **Solution:** Check permissions, ensure parent directory exists

**Issue:** Not seeing "Data folder has been redirected" message
- **Solution:** Check data_dir.txt is in same directory as silo_batch_pull.py (the `app/` directory)

## See Also

- [Configuration Reference](configuration-reference.md) - Complete configuration documentation
- [Python Guide](python-guide.md) - Python deployment details
- [Container Guide](container-guide.md) - Container deployment details
