FROM python:3.12-slim
WORKDIR /opt/app
COPY scripts/ ./scripts/
ENV PYTHONPATH=/opt/app/scripts
RUN pip install --no-cache-dir google-cloud-storage python-dotenv requests flask gunicorn
ENTRYPOINT ["gunicorn", "-b", ":8080", "ingest_openaq:app", "--workers", "1"]
