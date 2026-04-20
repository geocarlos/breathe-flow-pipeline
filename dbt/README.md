# dbt Models (breathe_flow_dbt)

## Models

| Model | Type | Description |
|-------|------|-------------|
| `stg_openaq_raw` | incremental | Station snapshots from the raw BigQuery table. Unique key: `MD5(station_id \| ingested_at)`. Partitioned by `ingested_date`, clustered by `country_code`. |
| `fct_station_coverage` | incremental | Daily count of active stations per country. Aggregates `stg_openaq_raw` by `(country_code, ingested_date)`. |

## Running locally

### Option A — Local dbt install (recommended)

```bash
pip install dbt-bigquery
cp dbt/profiles.yml.example dbt/profiles.yml  # fill in your values

export GCP_PROJECT_ID=your-project
export BQ_DATASET=breathe_flow
export BQ_SOURCE_DATASET=openaq
export GOOGLE_APPLICATION_CREDENTIALS=/path/to/sa.json

dbt run --project-dir dbt --profiles-dir dbt
dbt test --project-dir dbt --profiles-dir dbt
```

### Option B — Docker runner

```bash
export DBT_PROJECT_DIR=$(pwd)/dbt
export PROFILES_DIR=$(pwd)/dbt
./scripts/run_dbt.sh deps
./scripts/run_dbt.sh run
```

### Full pipeline (ingest → load → dbt)

```bash
# Requires: GCP_PROJECT_ID, GCS_BUCKET_NAME, BQ_SOURCE_DATASET, BQ_DATASET, GOOGLE_APPLICATION_CREDENTIALS
python scripts/run_pipeline.py

# Skip individual steps:
python scripts/run_pipeline.py --skip-ingest           # data already in GCS
python scripts/run_pipeline.py --skip-ingest --skip-load  # data already in BQ
python scripts/run_pipeline.py --dbt-cmd "run test"    # run + test in one go
```

Kestra (`kestra/flows/breatheflow_openaq_to_bigquery.yml`) is an alternative
orchestrator for the same pipeline on the VPS — it runs ingest via Cloud Run,
then executes dbt inside the Kestra container.

## Environment variables

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `GCP_PROJECT_ID` | ✓ | — | GCP project ID |
| `BQ_DATASET` | ✓ | `breathe_flow` | dbt output dataset |
| `BQ_SOURCE_DATASET` | — | `openaq` | Dataset containing the raw table |
| `BQ_TABLE` | — | `raw` | Raw source table name |
| `GCS_BUCKET_NAME` | ✓ for load | — | GCS bucket with raw NDJSON files |
| `GOOGLE_APPLICATION_CREDENTIALS` | ✓ | — | Path to service account JSON |
