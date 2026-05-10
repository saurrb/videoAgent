# YT Shorts Caption Playbook (Project Default)

Last updated: 2026-05-07

## Goal

Produce caption style close to high-performing YouTube Shorts:

- Heavy bold caps (Impact-style)
- White base + neon-green active word
- Thick black outline + subtle shadow
- Bottom safe placement
- Word-synced highlight transitions

## Default Inputs

- Base reel video (no captions)
- `captions_synced.srt`
- `word_timestamps.json`

## Mandatory Caption Rule

Use this approved script flow for default Logic Loom reel captions. Do not replace it with ad-hoc burned text, editor captions, platform-only captions, or unsynced captions unless the user explicitly approves that fallback for the current reel.

If `captions_synced.srt`, `word_timestamps.json`, ASS generation, ffmpeg burn-in, or visual QA fails, stop as blocked or regenerate the failed caption phase. Do not upload a reel with unverified captions.

## Fast-Pacing Rule

Keep captions fast-paced and tightly chunked to match the script rhythm, so the full narration fits naturally inside a short reel without feeling rushed.

Default pacing rules:

- Match the short-line script style with short caption chunks.
- Prefer 1-3 words on screen for punch lines and resets.
- Use 2-word chunks as the baseline for high-retention scripts.
- Avoid slow, full-sentence caption blocks unless the voice line is intentionally slow.
- If the script cannot fit into the target duration, tighten the script first; do not make captions linger longer.
- Caption timing must follow Speechma PRO voice pacing, not an assumed reading speed.

## Platform Caption + Hashtag Rule

Before upload, save final platform captions and hashtags to `meta/platform_caption_hashtags.md`.

Use US America hashtags by default for better RPM and US audience fit. Mix them with relevant niche/topic tags and platform discovery tags. Do not use unrelated trend tags or non-US geo tags unless the reel specifically targets that audience.

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

## Step 4: Branding Watermark (Publish-Ready)

If the generated scenes contain a bottom-right Grok watermark/safe-area, create a publish-ready branded final with the fixed Playbook white-box + logo preset:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\add_logicloom_watermark.ps1 `
  -InputVideo "C:\ABS\reel\final\reel_captioned.mp4" `
  -OutputVideo "C:\ABS\reel\final\reel_captioned_playbook.mp4"
```

Default branding asset path used by script:

- `assets/branding/playbook_logo_nobg.png`

## Known Good Reference

- `assets/reels/2026-05-06_soft-cute-v2/final/reel_soft_cute_latest.mp4`

## Notes

- If `python` or `ffmpeg` are unavailable in PATH, use repo-bundled tools.
- Prefer short phrase chunks for punchy shorts rhythm.
- For fast Logic Loom scripts, keep caption chunks tight enough that the whole narration fits the reel duration.
- Keep this playbook as the baseline for all future reel captioning.
