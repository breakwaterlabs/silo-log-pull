# silo-log-pull

A tool for downloading and processing Silo logs from Authentic8. Supports automated workflows, container deployment, and separation of duties scenarios.

## Features

- Download and decrypt Silo audit logs
- JSON-based configuration with environment variable overrides
- Container and Python deployment options
- Support for air-gapped and offline systems

## Quick Start

1. **Pull the container image:**
   ```bash
   docker pull registry.gitlab.com/breakwaterlabs/silo-log-pull:latest
   docker tag registry.gitlab.com/breakwaterlabs/silo-log-pull:latest silo-log-pull
   ```

2. **Download and extract this repository** to get the configuration templates.

3. **Configure:** Copy `app/data/example_silo_config.json` to `app/data/silo_config.json` and set your organization name. Add your API token to `app/data/token.txt`.

4. **Run:**
   ```bash
   cd app
   docker run --rm -v $(pwd)/data:/data silo-log-pull
   ```

Logs are written to `app/data/logs/`.

For Python deployment without containers, see the [Python Guide](docs/python-guide.md).

## Documentation

- **[Full Documentation](docs/README.md)** - All guides and references
- **[Configuration Reference](docs/configuration-reference.md)** - All settings and options
- **[Example Configs](docs/example_configs/)** - Ready-to-use configurations

## License

See LICENSE.md for details.
