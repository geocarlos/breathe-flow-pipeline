import os
import sys
from google.cloud import secretmanager

def main():
    secret_name = os.environ.get("OPENAQ_SECRET_NAME", "openaq-api-key")
    project = os.environ.get("GCP_PROJECT_ID")
    if not project:
        print("GCP_PROJECT_ID not set", file=sys.stderr)
        sys.exit(2)

    client = secretmanager.SecretManagerServiceClient()
    name = f"projects/{project}/secrets/{secret_name}/versions/latest"
    response = client.access_secret_version(request={"name": name})
    payload = response.payload.data.decode("UTF-8")
    print(payload)

if __name__ == '__main__':
    main()
