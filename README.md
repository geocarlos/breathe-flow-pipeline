# Breathe-Flow: Global Air Quality Pipeline

**Breathe-Flow** is an end-to-end data engineering pipeline designed to monitor and analyze global air quality index (AQI) data in real-time. This project was developed as a final capstone for the **Data Engineering Zoomcamp 2026**.

The pipeline fetches hourly sensor data from the **OpenAQ API**, processes it through a cloud-native Medallion architecture, and visualizes pollution trends across the globe.

## Architecture
* **Infrastructure:** **Terraform** (IaC) for provisioning Google Cloud Platform (GCP) resources.
* **Workflow Orchestration:** **Kestra** (running on Docker/Compute Engine) for scheduling and monitoring.
* **Data Lake:** **Google Cloud Storage (GCS)** for raw JSON landing.
* **Data Warehouse:** **Google BigQuery** for high-performance analytics.
* **Transformation:** **dbt (data build tool)** for modular, version-controlled SQL transformations.
* **Visualization:** **Streamlit** for a live interactive dashboard.

## The Dataset
This project utilizes the **OpenAQ API (v3)**, which aggregates environmental sensor data from 100+ countries. 
* **Update Frequency:** Hourly
* **Key Metrics:** PM2.5, PM10, NO2, O3, and CO levels.
* **Format:** Nested JSON parsed into structured Star-Schema tables.

## Getting Started

### 1. Prerequisites
* GCP Account and Service Account JSON key.
* Terraform installed.
* Docker & Docker Compose.
* OpenAQ API Key (Free tier).

### 2. Infrastructure Setup
```bash
cd terraform
terraform init
terraform apply
```

### 3. Orchestration
```bash
cd kestra
docker compose up -d
# Access UI at http://localhost:8080 to trigger the 'openaq_ingestion' flow.
```

### 4. Transformation
```bash
cd dbt_project
dbt build --var 'is_incremental: true'
```

## Analytics & Visualization
The final dashboard provides insights into:
1.  **Pollution Hotspots:** A real-time map of the world's most affected regions.
2.  **Temporal Trends:** Comparison of air quality during peak traffic hours vs. nighttime.
3.  **Country Rankings:** Live leaderboard of air quality by city and country.

## Project Roadmap
- [X] Initial Infrastructure with Terraform.
- [X] API Ingestion Script (Python).
- [ ] Kestra Workflow Automation.
- [ ] Advanced dbt Modeling (Incremental loads).
- [ ] Streamlit Dashboard Deployment.

## Kestra PoC (local)
A minimal PoC is scaffolded to run Kestra locally and execute the ingestion script.

- Flow: [kestra/flows/openaq_ingestion_flow.yml](kestra/flows/openaq_ingestion_flow.yml)
- Ingest image Dockerfile: [Dockerfile.ingest](Dockerfile.ingest)
- Compose: [docker-compose.yml](docker-compose.yml)

Quick start (local):
```bash
# Ensure you DO NOT commit credentials. Provide them via env or mount.
docker compose up -d
# Kestra UI: http://localhost:8081  (API server at http://localhost:8080)
# The `ingest` container is left running for ad-hoc runs; to run it manually:
docker compose exec ingest python ingest_openaq.py
```

Notes:
- The PoC mounts `./scripts` into Kestra so the Bash task can call the Python script.
- For production, create a dedicated service account, store credentials in Secret Manager, and avoid committing `google_credentials.json`.

Optional SA key generation (Terraform)
:
	The Terraform module now includes an optional toggle to create a long-lived service account key for the Kestra service account. This is intended only for local PoC usage. To enable, run Terraform with the variable:

```bash
terraform apply -var 'create_kestra_sa_key=true'
```

Warnings:
- Long-lived JSON keys are sensitive and will be stored in Terraform state. Prefer Workload Identity (GKE) or instance service account bindings for production.
- If you enable key creation, download the key securely and delete it from the Terraform state if you don't need it persisted.


## License
Distributed under the MIT License. See `LICENSE` for more information.
