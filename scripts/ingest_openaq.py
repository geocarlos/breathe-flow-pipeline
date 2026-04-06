import os
import requests
import json
from datetime import datetime, timedelta
from google.cloud import storage
from dotenv import load_dotenv, find_dotenv

# This will find the .env at the project root even if 
# you run the script from inside the scripts/ folder.
load_dotenv(find_dotenv())

# --- Configuration ---
# You'll set these via Terraform or Environment Variables
PROJECT_ID = os.getenv("GCP_PROJECT_ID")
BUCKET_NAME = os.getenv("GCS_BUCKET_NAME")
OPENAQ_API_KEY = os.getenv("OPENAQ_API_KEY") 
BASE_URL = "https://api.openaq.org/v3/locations"

def fetch_openaq_data(country_code="BR"):
    """Fetches the latest air quality data for a specific country."""
    # We want data from the last 24 hours
    date_from = (datetime.utcnow() - timedelta(days=1)).strftime('%Y-%m-%dT%H:%M:%S')
    
    headers = {"X-API-Key": OPENAQ_API_KEY}
    params = {
        "countries_id": country_code,
        "limit": 1000,
        "date_from": date_from
    }

    print(f"Fetching data for {country_code} since {date_from}...")
    response = requests.get(BASE_URL, headers=headers, params=params)
    
    if response.status_code == 200:
        return response.json()
    else:
        raise Exception(f"API Error: {response.status_code} - {response.text}")

def upload_to_gcs(data, filename):
    """Uploads a dictionary as a JSON file to GCS."""
    # Get the path from your .env
    credentials_path = os.getenv("GOOGLE_APPLICATION_CREDENTIALS")
    
    # Initialize the client with the explicit file path
    if credentials_path:
        storage_client = storage.Client.from_service_account_json(credentials_path)
    else:
        # Fallback for when you move to the cloud (Kestra/GCP)
        storage_client = storage.Client()
        
    bucket_name = os.getenv("GCS_BUCKET_NAME")
    bucket = storage_client.bucket(bucket_name)
    blob = bucket.blob(filename)

    blob.upload_from_string(
        data=json.dumps(data),
        content_type='application/json'
    )
    print(f"Successfully uploaded to gs://{BUCKET_NAME}/filename")

if __name__ == "__main__":
    # 1. Fetch data    
    BR_COUNTRY_ID = 28
    raw_data = fetch_openaq_data(country_code=BR_COUNTRY_ID)
    
    # 2. Create a unique filename with a timestamp
    timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
    filename = f"raw/openaq_br_{timestamp}.json"
    
    # 3. Upload to GCS
    upload_to_gcs(raw_data, filename)