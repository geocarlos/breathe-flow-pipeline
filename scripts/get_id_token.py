import os
import sys
from google.auth.transport.requests import Request
from google.oauth2 import service_account

def main():
    if len(sys.argv) < 2:
        print("Usage: get_id_token.py <audience>", file=sys.stderr)
        sys.exit(2)
    audience = sys.argv[1]
    key_path = os.environ.get("GOOGLE_APPLICATION_CREDENTIALS")
    if not key_path:
        print("GOOGLE_APPLICATION_CREDENTIALS not set", file=sys.stderr)
        sys.exit(2)

    creds = service_account.IDTokenCredentials.from_service_account_file(key_path, target_audience=audience)
    creds.refresh(Request())
    print(creds.token)

if __name__ == '__main__':
    main()
