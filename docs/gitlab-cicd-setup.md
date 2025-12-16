# GitLab CI/CD Setup

This repository includes a GitLab CI/CD configuration that automatically builds and publishes Docker images.

## What It Does

The pipeline automatically:

1. Builds the Docker image on every commit
2. Tests* that Python runs correctly in the container
3. Publishes images to GitLab Container Registry when:
   - Code is pushed to the main branch (tagged as `latest`)
   - Version tags are created (tagged as the version and `latest`)

## Setup

The `.gitlab-ci.yml` file works out of the box with GitLab's built-in features. Simply:

1. Push this repository to GitLab
2. The pipeline will run automatically
3. Images will be published to your project's Container Registry

## Accessing Your Images

Images are published to:
```
registry.gitlab.com/YOUR_USERNAME/YOUR_PROJECT_NAME:TAG
```

For example:
```bash
docker pull registry.gitlab.com/johndoe/silo-log-pull:latest
```

## Creating a Release

To publish a versioned release:

### Via Command Line

```bash
# Create and push a version tag
git tag v1.0.0
git push origin v1.0.0
```

The pipeline will automatically:
- Build the image
- Tag it as `v1.0.0` and `latest`
- Push to the Container Registry

### Via GitLab UI

1. Go to **Repository → Tags**
2. Click **New tag**
3. Enter tag name (e.g., `v1.0.0`)
4. Optionally add release notes
5. Click **Create tag**

The pipeline will run automatically.

## Viewing Pipeline Status

Check your pipeline status at:
```
https://gitlab.com/YOUR_USERNAME/YOUR_PROJECT_NAME/-/pipelines
```

## Viewing Available Images

Browse published images at:
```
https://gitlab.com/YOUR_USERNAME/YOUR_PROJECT_NAME/container_registry
```

## Image Tags

The CI/CD pipeline creates these tags:

- **`latest`** - Most recent build from main branch or latest release tag
- **`v1.0.0`** - Specific version tags you create
- **`abc1234`** - Short commit SHA (every commit)

## Registry Permissions

By default, GitLab Container Registry images are:
- **Private** - Only accessible to project members
- **Public** - Can be made public in **Settings → General → Visibility**

### Making Images Public

If you want anyone to pull your images:

1. Go to **Settings → General → Visibility, project features, permissions**
2. Expand **Visibility, project features, permissions**
3. Under **Container registry**, select **Everyone With Access**
4. Click **Save changes**

Now anyone can pull your images without authentication:
```bash
docker pull registry.gitlab.com/YOUR_USERNAME/YOUR_PROJECT_NAME:latest
```

## Using Images in Your Workflow

### For Users

Update your platform guides to reference the pre-built images:

```bash
# Instead of building locally:
docker build -t silo-log-pull .

# Use the pre-built image:
docker pull registry.gitlab.com/YOUR_USERNAME/silo-log-pull:latest
```

### For Offline Systems

1. Pull the image on a system with internet:
   ```bash
   docker pull registry.gitlab.com/YOUR_USERNAME/silo-log-pull:latest
   docker save registry.gitlab.com/YOUR_USERNAME/silo-log-pull:latest -o silo-log-pull.tar
   ```

2. Transfer `silo-log-pull.tar` to offline system

3. Load on offline system:
   ```bash
   docker load -i silo-log-pull.tar
   ```

## Customizing the Pipeline

### Build on Different Branches

To also publish images from a development branch, edit `.gitlab-ci.yml`:

```yaml
publish:
  # ... existing config ...
  rules:
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH
    - if: $CI_COMMIT_BRANCH == "development"  # Add this
    - if: $CI_COMMIT_TAG
```

### Add Additional Tests

Add more test steps in the `build` job:

```yaml
build:
  # ... existing config ...
  script:
    - docker build -t $IMAGE_NAME:$CI_COMMIT_SHORT_SHA .
    - docker run --rm $IMAGE_NAME:$CI_COMMIT_SHORT_SHA python --version
    # Add more tests:
    - docker run --rm $IMAGE_NAME:$CI_COMMIT_SHORT_SHA python -c "import seccure"
```

### Use External Registry

To push to Docker Hub or another registry instead:

1. Set these CI/CD variables in **Settings → CI/CD → Variables**:
   - `DOCKER_REGISTRY_USER` - Your registry username
   - `DOCKER_REGISTRY_PASSWORD` - Your registry password (masked)
   - `DOCKER_REGISTRY` - Registry URL (e.g., `docker.io`)

2. Update `.gitlab-ci.yml`:
   ```yaml
   variables:
     IMAGE_NAME: $DOCKER_REGISTRY/YOUR_USERNAME/silo-log-pull

   publish:
     before_script:
       - docker login -u $DOCKER_REGISTRY_USER -p $DOCKER_REGISTRY_PASSWORD $DOCKER_REGISTRY
   ```

## Troubleshooting

### Pipeline Fails with "Permission Denied"

GitLab Container Registry is enabled by default, but check:
1. **Settings → General → Visibility** - Container registry should be enabled
2. Pipeline should have permission to push (automatic for GitLab registry)

### Images Not Appearing in Registry

- Check that the `publish` job completed successfully
- Verify you're looking at the correct project's registry
- Ensure the pipeline ran on main branch or a tag

### Build Takes Too Long

The pipeline builds from scratch each time. To speed it up:

1. Use GitLab's Docker layer caching
2. Add to `.gitlab-ci.yml`:
   ```yaml
   build:
     cache:
       key: $CI_COMMIT_REF_SLUG
       paths:
         - .docker
   ```

## Disabling CI/CD

If you don't want to use CI/CD:

1. Delete or rename `.gitlab-ci.yml`
2. Or disable in **Settings → General → Visibility** → **CI/CD** → Disable

## Additional Resources

- [GitLab Container Registry Documentation](https://docs.gitlab.com/ee/user/packages/container_registry/)
- [GitLab CI/CD Documentation](https://docs.gitlab.com/ee/ci/)
- [Using Pre-Built Images](using-prebuilt-images.md)
