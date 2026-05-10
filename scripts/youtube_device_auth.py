from __future__ import annotations

import argparse
import json
import time
from pathlib import Path

import requests


DEVICE_CODE_URL = "https://oauth2.googleapis.com/device/code"
TOKEN_URL = "https://oauth2.googleapis.com/token"
SCOPE = "https://www.googleapis.com/auth/youtube.upload"


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="YouTube OAuth device flow (BrowserOS-friendly).")
    parser.add_argument("--client-secrets", required=True, help="Path to OAuth client secret JSON.")
    parser.add_argument("--token-out", required=True, help="Path to write token JSON.")
    return parser


def main() -> None:
    args = build_parser().parse_args()
    secrets = json.loads(Path(args.client_secrets).read_text(encoding="utf-8"))
    installed = secrets.get("installed", {})
    client_id = installed["client_id"]
    client_secret = installed["client_secret"]

    dc_resp = requests.post(
        DEVICE_CODE_URL,
        data={"client_id": client_id, "scope": SCOPE},
        timeout=30,
    )
    dc_resp.raise_for_status()
    dc = dc_resp.json()

    print(f"VERIFY_URL={dc['verification_url']}")
    print(f"USER_CODE={dc['user_code']}")
    print(f"EXPIRES_IN={dc['expires_in']}")
    print(f"INTERVAL={dc['interval']}")

    interval = int(dc.get("interval", 5))
    deadline = time.time() + int(dc["expires_in"])

    while time.time() < deadline:
        tr = requests.post(
            TOKEN_URL,
            data={
                "client_id": client_id,
                "client_secret": client_secret,
                "device_code": dc["device_code"],
                "grant_type": "urn:ietf:params:oauth:grant-type:device_code",
            },
            timeout=30,
        )
        if tr.status_code == 200:
            token = tr.json()
            out = Path(args.token_out)
            out.parent.mkdir(parents=True, exist_ok=True)
            out.write_text(json.dumps(token, indent=2), encoding="utf-8")
            print(str(out))
            return

        body = tr.json()
        err = body.get("error")
        if err == "authorization_pending":
            time.sleep(interval)
            continue
        if err == "slow_down":
            interval += 5
            time.sleep(interval)
            continue
        raise RuntimeError(f"Device auth failed: {body}")

    raise TimeoutError("Timed out waiting for device authorization.")


if __name__ == "__main__":
    main()
