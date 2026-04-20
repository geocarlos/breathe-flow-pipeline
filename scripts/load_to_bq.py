#!/usr/bin/env python3
"""Load today's OpenAQ NDJSON files from GCS into BigQuery.

Finds all GCS files under raw/openaq_<DATE>*.json and loads them into
a BigQuery table using WRITE_APPEND + auto-detect schema.  The dbt
incremental models handle deduplication on top of this.

Usage:
    python scripts/load_to_bq.py [--date YYYYMMDD]

Environment variables:
    GCP_PROJECT_ID              BigQuery project ID (required)
    GCS_BUCKET_NAME             GCS bucket containing raw/ files (required)
    BQ_SOURCE_DATASET           BigQuery dataset to load into (default: openaq)
    BQ_TABLE                    BigQuery table name (default: raw)
    GOOGLE_APPLICATION_CREDENTIALS  Path to service account JSON (optional)
"""

import argparse
import os
import sys
from datetime import datetime, timezone

from google.cloud import bigquery, storage


def get_gcs_uris_for_date(
    bucket_name: str,
    date_str: str,
    credentials_path: str | None,
) -> list[str]:
    """Return gs:// URIs of all NDJSON files matching the given date prefix."""
    if credentials_path:
        client = storage.Client.from_service_account_json(credentials_path)
    else:
        client = storage.Client()

    prefix = f"raw/openaq_{date_str}"
    blobs = list(client.bucket(bucket_name).list_blobs(prefix=prefix))
    uris = [f"gs://{bucket_name}/{b.name}" for b in blobs if b.name.endswith(".json")]
    return uris


def load_uris_to_bigquery(
    project: str,
    dataset: str,
    table: str,
    uris: list[str],
    credentials_path: str | None,
) -> None:
    """Load a list of GCS URIs into a BigQuery table with WRITE_APPEND."""
    if credentials_path:
        client = bigquery.Client.from_service_account_json(credentials_path, project=project)
    else:
        client = bigquery.Client(project=project)

    # Create dataset if it doesn't exist
    bq_dataset = bigquery.Dataset(f"{project}.{dataset}")
    bq_dataset.location = "US"
    client.create_dataset(bq_dataset, exists_ok=True)
    print(f"Dataset {project}.{dataset} ready.")

    table_ref = f"{project}.{dataset}.{table}"
    job_config = bigquery.LoadJobConfig(
        source_format=bigquery.SourceFormat.NEWLINE_DELIMITED_JSON,
        autodetect=True,
        write_disposition=bigquery.WriteDisposition.WRITE_APPEND,
        ignore_unknown_values=True,
    )

    print(f"Loading {len(uris)} file(s) into {table_ref}")
    for uri in uris:
        print(f"  {uri}")

    load_job = client.load_table_from_uri(uris, table_ref, job_config=job_config)
    load_job.result()  # blocks until complete

    dest = client.get_table(table_ref)
    print(f"Load complete — {table_ref} now has {dest.num_rows} total rows.")


def main() -> None:
    parser = argparse.ArgumentParser(description="Load GCS NDJSON files to BigQuery.")
    parser.add_argument(
        "--date",
        default=datetime.now(timezone.utc).strftime("%Y%m%d"),
        help="Date prefix YYYYMMDD to filter GCS files (default: today UTC).",
    )
    args = parser.parse_args()

    project = os.environ["GCP_PROJECT_ID"]
    bucket_name = os.environ["GCS_BUCKET_NAME"]
    dataset = os.getenv("BQ_SOURCE_DATASET", "openaq")
    table = os.getenv("BQ_TABLE", "raw")
    credentials_path = os.getenv("GOOGLE_APPLICATION_CREDENTIALS")

    print(f"Looking for GCS files with date prefix: {args.date}")
    uris = get_gcs_uris_for_date(bucket_name, args.date, credentials_path)

    if not uris:
        print("No files found for the given date. Nothing to load.")
        sys.exit(0)

    load_uris_to_bigquery(project, dataset, table, uris, credentials_path)
    print("Done.")


if __name__ == "__main__":
    main()
