**Deployment Alternatives**

This document describes affordable, low-ops deployment options for running Kestra and its database while keeping other pipeline resources in GCP (for example, ingestion on Cloud Run).

Overview
- Keep ingestion services on Cloud Run (recommended for autoscaling and minimal maintenance).
- Run Kestra + DB on either:
  - A small VPS (Contabo, Hetzner) — recommended for predictable, low-cost long-running services.
  - A GCE VM with >=4GB RAM (production) or with swap for low-cost dev usage.
  - (Optional) Cloud Run for Kestra with Cloud SQL — feasible but requires external DB (Cloud SQL) and a strategy for storage (object store or DB-backed storage).

VPS (Contabo) Quick Guide
- Recommended VM: 4GB RAM or larger. If only 2GB available, add 2–4GB swap.
- OS: Ubuntu 22.04 LTS or Debian 12.

Prerequisites (example)
```bash
sudo apt update
sudo apt install -y docker.io docker-compose git
sudo usermod -aG docker $USER
# Log out/in or run `newgrp docker`
```

Local Postgres vs Cloud SQL
- You can run Postgres locally on the VPS (example compose provided) or use Cloud SQL (recommended for reliability). To use Cloud SQL, remove the `kestra_postgres` service and update `datasources.postgres.url` to point to your Cloud SQL instance (or use the Cloud SQL Proxy).

docker-compose (VPS) recommendations
- Use the provided `docker-compose.yml` for a VPS-friendly configuration.
- Ensure the Kestra JVM heap is sized for available RAM: for 4GB use `-Xmx1536m`; for 2GB use `-Xmx512m`.

Systemd service
- Example unit file `docs/kestra-stack.service.example` is provided. Copy it to `/etc/systemd/system/kestra-stack.service` and enable+start it.

Networking and TLS
- Open required ports (8080, 8081) or place nginx/Caddy in front to proxy on 80/443 and handle TLS (Let's Encrypt or Cloudflare).

Cloud Run as alternative
- Keep ingestion on Cloud Run. If you prefer Kestra on managed infra, you can run Kestra on Cloud Run but must use Cloud SQL for persistence and an external storage solution (S3/GCS) for flows and artifacts.

Next steps
- If you want, I can commit the `docker-compose.yml` and systemd unit now and help tailor it to your target VPS (Contabo) or to switch Postgres to Cloud SQL.
