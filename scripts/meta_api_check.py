from __future__ import annotations

import argparse
import json
from pathlib import Path

import requests


GRAPH_VERSION = "v24.0"


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Validate Meta token and discover Pages/Instagram accounts.")
    parser.add_argument("--token", required=True, help="Path to token JSON from meta_oauth.py.")
    parser.add_argument("--save-config", default="", help="Optional path to write selected Page/IG config JSON.")
    parser.add_argument("--page-id", default="", help="Optional preferred Page ID.")
    return parser


def graph_get(path: str, access_token: str, **params: str) -> dict:
    response = requests.get(
        f"https://graph.facebook.com/{GRAPH_VERSION}/{path}",
        params={"access_token": access_token, **params},
        timeout=60,
    )
    try:
        payload = response.json()
    except ValueError:
        payload = {"raw": response.text}
    if response.status_code >= 400:
        message = payload.get("error", {}).get("message", response.text)
        raise SystemExit(f"Meta API failed: {message}")
    return payload


def main() -> None:
    args = build_parser().parse_args()
    token_path = Path(args.token)
    if not token_path.exists():
        raise SystemExit(f"Token not found: {token_path}")

    user_token = json.loads(token_path.read_text(encoding="utf-8"))["access_token"]
    me = graph_get("me", user_token, fields="id,name")
    pages = graph_get(
        "me/accounts",
        user_token,
        fields="id,name,access_token,instagram_business_account{id,username,name}",
        limit="100",
    ).get("data", [])
    if not pages:
        raise SystemExit("No Facebook Pages returned. Re-run OAuth and select the Page in the consent dialog.")

    selected = None
    for page in pages:
        ig = page.get("instagram_business_account") or {}
        suffix = f" ig=@{ig.get('username')} ({ig.get('id')})" if ig else " ig=not_connected"
        print(f"PAGE {page.get('name')} ({page.get('id')}){suffix}")
        if args.page_id and page.get("id") == args.page_id:
            selected = page
    selected = selected or pages[0]

    if args.save_config:
        config_path = Path(args.save_config)
        config_path.parent.mkdir(parents=True, exist_ok=True)
        config = {
            "graph_version": GRAPH_VERSION,
            "user_id": me.get("id"),
            "user_name": me.get("name"),
            "page_id": selected.get("id"),
            "page_name": selected.get("name"),
            "page_access_token": selected.get("access_token"),
            "instagram_business_account": selected.get("instagram_business_account"),
        }
        config_path.write_text(json.dumps(config, indent=2), encoding="utf-8")
        print(f"CONFIG_SAVED={config_path}")

    print("Meta API token OK")


if __name__ == "__main__":
    main()
