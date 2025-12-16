# Using Pre-Built Docker Images

If this repository is hosted on GitLab with CI/CD enabled, you can use pre-built Docker images instead of building locally.

## Pulling Pre-Built Images

### From GitLab Container Registry

```bash
# Pull the latest image
docker pull registry.gitlab.com/YOUR_USERNAME/silo-log-pull:latest

# Or pull a specific version
docker pull registry.gitlab.com/YOUR_USERNAME/silo-log-pull:v1.0.0

# Or pull a specific commit
docker pull registry.gitlab.com/YOUR_USERNAME/silo-log-pull:abc1234
```

### Using the Pre-Built Image

Once pulled, you can run it directly:

```bash
docker run --rm -v $(pwd)/data:/data registry.gitlab.com/YOUR_USERNAME/silo-log-pull:latest
```

Or tag it locally for convenience:

```bash
docker pull registry.gitlab.com/YOUR_USERNAME/silo-log-pull:latest
docker tag registry.gitlab.com/YOUR_USERNAME/silo-log-pull:latest silo-log-pull:latest

# Now you can use it with the simpler name
docker run --rm -v $(pwd)/data:/data silo-log-pull:latest
```

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
docker pull registry.gitlab.com/YOUR_USERNAME/silo-log-pull:latest

# Export to TAR file
docker save registry.gitlab.com/YOUR_USERNAME/silo-log-pull:latest -o silo-log-pull.tar
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

Check the pipeline status in your GitLab repository at:
```
https://gitlab.com/YOUR_USERNAME/silo-log-pull/-/pipelines
```

### Registry Location

View available images at:
```
https://gitlab.com/YOUR_USERNAME/silo-log-pull/container_registry
```

## Verifying Image Authenticity

To verify you're using an official image from the repository:

```bash
# Inspect the image
docker inspect registry.gitlab.com/YOUR_USERNAME/silo-log-pull:latest

# Check the creation date and labels
docker inspect registry.gitlab.com/YOUR_USERNAME/silo-log-pull:latest | grep -i created
```

## Updating to Latest Version

To update to the latest version:

```bash
# Pull the latest image
docker pull registry.gitlab.com/YOUR_USERNAME/silo-log-pull:latest

# Remove old containers (if any are running)
docker ps -a | grep silo-log-pull

# Run with the updated image
docker run --rm -v $(pwd)/data:/data registry.gitlab.com/YOUR_USERNAME/silo-log-pull:latest
```

## Building Locally vs Using Pre-Built

**Use pre-built images when:**
- You want to save time (no build required)
- You want to ensure you're using the official, tested version
- You're deploying to multiple systems

**Build locally when:**
- You've made custom modifications to the code
- You're developing or testing changes
- You want to verify the build process yourself
