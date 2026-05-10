from __future__ import annotations

import argparse
import json
import time
from pathlib import Path
from typing import Any

import requests


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Publish local MP4 reels to Facebook Page and Instagram via Meta Graph API.")
    parser.add_argument("--config", required=True, help="Path to meta_config.json from meta_api_check.py.")
    parser.add_argument("--video", required=True, help="Local MP4 path.")
    parser.add_argument("--caption", default="")
    parser.add_argument("--platforms", default="facebook,instagram", help="Comma-separated: facebook,instagram")
    parser.add_argument("--share-to-feed", action="store_true")
    parser.add_argument("--timeout-seconds", type=int, default=900)
    return parser


def graph_url(version: str, path: str, video: bool = False) -> str:
    host = "graph-video.facebook.com" if video else "graph.facebook.com"
    return f"https://{host}/{version}/{path}"


def request_json(method: str, url: str, **kwargs: Any) -> dict[str, Any]:
    response = requests.request(method, url, timeout=180, **kwargs)
    try:
        payload = response.json()
    except ValueError:
        payload = {"raw": response.text}
    if response.status_code >= 400:
        message = payload.get("error", {}).get("message", response.text)
        code = payload.get("error", {}).get("code")
        subcode = payload.get("error", {}).get("error_subcode")
        suffix = f" code={code}" if code else ""
        suffix += f" subcode={subcode}" if subcode else ""
        raise SystemExit(f"Meta API failed: {message}{suffix}")
    return payload


def graph_get(version: str, path: str, access_token: str, **params: str) -> dict[str, Any]:
    return request_json(
        "GET",
        graph_url(version, path),
        params={"access_token": access_token, **params},
    )


def graph_post(version: str, path: str, **data: Any) -> dict[str, Any]:
    return request_json("POST", graph_url(version, path), data=data)


def upload_binary(upload_url: str, access_token: str, video_path: Path, *, instagram: bool) -> None:
    size = video_path.stat().st_size
    headers = {
        "Authorization": f"OAuth {access_token}",
        "offset": "0",
        "file_size": str(size),
    }
    if instagram:
        headers["Content-Type"] = "application/octet-stream"
    with video_path.open("rb") as fh:
        response = requests.post(upload_url, headers=headers, data=fh, timeout=600)
    try:
        payload = response.json()
    except ValueError:
        payload = {"raw": response.text}
    if response.status_code >= 400:
        message = payload.get("error", {}).get("message", response.text)
        raise SystemExit(f"Meta binary upload failed: {message}")


def wait_for_ig_container(version: str, creation_id: str, access_token: str, timeout_seconds: int) -> None:
    deadline = time.time() + timeout_seconds
    last_status: dict[str, Any] = {}
    while time.time() < deadline:
        last_status = graph_get(version, creation_id, access_token, fields="status_code,status")
        status_code = last_status.get("status_code")
        print(f"INSTAGRAM_STATUS={status_code}", flush=True)
        if status_code == "FINISHED":
            return
        if status_code == "ERROR":
            raise SystemExit(f"Instagram container processing failed: {last_status}")
        time.sleep(10)
    raise SystemExit(f"Timed out waiting for Instagram processing: {last_status}")


def wait_for_facebook_video(version: str, video_id: str, access_token: str, timeout_seconds: int) -> None:
    deadline = time.time() + timeout_seconds
    last_status: dict[str, Any] = {}
    while time.time() < deadline:
        last_status = graph_get(version, video_id, access_token, fields="status")
        status = last_status.get("status") or {}
        processing = status.get("processing_phase") or {}
        publishing = status.get("publishing_phase") or {}
        processing_status = processing.get("status")
        publishing_status = publishing.get("status")
        print(f"FACEBOOK_STATUS=processing:{processing_status} publishing:{publishing_status}", flush=True)
        if processing_status in {"complete", "succeeded"} or publishing_status in {"complete", "published"}:
            return
        if processing_status == "error" or publishing_status == "error":
            raise SystemExit(f"Facebook video processing failed: {last_status}")
        time.sleep(10)
    raise SystemExit(f"Timed out waiting for Facebook video processing: {last_status}")


def publish_instagram(config: dict[str, Any], video_path: Path, caption: str, share_to_feed: bool, timeout_seconds: int) -> str:
    version = config.get("graph_version", "v24.0")
    access_token = config.get("page_access_token")
    ig = config.get("instagram_business_account") or {}
    ig_user_id = ig.get("id")
    if not access_token:
        raise SystemExit("Config has no page_access_token.")
    if not ig_user_id:
        raise SystemExit("Config has no instagram_business_account.id.")

    container = graph_post(
        version,
        f"{ig_user_id}/media",
        access_token=access_token,
        media_type="REELS",
        upload_type="resumable",
        caption=caption,
        share_to_feed="true" if share_to_feed else "false",
    )
    creation_id = container["id"]
    upload_url = container.get("uri") or f"https://rupload.facebook.com/ig-api-upload/{version}/{creation_id}"
    print(f"INSTAGRAM_CONTAINER_ID={creation_id}", flush=True)
    upload_binary(upload_url, access_token, video_path, instagram=True)
    wait_for_ig_container(version, creation_id, access_token, timeout_seconds)
    published = graph_post(version, f"{ig_user_id}/media_publish", access_token=access_token, creation_id=creation_id)
    media_id = published.get("id", "")
    print(f"INSTAGRAM_MEDIA_ID={media_id}", flush=True)
    return str(media_id)


def publish_facebook(config: dict[str, Any], video_path: Path, caption: str, timeout_seconds: int) -> str:
    version = config.get("graph_version", "v24.0")
    access_token = config.get("page_access_token")
    page_id = config.get("page_id")
    if not access_token:
        raise SystemExit("Config has no page_access_token.")
    if not page_id:
        raise SystemExit("Config has no page_id.")

    started = graph_post(version, f"{page_id}/video_reels", access_token=access_token, upload_phase="start")
    video_id = started["video_id"]
    upload_url = started["upload_url"]
    print(f"FACEBOOK_VIDEO_ID={video_id}", flush=True)
    upload_binary(upload_url, access_token, video_path, instagram=False)
    # For Facebook Reels, finalize upload first, then poll processing/publishing status.
    finished = graph_post(
        version,
        f"{page_id}/video_reels",
        access_token=access_token,
        upload_phase="finish",
        video_id=video_id,
        description=caption,
    )
    wait_for_facebook_video(version, video_id, access_token, timeout_seconds)
    print(f"FACEBOOK_REEL_RESULT={json.dumps(finished, ensure_ascii=True)}", flush=True)
    return str(video_id)


def main() -> None:
    args = build_parser().parse_args()
    config = json.loads(Path(args.config).read_text(encoding="utf-8"))
    video_path = Path(args.video)
    if not video_path.exists():
        raise SystemExit(f"Video not found: {video_path}")
    platforms = {p.strip().lower() for p in args.platforms.split(",") if p.strip()}
    if not platforms:
        raise SystemExit("No platforms selected.")
    if "facebook" in platforms:
        publish_facebook(config, video_path, args.caption, args.timeout_seconds)
    if "instagram" in platforms:
        publish_instagram(config, video_path, args.caption, args.share_to_feed, args.timeout_seconds)


if __name__ == "__main__":
    main()
