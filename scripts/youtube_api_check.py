from __future__ import annotations

import argparse
import json
from pathlib import Path

from google.auth.transport.requests import Request
from google.oauth2.credentials import Credentials


REQUIRED_SCOPE = "https://www.googleapis.com/auth/youtube.upload"


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Validate YouTube upload OAuth token without uploading.")
    parser.add_argument("--token", required=True, help="Path to token JSON from OAuth flow.")
    return parser


def main() -> None:
    args = build_parser().parse_args()
    token_path = Path(args.token)
    if not token_path.exists():
        raise SystemExit(f"Token not found: {token_path}")

    creds = Credentials.from_authorized_user_info(json.loads(token_path.read_text(encoding="utf-8")))
    scopes = set(creds.scopes or [])
    if REQUIRED_SCOPE not in scopes:
        raise SystemExit(f"Token missing required scope: {REQUIRED_SCOPE}")
    if not creds.refresh_token:
        raise SystemExit("Token has no refresh_token. Re-run OAuth with access_type=offline.")

    refreshed = False
    if creds.expired:
        creds.refresh(Request())
        token_path.write_text(creds.to_json(), encoding="utf-8")
        refreshed = True

    print("YouTube API token OK")
    print(f"refreshed={str(refreshed).lower()}")
    print(f"expiry={creds.expiry.isoformat() if creds.expiry else 'unknown'}")


if __name__ == "__main__":
    main()
