================================================================================
Silo Log Pull - Configuration Backup
================================================================================

This backup contains your configuration files and secrets, excluding log files.

CONTENTS:
  - data/              Configuration files from your data directory
  - data_dir.txt       Path to your data directory (if customized)
  - README.txt         This file

RESTORING:

To restore this backup:

1. Extract this archive to a temporary location:

   Linux/macOS:
     unzip silo-log-pull-config-backup-*.zip -d /tmp/restore

   Windows:
     Expand-Archive silo-log-pull-config-backup-*.zip -DestinationPath C:\temp\restore

2. Copy the contents to your silo-log-pull installation:

   If using default data directory:
     Linux/macOS: cp -r /tmp/restore/config-backup/data/* <silo-log-pull>/app/data/
     Windows:     Copy-Item C:\temp\restore\config-backup\data\* -Destination <silo-log-pull>\app\data\ -Recurse -Force

   If using custom data directory (check data_dir.txt):
     Linux/macOS: cp -r /tmp/restore/config-backup/data/* <your-custom-data-path>/
     Windows:     Copy-Item C:\temp\restore\config-backup\data\* -Destination <your-custom-data-path>\ -Recurse -Force

3. Copy data_dir.txt if it exists:
   Linux/macOS: cp /tmp/restore/config-backup/data_dir.txt <silo-log-pull>/app/
   Windows:     Copy-Item C:\temp\restore\config-backup\data_dir.txt -Destination <silo-log-pull>\app\

IMPORTANT NOTES:

- This backup does NOT include log files
- Keep this backup secure as it contains API tokens and configuration
- Verify file permissions after restore (especially token.txt)

For more information, see:
https://gitlab.com/breakwaterlabs/silo-log-pull

================================================================================
