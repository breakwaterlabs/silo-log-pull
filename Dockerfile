
FROM python:3.13-alpine AS builder
RUN apk add --no-cache gcc musl-dev gmp-dev
COPY requirements.txt /tmp/requirements.txt
RUN pip install --no-cache-dir --prefix=/install -r /tmp/requirements.txt

# Stage 2: Runtime
FROM python:3.13-alpine
ARG APP_DIR=/app \
    LOGS_DIR=logs

ENV DOCKER_CONTAINER=true \
    SILO_NON_INTERACTIVE=true \
    SILO_DATA_DIR=/data

COPY --from=builder /install /usr/local
WORKDIR ${SILO_APP_DIR}
COPY silo_batch_pull.py ${SILO_APP_DIR}
RUN mkdir -p ${SILO_DATA_DIR} ${SILO_DATA_DIR}/${LOGS_DIR}
VOLUME [${SILO_DATA_DIR}]

ENTRYPOINT ["python", "silo_batch_pull.py"]