================================================================================
silo-log-pull - Offline Python Package
================================================================================

This package contains everything needed to run silo-log-pull on an offline
system without internet access.

CONTENTS:
  - app/                  Python application and dependencies
  - docs/                 Complete documentation
  - scripts/              Setup and utility scripts
  - offline-extract.sh    Linux/macOS setup script
  - offline-extract.ps1   Windows setup script
  - README-OFFLINE.txt    This file

QUICK START:

  Linux/macOS:
    1. Extract this archive: unzip silo-log-pull-offline.zip
    2. Run setup script: ./offline-extract.sh
    3. Follow on-screen instructions

  Windows:
    1. Extract this archive: Expand-Archive silo-log-pull-offline.zip
    2. Run setup script: .\offline-extract.ps1
    3. Follow on-screen instructions

MANUAL INSTALLATION (if extraction script doesn't work):

  Linux/macOS:
    cd app
    python3 -m venv venv
    source venv/bin/activate
    pip install --no-index --find-links silo-dependencies -r requirements.txt

  Windows:
    cd app
    python -m venv venv
    .\venv\Scripts\Activate.ps1
    pip install --no-index --find-links silo-dependencies -r requirements.txt

CONFIGURATION:

  See docs/configuration-reference.md for complete configuration details.

  Quick start:
    1. Copy app/data/example_silo_config.json to app/data/silo_config.json
    2. Edit silo_config.json with your organization name
    3. Create app/data/token.txt with your API token

RUNNING:

  After installation and configuration:
    cd app
    source venv/bin/activate  (Linux/macOS) or .\venv\Scripts\Activate.ps1 (Windows)
    python silo_batch_pull.py

DOCUMENTATION:

  All documentation is in the docs/ directory:
    - README.md                      Documentation index
    - configuration-reference.md     All settings and options
    - python-guide.md               Python deployment guide
    - scheduled-execution.md        Automation setup
    - example_configs/              Example configurations

SUPPORT:

  See https://gitlab.com/breakwaterlabs/silo-log-pull for updates and support.

================================================================================
