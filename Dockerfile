FROM python:3.13-alpine
WORKDIR /usr/src/silo
COPY requirements.txt ./requirements.txt
RUN pip install --no-cache-dir -r requirements.txt
COPY . .
COPY config/example_silo_config.json config/silo_config.json
ENTRYPOINT [ "python", "./silo_batch_pull.py" ]