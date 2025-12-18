================================================================================
silo-log-pull - Offline Container Package
================================================================================

This package contains everything needed to run silo-log-pull with containers
on an offline system without internet access.

CONTENTS:
  - silo-log-pull.tar     Container image (Docker/Podman)
  - app/                  Application data directory
  - docs/                 Complete documentation
  - scripts/              Setup and utility scripts
  - offline-extract.sh    Linux/macOS setup script
  - offline-extract.ps1   Windows setup script
  - README-OFFLINE.txt    This file

QUICK START:

  Linux/macOS:
    1. Extract this archive: unzip silo-log-pull-container-offline.zip
    2. Run setup script: ./offline-extract.sh
    3. Follow on-screen instructions

  Windows:
    1. Extract this archive: Expand-Archive silo-log-pull-container-offline.zip
    2. Run setup script: .\offline-extract.ps1
    3. Follow on-screen instructions

MANUAL INSTALLATION (if extraction script doesn't work):

  Linux/macOS:
    docker load -i silo-log-pull.tar
    (or: podman load -i silo-log-pull.tar)

  Windows:
    docker load -i silo-log-pull.tar

CONFIGURATION:

  See docs/configuration-reference.md for complete configuration details.

  Quick start:
    1. Copy app/data/example_silo_config.json to app/data/silo_config.json
    2. Edit silo_config.json with your organization name
    3. Create app/data/token.txt with your API token

RUNNING:

  After loading the image and configuring:

  Linux/macOS:
    cd app
    docker run --rm -v $(pwd)/data:/data silo-log-pull
    (or: podman run --rm -v $(pwd)/data:/data silo-log-pull)

  Windows:
    cd app
    docker run --rm -v ${PWD}/data:/data silo-log-pull

  Logs will be written to app/data/logs/

DOCUMENTATION:

  All documentation is in the docs/ directory:
    - README.md                      Documentation index
    - configuration-reference.md     All settings and options
    - container-guide.md            Container deployment guide
    - scheduled-execution.md        Automation setup
    - example_configs/              Example configurations

SUPPORT:

  See https://gitlab.com/breakwaterlabs/silo-log-pull for updates and support.

================================================================================
