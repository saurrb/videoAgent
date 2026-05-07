from __future__ import annotations

import argparse
import json
import time
from pathlib import Path

import requests


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Publish an Instagram Reel through Meta Graph API.")
    parser.add_argument("--config", required=True, help="Path to meta_config.json from meta_api_check.py.")
    parser.add_argument("--video-url", required=True, help="Public HTTPS URL to the MP4 file.")
    parser.add_argument("--caption", default="")
    parser.add_argument("--share-to-feed", action="store_true")
    parser.add_argument("--timeout-seconds", type=int, default=600)
    return parser


def graph_post(version: str, path: str, **data: str | bool) -> dict:
    response = requests.post(f"https://graph.facebook.com/{version}/{path}", data=data, timeout=120)
    payload = response.json()
    if response.status_code >= 400:
        message = payload.get("error", {}).get("message", response.text)
        raise SystemExit(f"Meta API failed: {message}")
    return payload


def graph_get(version: str, path: str, access_token: str, **params: str) -> dict:
    response = requests.get(
        f"https://graph.facebook.com/{version}/{path}",
        params={"access_token": access_token, **params},
        timeout=60,
    )
    payload = response.json()
    if response.status_code >= 400:
        message = payload.get("error", {}).get("message", response.text)
        raise SystemExit(f"Meta API failed: {message}")
    return payload


def main() -> None:
    args = build_parser().parse_args()
    config = json.loads(Path(args.config).read_text(encoding="utf-8"))
    version = config.get("graph_version", "v24.0")
    ig = config.get("instagram_business_account") or {}
    ig_user_id = ig.get("id")
    access_token = config.get("page_access_token")
    if not ig_user_id:
        raise SystemExit("Config has no instagram_business_account.id. Connect Instagram to the Facebook Page.")
    if not access_token:
        raise SystemExit("Config has no page_access_token. Re-run meta_api_check.py.")

    container = graph_post(
        version,
        f"{ig_user_id}/media",
        access_token=access_token,
        media_type="REELS",
        video_url=args.video_url,
        caption=args.caption,
        share_to_feed="true" if args.share_to_feed else "false",
    )
    creation_id = container["id"]
    print(f"CONTAINER_ID={creation_id}", flush=True)

    deadline = time.time() + args.timeout_seconds
    status = {}
    while time.time() < deadline:
        status = graph_get(version, creation_id, access_token, fields="status_code,status")
        status_code = status.get("status_code")
        print(f"STATUS={status_code}", flush=True)
        if status_code == "FINISHED":
            break
        if status_code == "ERROR":
            raise SystemExit(f"Container processing failed: {status}")
        time.sleep(10)
    else:
        raise SystemExit(f"Timed out waiting for container processing: {status}")

    published = graph_post(version, f"{ig_user_id}/media_publish", access_token=access_token, creation_id=creation_id)
    print(f"INSTAGRAM_MEDIA_ID={published.get('id')}")


if __name__ == "__main__":
    main()
