from __future__ import annotations

import argparse
from pathlib import Path

from google_auth_oauthlib.flow import InstalledAppFlow
from google.oauth2.credentials import Credentials


SCOPES = ["https://www.googleapis.com/auth/youtube.upload"]


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Run YouTube OAuth and save token.json for uploads.")
    parser.add_argument(
        "--client-secrets",
        required=True,
        help="Absolute path to OAuth client secret JSON downloaded from Google Cloud.",
    )
    parser.add_argument(
        "--token-out",
        required=True,
        help="Absolute path to write token JSON (e.g., secrets/youtube_token.json).",
    )
    return parser


def main() -> None:
    args = build_parser().parse_args()
    client_secrets = Path(args.client_secrets)
    token_out = Path(args.token_out)
    token_out.parent.mkdir(parents=True, exist_ok=True)

    flow = InstalledAppFlow.from_client_secrets_file(str(client_secrets), SCOPES)
    creds: Credentials = flow.run_local_server(
        port=0,
        open_browser=False,
        authorization_prompt_message="Please visit this URL to authorize this application: {url}",
        prompt="consent select_account",
        access_type="offline",
        include_granted_scopes="true",
    )
    token_out.write_text(creds.to_json(), encoding="utf-8")
    print(str(token_out))


if __name__ == "__main__":
    main()
