from __future__ import annotations

import argparse
import json
from pathlib import Path


def fmt_srt_time(sec: float) -> str:
    ms = max(0, int(round(sec * 1000)))
    h = ms // 3600000
    ms -= h * 3600000
    m = ms // 60000
    ms -= m * 60000
    s = ms // 1000
    ms -= s * 1000
    return f"{h:02}:{m:02}:{s:02},{ms:03}"


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--words", required=True)
    ap.add_argument("--out", required=True)
    ap.add_argument("--chunk-size", type=int, default=3)
    ap.add_argument("--gap-threshold", type=float, default=0.45)
    args = ap.parse_args()

    words_path = Path(args.words)
    out_path = Path(args.out)
    out_path.parent.mkdir(parents=True, exist_ok=True)

    words = json.loads(words_path.read_text(encoding="utf-8"))
    words = [w for w in words if w.get("word")]

    chunks: list[list[dict]] = []
    cur: list[dict] = []
    for w in words:
        if cur:
            gap = float(w["start"]) - float(cur[-1]["end"])
            if gap > args.gap_threshold or len(cur) >= args.chunk_size:
                chunks.append(cur)
                cur = []
        cur.append(w)
    if cur:
        chunks.append(cur)

    lines = []
    idx = 1
    for c in chunks:
        start = float(c[0]["start"])
        end = float(c[-1]["end"])
        text = " ".join((x["word"] or "").strip() for x in c).strip()
        if not text:
            continue
        lines.append(str(idx))
        lines.append(f"{fmt_srt_time(start)} --> {fmt_srt_time(end)}")
        lines.append(text)
        lines.append("")
        idx += 1

    out_path.write_text("\n".join(lines), encoding="utf-8")
    print(str(out_path))


if __name__ == "__main__":
    main()
