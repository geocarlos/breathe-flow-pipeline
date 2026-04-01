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

## License
Distributed under the MIT License. See `LICENSE` for more information.
