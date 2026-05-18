from __future__ import annotations

import argparse
import subprocess
from pathlib import Path


def sort_key(p: Path) -> int:
    head = p.stem.split("_")[0]
    return int(head) if head.isdigit() else 10**9


def build_paths(project_root: Path, reel_root: Path, source: Path) -> dict[str, Path]:
    final_dir = reel_root / "final"
    voice_dir = reel_root / "voice"
    ffmpeg = (
        project_root
        / "tools"
        / "ffmpeg"
        / "ffmpeg-8.1.1-essentials_build"
        / "bin"
        / "ffmpeg.exe"
    )
    return {
        "final_dir": final_dir,
        "voice_dir": voice_dir,
        "ffmpeg": ffmpeg,
        "concat": source / "concat.txt",
        "stitched": final_dir / "scenes_stitched.mp4",
        "audio": voice_dir / "voice_v1.mp3",
        "voiced": final_dir / "scenes_stitched_voiced.mp4",
        "voiced_with_music": final_dir / "scenes_stitched_voiced_with_music.mp4",
        "source": source,
    }


def run_concat(paths: dict[str, Path]) -> None:
    source = paths["source"]
    clips = sorted(source.glob("*.mp4"), key=sort_key)
    if not clips:
        raise RuntimeError(f"No .mp4 clips found in {source}")
    lines = [f"file '{str(p).replace(chr(92), '/')}'\n" for p in clips]
    paths["concat"].write_text("".join(lines), encoding="utf-8")
    print(f"Concat file: {paths['concat']}")
    print(f"Clips: {len(clips)}")


def run_stitch(paths: dict[str, Path]) -> None:
    paths["final_dir"].mkdir(parents=True, exist_ok=True)
    cmd = [
        str(paths["ffmpeg"]),
        "-f",
        "concat",
        "-safe",
        "0",
        "-i",
        str(paths["concat"]),
        "-c",
        "copy",
        str(paths["stitched"]),
    ]
    subprocess.run(cmd, check=True)
    print(f"Stitched video: {paths['stitched']}")


def run_mux(paths: dict[str, Path]) -> None:
    if not paths["stitched"].exists():
        raise FileNotFoundError(f"Missing stitched video: {paths['stitched']}")
    if not paths["audio"].exists():
        raise FileNotFoundError(f"Missing voice file: {paths['audio']}")
    cmd = [
        str(paths["ffmpeg"]),
        "-y",
        "-i",
        str(paths["stitched"]),
        "-i",
        str(paths["audio"]),
        "-c:v",
        "copy",
        "-c:a",
        "aac",
        "-map",
        "0:v:0",
        "-map",
        "1:a:0",
        "-shortest",
        str(paths["voiced"]),
    ]
    subprocess.run(cmd, check=True)
    print(f"Voiced video: {paths['voiced']}")

    # Second variant keeps source clip music/sound under the narration.
    cmd_with_music = [
        str(paths["ffmpeg"]),
        "-y",
        "-i",
        str(paths["stitched"]),
        "-i",
        str(paths["audio"]),
        "-filter_complex",
        "[0:a]volume=0.35[bg];[1:a]volume=1.0[voice];[bg][voice]amix=inputs=2:duration=first:dropout_transition=2[aout]",
        "-map",
        "0:v:0",
        "-map",
        "[aout]",
        "-c:v",
        "copy",
        "-c:a",
        "aac",
        "-shortest",
        str(paths["voiced_with_music"]),
    ]
    subprocess.run(cmd_with_music, check=True)
    print(f"Voiced + music video: {paths['voiced_with_music']}")


def main() -> None:
    parser = argparse.ArgumentParser(description="Reel step 4 video pipeline")
    parser.add_argument("--action", choices=["concat", "stitch", "mux"], required=True)
    parser.add_argument("--project-root", required=True)
    parser.add_argument("--reel-root", required=True)
    parser.add_argument("--source", required=True)
    args = parser.parse_args()

    paths = build_paths(Path(args.project_root), Path(args.reel_root), Path(args.source))
    if args.action == "concat":
        run_concat(paths)
    elif args.action == "stitch":
        run_stitch(paths)
    else:
        run_mux(paths)


if __name__ == "__main__":
    main()
