
FROM python:3.13-alpine AS builder
RUN apk add --no-cache gcc musl-dev gmp-dev
COPY requirements.txt /tmp/requirements.txt
RUN pip install --no-cache-dir --prefix=/install -r /tmp/requirements.txt

# Stage 2: Runtime
FROM python:3.13-alpine
ENV DOCKER_CONTAINER=true
COPY --from=builder /install /usr/local
WORKDIR /app
COPY silo_batch_pull.py /app/
RUN mkdir -p /config /logs
VOLUME ["/config", "/logs"]
ENTRYPOINT ["python", "/app/silo_batch_pull.py"]