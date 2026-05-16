from __future__ import annotations

import argparse
import subprocess
from pathlib import Path


def run_burn(project_root: Path, reel_root: Path) -> None:
    ffmpeg = (
        project_root
        / "tools"
        / "ffmpeg"
        / "ffmpeg-8.1.1-essentials_build"
        / "bin"
        / "ffmpeg.exe"
    )
    voiced = reel_root / "final" / "scenes_stitched_voiced.mp4"
    ass = reel_root / "captions" / "captions.ass"
    output = reel_root / "final" / "final_captioned.mp4"
    if not voiced.exists():
        raise FileNotFoundError(f"Missing voiced video: {voiced}")
    if not ass.exists():
        raise FileNotFoundError(f"Missing ASS captions: {ass}")
    ass_filter = str(ass).replace("\\", "/").replace(":", "\\:")
    subprocess.run(
        [str(ffmpeg), "-i", str(voiced), "-vf", f"ass='{ass_filter}'", "-c:a", "copy", str(output)],
        check=True,
    )
    print(f"Captioned video: {output}")


def run_watermark(project_root: Path, reel_root: Path, logo_path: Path | None = None) -> None:
    watermark_script = project_root / "scripts" / "add_logicloom_watermark.ps1"
    input_video = reel_root / "final" / "final_captioned.mp4"
    output_video = reel_root / "final" / "final_captioned_branded.mp4"
    logo = logo_path or (project_root / "assets" / "branding" / "logos" / "logo_rounded_more.png")
    subprocess.run(
        [
            "powershell",
            "-ExecutionPolicy",
            "Bypass",
            "-File",
            str(watermark_script),
            "-InputVideo",
            str(input_video),
            "-OutputVideo",
            str(output_video),
            "-LogoPath",
            str(logo),
            "-SkipValidation",
        ],
        check=True,
    )
    print(f"Branded video: {output_video}")


def main() -> None:
    parser = argparse.ArgumentParser(description="Reel step 6 finalize pipeline")
    parser.add_argument("--action", choices=["burn", "watermark", "print"], required=True)
    parser.add_argument("--project-root", required=True)
    parser.add_argument("--reel-root", required=True)
    parser.add_argument("--logo-path", required=False, default="")
    args = parser.parse_args()

    project_root = Path(args.project_root)
    reel_root = Path(args.reel_root)
    final_output = reel_root / "final" / "final_captioned_branded.mp4"

    if args.action == "burn":
        run_burn(project_root, reel_root)
    elif args.action == "watermark":
        run_watermark(project_root, reel_root, Path(args.logo_path) if args.logo_path else None)
    else:
        print("=====================================")
        print("FINAL VIDEO CREATED SUCCESSFULLY")
        print(str(final_output))
        print("=====================================")


if __name__ == "__main__":
    main()
