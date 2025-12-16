
FROM python:3.13-alpine AS builder
RUN apk add --no-cache gcc musl-dev gmp-dev
COPY requirements.txt /tmp/requirements.txt
RUN pip install --no-cache-dir --prefix=/install -r /tmp/requirements.txt

# Stage 2: Runtime
FROM python:3.13-alpine
ARG SILO_LOGS_DIR=/logs \
    SILO_APP_DIR=/app

ENV DOCKER_CONTAINER=true \
    SILO_NON_INTERACTIVE=true \
    SILO_CONFIG_DIR=/config \
    SILO_LOG_IN_DIRECTORY=${SILO_LOGS_DIR} \
    SILO_LOG_OUT_DIRECTORY=${SILO_LOGS_DIR}

COPY --from=builder /install /usr/local
WORKDIR ${SILO_APP_DIR}
COPY silo_batch_pull.py ${SILO_APP_DIR}
RUN mkdir -p ${SILO_CONFIG_DIR} ${SILO_LOGS_DIR}
VOLUME [${SILO_CONFIG_DIR}, ${SILO_LOGS_DIR}]

ENTRYPOINT ["python", "silo_batch_pull.py"]