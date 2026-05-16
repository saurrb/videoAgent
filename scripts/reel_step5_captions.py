from __future__ import annotations

import argparse
import subprocess
from pathlib import Path


def main() -> None:
    parser = argparse.ArgumentParser(description="Reel step 5 caption pipeline")
    parser.add_argument("--project-root", required=True)
    parser.add_argument("--reel-root", required=True)
    parser.add_argument("--preset", default="logicloom_ref")
    args = parser.parse_args()

    project_root = Path(args.project_root)
    reel_root = Path(args.reel_root)
    captions_dir = reel_root / "captions"
    voice_file = reel_root / "voice" / "voice_v1.mp3"
    words = captions_dir / "word_timestamps.json"
    srt = captions_dir / "captions.srt"
    ass = captions_dir / "captions.ass"

    captions_dir.mkdir(parents=True, exist_ok=True)
    if not voice_file.exists():
        raise FileNotFoundError(f"Missing audio: {voice_file}")

    subprocess.run(
        [
            "python",
            str(project_root / "scripts" / "extract_word_timestamps.py"),
            "--audio",
            str(voice_file),
            "--out",
            str(words),
        ],
        check=True,
        cwd=str(project_root),
    )
    subprocess.run(
        [
            "python",
            str(project_root / "scripts" / "build_srt_from_words.py"),
            "--words",
            str(words),
            "--out",
            str(srt),
        ],
        check=True,
        cwd=str(project_root),
    )
    subprocess.run(
        [
            "python",
            str(project_root / "scripts" / "build_wordtimed_ass.py"),
            "--srt",
            str(srt),
            "--words",
            str(words),
            "--out",
            str(ass),
            "--preset",
            args.preset,
        ],
        check=True,
        cwd=str(project_root),
    )
    print(f"Words: {words}")
    print(f"SRT:   {srt}")
    print(f"ASS:   {ass}")


if __name__ == "__main__":
    main()

