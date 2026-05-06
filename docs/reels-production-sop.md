# Reels Production SOP (Reusable)

## Caption Standard (Default Going Forward)

Use this as the default caption style for all new reels:

- Rounded bold text
- White base words
- Active spoken word in yellow
- Thick black outline
- Bottom safe area placement
- Word-level timing sync (active word changes with speech)

Reference output:

- `assets/reels/2026-05-06_soft-cute-v2/final/reel_soft_cute_latest.mp4`

## 1) Create Post Workspace

Use the helper script:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\new-reel-workspace.ps1 -Name "sleep-peacefully"
```

This creates:

- `assets/reels/YYYY-MM-DD_sleep-peacefully/`
  - `script/`
  - `voice/`
  - `scenes/`
  - `captions/`
  - `edit/`
  - `final/`
  - `meta/`

## 2) Write Hook + Script

- Hook: single-line emotional trigger.
- Script target: 20-35 seconds.
- Save to: `script/script_v1.txt`

## 3) Generate Voiceover (ElevenLabs)

- Choose stable voice ID.
- Use `mp3_44100_128` by default.
- Save to: `voice/voice_v1.mp3`
- Keep script and audio versioned together.

## 4) Scene Plan

Break script into scene beats:

- Scene 1: 0:00-0:05 hook
- Scene 2: 0:05-0:12 supporting line
- Scene 3: 0:12-0:20 emotional pivot
- Scene 4: 0:20-0:28 open-loop CTA

Store in: `meta/scene_plan_v1.md`

## 5) Generate Scene Videos (Meta AI)

- Create one clip per beat.
- Keep same character identity and visual style.
- Save as:
  - `scenes/scene01.mp4`
  - `scenes/scene02.mp4`
  - `scenes/scene03.mp4`
  - `scenes/scene04.mp4`

## 6) Captions

- Generate transcript timing (manual or STT-assisted).
- Save SRT as: `captions/captions_v1.srt`

### 6.1) Build Word-Timed ASS Captions (YT Shorts Style)

Use:

```powershell
python .\scripts\build_wordtimed_ass.py `
  --srt "C:\ABSOLUTE\PATH\captions\captions_synced.srt" `
  --words "C:\ABSOLUTE\PATH\captions\word_timestamps.json" `
  --out "C:\ABSOLUTE\PATH\captions\captions_ytshort.ass" `
  --preset ytshort `
  --chunk-size 2 `
  --max-chars 13
```

Notes:

- `--preset ytshort` enables rounded Shorts-like styling.
- `--chunk-size 2` keeps phrase chunks short and punchy.
- `--max-chars 13` helps prevent overflow on narrow frames.
- Always keep captions inside frame safe area.

## 7) Assemble

In editor of choice (or FFmpeg/remotion):

- Place scene clips in order.
- Align to voice timing.
- Add burned captions or platform captions.
- Export MP4 (1080x1920, 30fps, H.264/AAC).

### 7.1) Burn Captions (Repo FFmpeg)

```powershell
.\tools\ffmpeg\ffmpeg-8.1.1-essentials_build\bin\ffmpeg.exe -y `
  -i "C:\ABSOLUTE\PATH\final\reel_base.mp4" `
  -vf "subtitles='C\:/ABSOLUTE/PATH/captions/captions_ytshort.ass':force_style='Fontname=Comic Sans MS,Fontsize=82,Outline=7.6,Shadow=0,MarginV=96,MarginL=62,MarginR=62,Spacing=0.2'" `
  -c:v libx264 -preset medium -crf 18 -c:a copy `
  "C:\ABSOLUTE\PATH\final\reel_captioned.mp4"
```

If local Python/FFmpeg are not in PATH, use repo-bundled binaries/scripts exactly as above.

Output: `final/reel_v1.mp4`

## 8) QA Checklist

- No hard cuts against sentence boundaries.
- Captions readable on mobile.
- Hook appears in first 1.5 seconds.
- Character identity consistent across scenes.
- Audio peak not clipping.
- Active highlighted word is aligned with spoken word.
- Captions never go outside visible frame.
- No unnecessary blinking/shaking on static caption spans.

## 9) Publish + Log

Record in `meta/publish_log.md`:

- Post URL
- Date/time (timezone)
- Hook version
- 2h / 24h metrics (views, watch time proxy, comments, shares)
