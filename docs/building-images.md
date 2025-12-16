# Building Container Images

This guide covers building silo-log-pull container images locally and setting up CI/CD pipelines.

## Building Locally

From the repository root:

```bash
docker build -t silo-log-pull .
```

Run your locally-built image:
```bash
docker run --rm -v $(pwd)/data:/data silo-log-pull
```

## Exporting Images for Offline Systems

Export the image to a tar file:
```bash
docker save silo-log-pull -o silo-log-pull.tar
```

Transfer the tar file to the offline system, then import:
```bash
docker load -i silo-log-pull.tar
```

See [Offline Systems Guide](offline-systems.md) for complete air-gapped deployment instructions.

## GitLab CI/CD Setup

The repository includes a `.gitlab-ci.yml` that automatically builds and publishes images.

### What It Does

The pipeline automatically:
1. Builds the Docker image on every commit
2. Tests that Python runs correctly in the container
3. Publishes images to GitLab Container Registry when:
   - Code is pushed to the main branch (tagged as `latest`)
   - Version tags are created (tagged as the version and `latest`)

### Setup

The pipeline works out of the box with GitLab:
1. Push this repository to GitLab
2. The pipeline runs automatically
3. Images are published to your project's Container Registry

### Image Tags

The CI/CD pipeline creates these tags:
- `latest` - Most recent build from main branch or latest release tag
- `v1.0.0` - Specific version tags you create
- `abc1234` - Short commit SHA (every commit)

### Accessing Your Images

Official images:
```bash
docker pull registry.gitlab.com/breakwaterlabs/silo-log-pull:latest
```

For forked repositories:
```bash
docker pull registry.gitlab.com/YOUR_USERNAME/silo-log-pull:latest
```

### Creating a Release

```bash
git tag v1.0.0
git push origin v1.0.0
```

The pipeline will build and tag the image as both `v1.0.0` and `latest`.

### Viewing Pipeline Status

- Pipeline status: https://gitlab.com/breakwaterlabs/silo-log-pull/-/pipelines
- Container registry: https://gitlab.com/breakwaterlabs/silo-log-pull/container_registry

## Customizing the Pipeline

### Build on Additional Branches

Edit `.gitlab-ci.yml`:
```yaml
publish:
  rules:
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH
    - if: $CI_COMMIT_BRANCH == "development"  # Add this
    - if: $CI_COMMIT_TAG
```

### Use External Registry

To push to Docker Hub or another registry:

1. Set CI/CD variables in **Settings → CI/CD → Variables**:
   - `DOCKER_REGISTRY_USER`
   - `DOCKER_REGISTRY_PASSWORD` (masked)
   - `DOCKER_REGISTRY` (e.g., `docker.io`)

2. Update `.gitlab-ci.yml`:
   ```yaml
   variables:
     IMAGE_NAME: $DOCKER_REGISTRY/YOUR_USERNAME/silo-log-pull

   publish:
     before_script:
       - docker login -u $DOCKER_REGISTRY_USER -p $DOCKER_REGISTRY_PASSWORD $DOCKER_REGISTRY
   ```

### Making Images Public

1. Go to **Settings → General → Visibility, project features, permissions**
2. Under **Container registry**, select **Everyone With Access**
3. Click **Save changes**

## Troubleshooting

### Pipeline Fails with "Permission Denied"
- Check **Settings → General → Visibility** - Container registry should be enabled
- Pipeline should have permission to push (automatic for GitLab registry)

### Images Not Appearing in Registry
- Verify the `publish` job completed successfully
- Ensure the pipeline ran on main branch or a tag

### Disabling CI/CD

Delete or rename `.gitlab-ci.yml`, or disable in **Settings → General → Visibility → CI/CD**.
