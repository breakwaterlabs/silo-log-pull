# Using Pre-Built Docker Images

Pre-built Docker images are automatically published to the GitLab Container Registry. You can use these instead of building locally.

## Pulling Pre-Built Images

### Official Images from BreakwaterLabs

```bash
# Pull the latest image
docker pull registry.gitlab.com/breakwaterlabs/silo-log-pull:latest

# Or pull a specific version
docker pull registry.gitlab.com/breakwaterlabs/silo-log-pull:v1.0.0

# Or pull a specific commit
docker pull registry.gitlab.com/breakwaterlabs/silo-log-pull:abc1234
```

### Using the Pre-Built Image

Once pulled, navigate to the `app/` directory and run it:

```bash
cd app
docker run --rm -v $(pwd)/data:/data registry.gitlab.com/breakwaterlabs/silo-log-pull:latest
```

Or tag it locally for convenience:

```bash
docker pull registry.gitlab.com/breakwaterlabs/silo-log-pull:latest
docker tag registry.gitlab.com/breakwaterlabs/silo-log-pull:latest silo-log-pull:latest

# Navigate to app directory and run with the simpler name
cd app
docker run --rm -v $(pwd)/data:/data silo-log-pull:latest
```

If you've forked this repo to your own GitLab account, your images will be published to:
```
registry.gitlab.com/YOUR_USERNAME/silo-log-pull:latest
```

Replace `breakwaterlabs` with your GitLab username in all examples above.

## Available Tags

The CI/CD pipeline automatically creates these tags:

- **`latest`** - Most recent build from the main branch or latest release tag
- **`v1.0.0`** (example) - Specific version tags when releases are created
- **`abc1234`** (example) - Specific commit SHA for reproducibility

## For Offline Systems

To transfer a pre-built image to an offline system:

### 1. Pull and Export on Connected System

```bash
# Pull the image
docker pull registry.gitlab.com/breakwaterlabs/silo-log-pull:latest

# Export to TAR file
docker save registry.gitlab.com/breakwaterlabs/silo-log-pull:latest -o silo-log-pull.tar
```

### 2. Transfer and Import on Offline System

Transfer `silo-log-pull.tar` to the offline system, then:

```bash
# Import the image
docker load -i silo-log-pull.tar

# Verify
docker images | grep silo-log-pull
```

## CI/CD Pipeline

The GitLab CI/CD pipeline automatically:

1. **Builds** the Docker image on every commit
2. **Tests** basic functionality (verifies Python runs)
3. **Publishes** to the GitLab Container Registry when:
   - Commits are pushed to the main branch (tagged as `latest`)
   - Version tags are created (tagged as `latest` and the version tag)

### Build Status

Check the pipeline status at:
```
https://gitlab.com/breakwaterlabs/silo-log-pull/-/pipelines
```

### Registry Location

View available images at:
```
https://gitlab.com/breakwaterlabs/silo-log-pull/container_registry
```

## Verifying Image Authenticity

To verify what image you're using:

```bash
# Inspect the image
docker inspect registry.gitlab.com/breakwaterlabs/silo-log-pull:latest

# Check the creation date and labels
docker inspect registry.gitlab.com/breakwaterlabs/silo-log-pull:latest | grep -i created
```

## Updating to Latest Version

To update to the latest version:

```bash
# Pull the latest image
docker pull registry.gitlab.com/breakwaterlabs/silo-log-pull:latest

# Run with the updated image
docker run --rm -v $(pwd)/data:/data registry.gitlab.com/breakwaterlabs/silo-log-pull:latest
```