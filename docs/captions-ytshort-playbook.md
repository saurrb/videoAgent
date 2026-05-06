# YT Shorts Caption Playbook (Project Default)

Last updated: 2026-05-06

## Goal

Produce caption style close to high-performing YouTube Shorts:

- Rounded bold text
- White base + yellow active word
- Thick black outline
- Bottom safe placement
- Word-synced highlight transitions

## Default Inputs

- Base reel video (no captions)
- `captions_synced.srt`
- `word_timestamps.json`

## Step 1: Build ASS Captions

```powershell
python .\scripts\build_wordtimed_ass.py `
  --srt "C:\ABS\reel\captions\captions_synced.srt" `
  --words "C:\ABS\reel\captions\word_timestamps.json" `
  --out "C:\ABS\reel\captions\captions_ytshort.ass" `
  --preset ytshort `
  --chunk-size 2 `
  --max-chars 13
```

## Step 2: Burn Captions

```powershell
.\tools\ffmpeg\ffmpeg-8.1.1-essentials_build\bin\ffmpeg.exe -y `
  -i "C:\ABS\reel\final\reel_base.mp4" `
  -vf "subtitles='C\:/ABS/reel/captions/captions_ytshort.ass':force_style='Fontname=Comic Sans MS,Fontsize=82,Outline=7.6,Shadow=0,MarginV=96,MarginL=62,MarginR=62,Spacing=0.2'" `
  -c:v libx264 -preset medium -crf 18 -c:a copy `
  "C:\ABS\reel\final\reel_captioned.mp4"
```

## Step 3: Visual QA (Mandatory)

Take frame samples across the timeline and verify:

1. Active highlighted word changes exactly with speech timing.
2. Captions stay inside frame on every sample.
3. Caption style remains soft/punchy, without continuous blinking.
4. No line clipping on long words.

## Known Good Reference

- `assets/reels/2026-05-06_soft-cute-v2/final/reel_soft_cute_latest.mp4`

## Notes

- If `python` or `ffmpeg` are unavailable in PATH, use repo-bundled tools.
- Prefer short phrase chunks for punchy shorts rhythm.
- Keep this playbook as the baseline for all future reel captioning.
