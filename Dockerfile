FROM python:3.13-alpine

# Set environment variable to indicate Docker mode
ENV DOCKER_CONTAINER=true

# Set working directory
WORKDIR /app

# Copy application file
COPY silo_batch_pull.py /app/

# Copy and install Python dependencies
COPY requirements.txt ./requirements.txt
RUN apk add --no-cache gcc musl-dev gmp-dev &&\
    pip install --no-cache-dir -r requirements.txt &&\
    mkdir -p /config /logs

# Volume mounts for configuration and logs
VOLUME ["/config", "/logs"]

# Run the application
ENTRYPOINT ["python", "/app/silo_batch_pull.py"]