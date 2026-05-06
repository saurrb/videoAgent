# Caption Workflow (Reels)

This is the production workflow used for:

- exact word timing from voice audio
- active-word highlight while speaking
- keeping captions inside a 9:16 frame

## 1) Inputs

- Narration audio (mp3/wav/m4a)
- Base subtitle text in `.srt`
- Target reel video (1080x1920)

## 2) Generate word timestamps

Use `faster-whisper` through:

`C:\Users\saura\Documents\videoAgent\scripts\extract_word_timestamps.py`

Example:

```powershell
& "C:\Users\saura\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe" `
  "C:\Users\saura\Documents\videoAgent\scripts\extract_word_timestamps.py" `
  --audio "C:\ABS\voice.mp3" `
  --out "C:\ABS\word_timestamps.json"
```

Output JSON contains per-word `start/end` seconds.

## 3) Build ASS captions with highlight rules

Use:

`C:\Users\saura\Documents\videoAgent\scripts\build_wordtimed_ass.py`

Example:

```powershell
& "C:\Users\saura\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe" `
  "C:\Users\saura\Documents\videoAgent\scripts\build_wordtimed_ass.py" `
  --srt "C:\ABS\captions_subsync.srt" `
  --words "C:\ABS\word_timestamps.json" `
  --out "C:\ABS\captions_wordtimed_soft.ass" `
  --max-chars 16
```

### How highlighting works

- `Base` line: stable full caption across the line duration.
- `Active` overlays: only the current spoken word is restyled.
- Timing source: word-level timestamps, not guessed equal slices.

This avoids karaoke sweep lines and keeps active-word emphasis readable.

## 4) Render captions into video

```powershell
$ff="C:\Users\saura\Documents\videoAgent\tools\ffmpeg\ffmpeg-8.1.1-essentials_build\bin\ffmpeg.exe"
& $ff -y -i "C:\ABS\reel_base.mp4" `
  -vf "ass='C\\:\\ABS\\captions_wordtimed_soft.ass'" `
  -c:a copy "C:\ABS\reel_captioned.mp4"
```

## 5) Frame-safety rules (to avoid text going out of frame)

Implemented in script/style defaults:

- 2-line wrap with `--max-chars` (default `16`)
- `Fontsize=42`
- margins: `MarginL=140`, `MarginR=140`, `MarginV=340`
- bottom-center alignment

If a device still clips text, reduce `--max-chars` (e.g., `14`) or font size in style.

## 6) Timing quality checks

Before publishing:

1. Export screenshots at multiple timestamps across the reel.
2. Verify active word matches spoken word.
3. Verify no clipping on left/right/bottom.
4. Verify stable caption (no jitter unless intentionally animated).

## 7) Current approved style

The currently approved look is the one matching:

`reel_soft_cute_v11_highlight_strong_safe.mp4`

and re-rendered as:

`reel_soft_cute_v13_reverted_to_v11.mp4`
