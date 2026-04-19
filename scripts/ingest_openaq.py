import os
import requests
import json
from datetime import datetime, timezone
from google.cloud import storage
from dotenv import load_dotenv, find_dotenv
from flask import Flask, request, jsonify

load_dotenv(find_dotenv())

PROJECT_ID = os.getenv("GCP_PROJECT_ID")
BUCKET_NAME = os.getenv("GCS_BUCKET_NAME")
OPENAQ_API_KEY = os.getenv("OPENAQ_API_KEY")
LOCATIONS_URL = "https://api.openaq.org/v3/locations"

# OpenAQ v3 uses numeric country IDs. This covers major regions for global AQI coverage.
TARGET_COUNTRIES: dict[int, str] = {
    28:  "BR",  # Brazil
    155: "US",  # United States
    100: "IN",  # India
    45:  "CN",  # China
    65:  "DE",  # Germany
}


def fetch_locations(country_id: int, country_code: str) -> list[dict]:
    """Fetch active air quality monitoring stations for a country."""
    headers = {"X-API-Key": OPENAQ_API_KEY} if OPENAQ_API_KEY else {}
    params = {"countries_id": country_id, "limit": 1000}

    print(f"Fetching locations for {country_code} (id={country_id})...")
    response = requests.get(LOCATIONS_URL, headers=headers, params=params)
    response.raise_for_status()

    results = response.json().get("results", [])
    print(f"  → {len(results)} stations found.")
    return results


def upload_ndjson_to_gcs(records: list[dict], filename: str) -> None:
    """Upload a list of records as NDJSON (one JSON object per line) to GCS."""
    credentials_path = os.getenv("GOOGLE_APPLICATION_CREDENTIALS")
    if credentials_path:
        storage_client = storage.Client.from_service_account_json(credentials_path)
    else:
        storage_client = storage.Client()

    bucket = storage_client.bucket(BUCKET_NAME)
    blob = bucket.blob(filename)
    ndjson_content = "\n".join(json.dumps(record) for record in records)
    blob.upload_from_string(data=ndjson_content, content_type="application/json")
    print(f"Uploaded {len(records)} records → gs://{BUCKET_NAME}/{filename}")


def run_ingest(api_key: str | None = None) -> dict:
    """Run the ingestion flow and return a summary dict."""
    # allow caller to override the API key (useful for HTTP-triggered runs)
    global OPENAQ_API_KEY
    if api_key:
        OPENAQ_API_KEY = api_key

    ingested_at = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
    all_records: list[dict] = []

    for country_id, country_code in TARGET_COUNTRIES.items():
        records = fetch_locations(country_id, country_code)
        for record in records:
            record["_ingested_at"] = ingested_at
            record["_country_code"] = country_code
        all_records.extend(records)

    timestamp = datetime.now(timezone.utc).strftime("%Y%m%d_%H%M%S")
    filename = f"raw/openaq_{timestamp}.json"
    upload_ndjson_to_gcs(all_records, filename)

    return {"filename": filename, "records": len(all_records)}


app = Flask(__name__)


@app.route("/run", methods=["POST"])
def run_endpoint():
    """HTTP endpoint to trigger ingestion. Returns JSON summary.

    Accepts an optional header `X-OPENAQ-API-KEY` to override the configured
    `OPENAQ_API_KEY` for this run (useful when Cloud Run env var isn't set).
    """
    try:
        api_key = None
        if "X-OPENAQ-API-KEY" in request.headers:
            api_key = request.headers.get("X-OPENAQ-API-KEY")
        result = run_ingest(api_key=api_key)
        return jsonify({"status": "ok", "filename": result["filename"], "records": result["records"]}), 200
    except Exception as exc:
        return jsonify({"status": "error", "error": str(exc)}), 500


if __name__ == "__main__":
    summary = run_ingest()
    print(f"Ingest completed: {summary}")