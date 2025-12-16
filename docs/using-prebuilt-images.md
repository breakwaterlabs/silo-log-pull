# Using Pre-Built Docker Images

Pre-built images are published to the GitLab Container Registry.

## Pulling Images

```bash
docker pull registry.gitlab.com/breakwaterlabs/silo-log-pull:latest
```

Available tags:
- `latest` - Most recent build from main branch
- `v1.0.0` (example) - Specific version releases
- `abc1234` (example) - Specific commit SHA

For forked repositories, replace `breakwaterlabs` with your GitLab username.

## Running

```bash
cd app
docker run --rm -v $(pwd)/data:/data registry.gitlab.com/breakwaterlabs/silo-log-pull:latest
```

Optionally tag locally for convenience:
```bash
docker tag registry.gitlab.com/breakwaterlabs/silo-log-pull:latest silo-log-pull
docker run --rm -v $(pwd)/data:/data silo-log-pull
```

## Offline Systems

Export on a connected system:
```bash
docker pull registry.gitlab.com/breakwaterlabs/silo-log-pull:latest
docker save registry.gitlab.com/breakwaterlabs/silo-log-pull:latest -o silo-log-pull.tar
```

Import on the offline system:
```bash
docker load -i silo-log-pull.tar
```

See [Offline Systems Guide](offline-systems.md) for detailed instructions.

## CI/CD Pipeline

The GitLab pipeline builds and publishes images automatically:
- Pipeline status: https://gitlab.com/breakwaterlabs/silo-log-pull/-/pipelines
- Container registry: https://gitlab.com/breakwaterlabs/silo-log-pull/container_registry