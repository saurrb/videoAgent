from __future__ import annotations

import re
from pathlib import Path


SRC_SRT = Path(
    r"C:\Users\saura\Documents\youtubeVideoAgent\assets\reels\2026-05-06_soft-cute-v2\captions\captions_subsync.srt"
)
OUT_ASS = Path(
    r"C:\Users\saura\Documents\youtubeVideoAgent\assets\reels\2026-05-06_soft-cute-v2\captions\captions_karaoke.ass"
)


def parse_srt_time(ts: str) -> float:
    hh, mm, rest = ts.split(":")
    ss, ms = rest.split(",")
    return int(hh) * 3600 + int(mm) * 60 + int(ss) + int(ms) / 1000


def to_ass_time(seconds: float) -> str:
    if seconds < 0:
        seconds = 0
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
        if len(lines) < 3:
            continue
        timeline = lines[1]
        if "-->" not in timeline:
            continue
        start_s, end_s = [x.strip() for x in timeline.split("-->")]
        start = parse_srt_time(start_s)
        end = parse_srt_time(end_s)
        caption = " ".join(lines[2:])
        out.append((start, end, caption))
    return out


def tokenize_words(text: str) -> list[str]:
    return re.findall(r"\S+", text)


def wrap_two_lines(words: list[str], max_chars: int = 28) -> tuple[list[str], int]:
    if not words:
        return words, -1
    total = len(" ".join(words))
    if total <= max_chars:
        return words, -1
    best_i = 1
    best_delta = 10**9
    for i in range(1, len(words)):
        left = len(" ".join(words[:i]))
        right = len(" ".join(words[i:]))
        if left > max_chars or right > max_chars:
            continue
        delta = abs(left - right)
        if delta < best_delta:
            best_delta = delta
            best_i = i
    return words, best_i


def build_ass(events: list[tuple[float, float, str]]) -> str:
    header = """[Script Info]
Title: Reel Karaoke Captions
ScriptType: v4.00+
WrapStyle: 2
ScaledBorderAndShadow: yes
PlayResX: 1080
PlayResY: 1920

[V4+ Styles]
Format: Name, Fontname, Fontsize, PrimaryColour, SecondaryColour, OutlineColour, BackColour, Bold, Italic, Underline, StrikeOut, ScaleX, ScaleY, Spacing, Angle, BorderStyle, Outline, Shadow, Alignment, MarginL, MarginR, MarginV, Encoding
Style: Base,Arial,58,&H00F4F4F4,&H00F4F4F4,&H00111111,&H50000000,-1,0,0,0,100,100,0,0,1,3,0,2,90,90,260,1

[Events]
Format: Layer, Start, End, Style, Name, MarginL, MarginR, MarginV, Effect, Text
"""
    lines = [header]
    for start, end, caption in events:
        words = tokenize_words(caption)
        if not words:
            continue

        words, split_at = wrap_two_lines(words, max_chars=28)
        duration = max(0.08, end - start)
        step = duration / len(words)

        for i in range(len(words)):
            ws = start + i * step
            we = end if i == len(words) - 1 else (start + (i + 1) * step)

            rendered = []
            for j, w in enumerate(words):
                clean = w.replace("{", "").replace("}", "")
                if j == i:
                    # Soft punch: warm highlight + slight scale pop + glow feel.
                    rendered.append(
                        r"{\1c&H00B8FF&\3c&H000000&\bord4\t(0,120,\fscx112\fscy112)\t(120,260,\fscx100\fscy100)}"
                        + clean
                        + r"{\r}"
                    )
                else:
                    rendered.append(clean)

            if split_at != -1:
                text = " ".join(rendered[:split_at]) + r"\N" + " ".join(rendered[split_at:])
            else:
                text = " ".join(rendered)

            lines.append(
                f"Dialogue: 0,{to_ass_time(ws)},{to_ass_time(we)},Base,,0,0,260,,{text}"
            )
    return "\n".join(lines) + "\n"


def main() -> None:
    events = parse_srt_blocks(SRC_SRT.read_text(encoding="utf-8"))
    ass = build_ass(events)
    OUT_ASS.write_text(ass, encoding="utf-8")
    print(str(OUT_ASS))


if __name__ == "__main__":
    main()
