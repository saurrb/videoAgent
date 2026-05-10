from __future__ import annotations

import argparse
from pathlib import Path
from wsgiref.simple_server import make_server

from google_auth_oauthlib.flow import InstalledAppFlow
from google.oauth2.credentials import Credentials


SCOPES = ["https://www.googleapis.com/auth/youtube.upload"]


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="YouTube OAuth flow for BrowserOS-driven approval.")
    parser.add_argument("--client-secrets", required=True)
    parser.add_argument("--token-out", required=True)
    parser.add_argument("--port", type=int, default=8765)
    return parser


def main() -> None:
    args = build_parser().parse_args()
    token_out = Path(args.token_out)
    token_out.parent.mkdir(parents=True, exist_ok=True)

    flow = InstalledAppFlow.from_client_secrets_file(args.client_secrets, SCOPES)
    flow.redirect_uri = f"http://localhost:{args.port}/"
    auth_url, _ = flow.authorization_url(
        access_type="offline",
        include_granted_scopes="true",
        prompt="consent select_account",
    )
    print(f"AUTH_URL={auth_url}", flush=True)

    captured = {"uri": None}

    def app(environ, start_response):
        captured["uri"] = f"http://localhost:{args.port}{environ.get('RAW_URI') or environ.get('REQUEST_URI') or '/'}"
        body = b"Authorization received. You can close this tab."
        start_response("200 OK", [("Content-Type", "text/plain"), ("Content-Length", str(len(body)))])
        return [body]

    with make_server("localhost", args.port, app) as httpd:
        while captured["uri"] is None:
            httpd.handle_request()

    flow.fetch_token(authorization_response=captured["uri"])
    creds: Credentials = flow.credentials
    token_out.write_text(creds.to_json(), encoding="utf-8")
    print(f"TOKEN_SAVED={token_out}", flush=True)


if __name__ == "__main__":
    main()
