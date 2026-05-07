from __future__ import annotations

import argparse
import json
from pathlib import Path

from google.oauth2.credentials import Credentials
from google.auth.transport.requests import Request
from googleapiclient.errors import HttpError
from googleapiclient.discovery import build
from googleapiclient.http import MediaFileUpload


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Upload a video to YouTube with Data API v3.")
    parser.add_argument("--token", required=True, help="Absolute path to token JSON from OAuth flow.")
    parser.add_argument("--video", required=True, help="Absolute path to video file.")
    parser.add_argument("--title", required=True, help="Video title.")
    parser.add_argument("--description", default="", help="Video description.")
    parser.add_argument("--tags", default="", help="Comma-separated tags.")
    parser.add_argument("--category-id", default="22", help="YouTube category ID. Default 22 (People & Blogs).")
    parser.add_argument("--privacy", default="private", choices=["private", "unlisted", "public"])
    return parser


def main() -> None:
    args = build_parser().parse_args()
    token_path = Path(args.token)
    video_path = Path(args.video)
    creds = Credentials.from_authorized_user_info(json.loads(token_path.read_text(encoding="utf-8")))

    if creds.expired and creds.refresh_token:
        creds.refresh(Request())
        token_path.write_text(creds.to_json(), encoding="utf-8")

    youtube = build("youtube", "v3", credentials=creds)

    tags = [t.strip() for t in args.tags.split(",") if t.strip()]
    body = {
        "snippet": {
            "title": args.title,
            "description": args.description,
            "tags": tags,
            "categoryId": args.category_id,
        },
        "status": {"privacyStatus": args.privacy},
    }
    media = MediaFileUpload(str(video_path), chunksize=-1, resumable=True)
    request = youtube.videos().insert(part="snippet,status", body=body, media_body=media)

    response = None
    try:
        while response is None:
            _, response = request.next_chunk()
    except HttpError as exc:
        try:
            payload = json.loads(exc.content.decode("utf-8"))
            message = payload.get("error", {}).get("message", exc.reason)
            reasons = [
                item.get("reason")
                for item in payload.get("error", {}).get("errors", [])
                if item.get("reason")
            ]
            detail = f"{message}"
            if reasons:
                detail += f" (reason: {', '.join(reasons)})"
            raise SystemExit(f"YouTube API upload failed: {detail}") from exc
        except (json.JSONDecodeError, UnicodeDecodeError, AttributeError):
            raise SystemExit(f"YouTube API upload failed: {exc}") from exc

    video_id = response["id"]
    print(f"https://www.youtube.com/watch?v={video_id}")


if __name__ == "__main__":
    main()
