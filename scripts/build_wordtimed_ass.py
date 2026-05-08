from __future__ import annotations

import argparse
import json
import re
from dataclasses import dataclass
from pathlib import Path


@dataclass
class WordTs:
    word: str
    start: float
    end: float


def norm_word(w: str) -> str:
    return re.sub(r"[^a-z0-9]+", "", w.lower())


def parse_srt_time(ts: str) -> float:
    hh, mm, rest = ts.split(":")
    ss, ms = rest.split(",")
    return int(hh) * 3600 + int(mm) * 60 + int(ss) + int(ms) / 1000


def to_ass_time(seconds: float) -> str:
    seconds = max(0.0, seconds)
    h = int(seconds // 3600)
    seconds -= h * 3600
    m = int(seconds // 60)
    seconds -= m * 60
    s = int(seconds)
    cs = int(round((seconds - s) * 100))
    if cs == 100:
        s += 1
        cs = 0
    if s == 60:
        m += 1
        s = 0
    if m == 60:
        h += 1
        m = 0
    return f"{h}:{m:02d}:{s:02d}.{cs:02d}"


def parse_srt_blocks(text: str) -> list[tuple[float, float, str]]:
    blocks = re.split(r"\r?\n\r?\n", text.strip())
    out: list[tuple[float, float, str]] = []
    for block in blocks:
        lines = [ln.strip() for ln in block.splitlines() if ln.strip()]
        if len(lines) < 3 or "-->" not in lines[1]:
            continue
        start_s, end_s = [x.strip() for x in lines[1].split("-->")]
        out.append((parse_srt_time(start_s), parse_srt_time(end_s), " ".join(lines[2:])))
    return out


def tokenize_caption(text: str) -> list[str]:
    return re.findall(r"\S+", text)


def wrap_two_lines(words: list[str], max_chars: int = 16) -> tuple[list[str], int]:
    if not words:
        return words, -1
    total = len(" ".join(words))
    if total <= max_chars:
        return words, -1
    best_i, best_delta = 1, 10**9
    for i in range(1, len(words)):
        left = len(" ".join(words[:i]))
        right = len(" ".join(words[i:]))
        if left > max_chars or right > max_chars:
            continue
        delta = abs(left - right)
        if delta < best_delta:
            best_i, best_delta = i, delta
    return words, best_i


def load_word_ts(path: Path) -> list[WordTs]:
    # Windows PowerShell `Set-Content -Encoding UTF8` commonly writes a UTF-8 BOM.
    # Accept both BOM and non-BOM UTF-8 for smoother local automation.
    raw = json.loads(path.read_text(encoding="utf-8-sig"))
    out: list[WordTs] = []
    for item in raw:
        w = str(item.get("word", "")).strip()
        s = float(item.get("start", 0.0))
        e = float(item.get("end", s + 0.12))
        if w:
            out.append(WordTs(w, s, e))
    return out


def find_window_words(word_ts: list[WordTs], start: float, end: float) -> list[WordTs]:
    eps = 0.18
    return [w for w in word_ts if (w.end >= start - eps and w.start <= end + eps)]


def match_caption_to_timestamps(caption_words: list[str], candidates: list[WordTs], fallback_start: float, fallback_end: float) -> list[tuple[float, float]]:
    if not [norm_word(w) for w in caption_words if norm_word(w)]:
        return []
    cand_norm = [norm_word(c.word) for c in candidates]
    times: list[tuple[float, float]] = []
    idx = 0
    for cw_raw in caption_words:
        cw = norm_word(cw_raw)
        if not cw:
            continue
        found = None
        for j in range(idx, len(candidates)):
            if cand_norm[j] == cw:
                found = j
                break
        if found is None:
            if idx < len(candidates):
                t = candidates[idx]
                times.append((t.start, t.end))
                idx += 1
            else:
                n = max(1, len(caption_words))
                step = max(0.08, (fallback_end - fallback_start) / n)
                k = len(times)
                ws = fallback_start + k * step
                times.append((ws, min(fallback_end, ws + step)))
            continue
        t = candidates[found]
        times.append((t.start, t.end))
        idx = found + 1
    fixed: list[tuple[float, float]] = []
    prev_end = fallback_start
    for s, e in times:
        s = max(s, prev_end)
        e = max(e, s + 0.06)
        fixed.append((s, e))
        prev_end = e
    return fixed


def build_ass(events: list[tuple[float, float, str]], word_ts: list[WordTs], max_chars: int, preset: str, chunk_size: int) -> str:
    if preset == "ytshort":
        # Reference-matching style (your provided screenshots):
        # heavy caps, thick black stroke, subtle shadow, active word in neon green.
        base_style = "Style: Base,Impact,84,&H00FFFFFF,&H00FFFFFF,&H00000000,&H80000000,-1,0,0,0,100,100,0,0,1,8.0,2.2,2,58,58,84,1"
        # Keep Active style white; we color only the active word via overrides.
        active_style = "Style: Active,Impact,84,&H00FFFFFF,&H00FFFFFF,&H00000000,&H80000000,-1,0,0,0,100,100,0,0,1,8.0,2.2,2,58,58,84,1"
    elif preset == "ytshort_legacy":
        # Previous shorts preset (kept for backward-compat comparisons).
        base_style = "Style: Base,Comic Sans MS,68,&H00FFFFFF,&H00FFFFFF,&H00000000,&H00000000,-1,0,0,0,100,100,0,0,1,7.0,0,2,54,54,78,1"
        active_style = "Style: Active,Comic Sans MS,68,&H00FFFFFF,&H00FFFFFF,&H00000000,&H00000000,-1,0,0,0,100,100,0,0,1,7.0,0,2,54,54,78,1"
    elif preset == "logicloom_ref":
        # Reference-matching style: heavy caps, thick black stroke, subtle shadow,
        # and active word in neon green.
        # ASS colors are &HAABBGGRR.
        base_style = "Style: Base,Impact,84,&H00FFFFFF,&H00FFFFFF,&H00000000,&H80000000,-1,0,0,0,100,100,0,0,1,8.0,2.2,2,58,58,84,1"
        # Slightly yellow-leaning neon green (closer to the reference).
        active_style = "Style: Active,Impact,84,&H00FFFFFF,&H00FFFFFF,&H00000000,&H80000000,-1,0,0,0,100,100,0,0,1,8.0,2.2,2,58,58,84,1"
    else:
        base_style = "Style: Base,Arial,42,&H00F4F4F4,&H00F4F4F4,&H00111111,&H50000000,-1,0,0,0,100,100,0,0,1,3,0,2,140,140,340,1"
        active_style = "Style: Active,Arial,42,&H00F4F4F4,&H00F4F4F4,&H00111111,&H00000000,-1,0,0,0,100,100,0,0,1,3,0,2,140,140,340,1"

    header = f"""[Script Info]
Title: Reel Word-Timed Captions
ScriptType: v4.00+
WrapStyle: 2
ScaledBorderAndShadow: yes
PlayResX: 1080
PlayResY: 1920

[V4+ Styles]
Format: Name, Fontname, Fontsize, PrimaryColour, SecondaryColour, OutlineColour, BackColour, Bold, Italic, Underline, StrikeOut, ScaleX, ScaleY, Spacing, Angle, BorderStyle, Outline, Shadow, Alignment, MarginL, MarginR, MarginV, Encoding
{base_style}
{active_style}

[Events]
Format: Layer, Start, End, Style, Name, MarginL, MarginR, MarginV, Effect, Text
"""
    lines = [header]
    for s0, e0, caption in events:
        words = tokenize_caption(caption)
        if not words:
            continue
        if preset in ("ytshort", "ytshort_legacy", "logicloom_ref"):
            words = [w.upper() for w in words]
        words, split_at = wrap_two_lines(words, max_chars=max_chars)
        candidates = find_window_words(word_ts, s0, e0)
        per_word_times = match_caption_to_timestamps(words, candidates, s0, e0)
        if len(per_word_times) != len(words):
            step = max(0.08, (e0 - s0) / max(1, len(words)))
            per_word_times = [(s0 + i * step, s0 + (i + 1) * step) for i in range(len(words))]
            per_word_times[-1] = (per_word_times[-1][0], e0)

        first_start, last_end = per_word_times[0][0], per_word_times[-1][1]
        base_words = [w.replace("{", "").replace("}", "") for w in words]
        if preset in ("ytshort", "ytshort_legacy", "logicloom_ref"):
            i = 0
            while i < len(base_words):
                j = min(len(base_words), i + max(1, chunk_size))
                chunk_words = base_words[i:j]
                chunk_start = per_word_times[i][0]
                chunk_end = per_word_times[j - 1][1]
                lines.append(f"Dialogue: 0,{to_ass_time(chunk_start)},{to_ass_time(chunk_end)},Base,,0,0,78,,{' '.join(chunk_words)}")
                for k in range(i, j):
                    ws, we = per_word_times[k]
                    rendered = []
                    for p, w in enumerate(chunk_words):
                        if i + p == k:
                            if preset in ("ytshort", "logicloom_ref"):
                                # Reset explicitly to Base so the rest of the line stays white.
                                rendered.append(r"{\1c&H0000FF92&\3c&H00000000&\bord8\shad2\b1}" + w + r"{\rBase}")
                            else:
                                rendered.append(r"{\1c&H0000FFFF&\3c&H00000000&\bord6.6\b1}" + w + r"{\r}")
                        else:
                            rendered.append(w)
                    lines.append(f"Dialogue: 1,{to_ass_time(ws)},{to_ass_time(we)},Active,,0,0,78,,{' '.join(rendered)}")
                i = j
        else:
            base_text = " ".join(base_words[:split_at]) + r"\N" + " ".join(base_words[split_at:]) if split_at != -1 else " ".join(base_words)
            lines.append(f"Dialogue: 0,{to_ass_time(first_start)},{to_ass_time(last_end)},Base,,0,0,340,,{base_text}")
            for i, (ws, we) in enumerate(per_word_times):
                rendered = []
                for j, w in enumerate(base_words):
                    if i == j:
                        rendered.append(r"{\1c&H0000FFFF&\3c&H00000000&\bord5\shad1\b1}" + w + r"{\r}")
                    else:
                        rendered.append(w)
                active_text = " ".join(rendered[:split_at]) + r"\N" + " ".join(rendered[split_at:]) if split_at != -1 else " ".join(rendered)
                lines.append(f"Dialogue: 1,{to_ass_time(ws)},{to_ass_time(we)},Active,,0,0,340,,{active_text}")
    return "\n".join(lines) + "\n"


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Build word-timed ASS captions with active-word highlight.")
    parser.add_argument("--srt", required=True, help="Absolute path to source SRT.")
    parser.add_argument("--words", required=True, help="Absolute path to word_timestamps JSON.")
    parser.add_argument("--out", required=True, help="Absolute path to output ASS file.")
    parser.add_argument("--max-chars", type=int, default=16, help="Max chars per caption line before split.")
    parser.add_argument("--preset", choices=["default", "ytshort", "ytshort_legacy", "logicloom_ref"], default="default", help="Caption style preset.")
    parser.add_argument("--chunk-size", type=int, default=3, help="Words per chunk for ytshort preset.")
    return parser


def main() -> None:
    args = build_parser().parse_args()
    srt_path = Path(args.srt)
    words_path = Path(args.words)
    out_path = Path(args.out)
    out_path.parent.mkdir(parents=True, exist_ok=True)

    events = parse_srt_blocks(srt_path.read_text(encoding="utf-8-sig"))
    word_ts = load_word_ts(words_path)
    ass = build_ass(events, word_ts, max_chars=args.max_chars, preset=args.preset, chunk_size=args.chunk_size)
    out_path.write_text(ass, encoding="utf-8")
    print(str(out_path))


if __name__ == "__main__":
    main()
