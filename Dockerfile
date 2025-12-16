# Stage 1: Builder - compile dependencies
FROM python:3.13-alpine AS builder

# Install build dependencies
RUN apk add --no-cache gcc musl-dev gmp-dev

# Copy requirements and install Python dependencies to a temporary location
COPY requirements.txt /tmp/requirements.txt
RUN pip install --no-cache-dir --prefix=/install -r /tmp/requirements.txt

# Stage 2: Runtime - minimal final image
FROM python:3.13-alpine

# Set environment variable to indicate Docker mode
ENV DOCKER_CONTAINER=true

# Copy installed Python packages from builder stage
COPY --from=builder /install /usr/local

# Set working directory
WORKDIR /app

# Copy application file
COPY silo_batch_pull.py /app/

# Create volume directories
RUN mkdir -p /config /logs

# Volume mounts for configuration and logs
VOLUME ["/config", "/logs"]

# Run the application
ENTRYPOINT ["python", "/app/silo_batch_pull.py"]