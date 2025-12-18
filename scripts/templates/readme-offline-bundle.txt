================================================================================
silo-log-pull - Offline Package
================================================================================

This package contains everything needed to run silo-log-pull on an offline
system without internet access.

CONTENTS:
  - app/                  Python application
{{PYTHON_DEPS_LINE}}
{{CONTAINER_IMAGE_LINE}}
  - docs/                 Complete documentation
  - scripts/              Setup and utility scripts
{{PYTHON_EXTRACT_LINE}}
{{CONTAINER_EXTRACT_LINE}}
  - README-OFFLINE.txt    This file

QUICK START:
{{PYTHON_QUICKSTART}}
{{CONTAINER_QUICKSTART}}

CONFIGURATION:

  See docs/configuration-reference.md for complete configuration details.

  Quick start:
    1. Copy app/data/example_silo_config.json to app/data/silo_config.json
    2. Edit silo_config.json with your organization name
    3. Create app/data/token.txt with your API token

RUNNING:
{{PYTHON_RUNNING}}
{{CONTAINER_RUNNING}}

DOCUMENTATION:

  All documentation is in the docs/ directory:
    - README.md                      Documentation index
    - configuration-reference.md     All settings and options
{{PYTHON_DOC_LINE}}
{{CONTAINER_DOC_LINE}}
    - scheduled-execution.md        Automation setup
    - example_configs/              Example configurations

SUPPORT:

  See https://gitlab.com/breakwaterlabs/silo-log-pull for updates and support.

================================================================================
