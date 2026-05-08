# Next Steps (DHEDiXy7B-Q)

## 1) Voice (done)

- `voice/voice_v1.mp3` is the source of truth for timing.
- Current duration (Speechma PRO, Brian, Pitch 0 / Speed 25 / Volume 200): ~53.9s.
- Speechma input file (paste this, not headings): `voice/speechma_input_v1.txt`.

## 2) Generate Scenes (Grok)

Use Grok Automation with the prompt pack:

- `meta/grok_automation_prompts_v1.txt`

Save downloaded clips as:

- `scenes/scene01.mp4` ... `scenes/scene09.mp4`

Helper (auto-import Grok downloads if filenames are `grok-*.mp4`):

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\monitor_grok_downloads.ps1 `
  -Workspace "C:\Users\saura\Documents\youtubeVideoAgent\assets\reels\2026-05-08_logic-loom-dhedixy7b-q" `
  -StartScene 1 -Count 9
```

## 3) Stitch Base Reel

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\stitch_reel_from_scenes.ps1 `
  -Workspace "C:\Users\saura\Documents\youtubeVideoAgent\assets\reels\2026-05-08_logic-loom-dhedixy7b-q" `
  -Scenes 9
```

Output:

- `final/reel_base.mp4`

## 4) Captions (new style)

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\run_caption_pipeline.ps1 `
  -AudioPath "C:\Users\saura\Documents\youtubeVideoAgent\assets\reels\2026-05-08_logic-loom-dhedixy7b-q\voice\voice_v1.mp3" `
  -SrtPath "C:\Users\saura\Documents\youtubeVideoAgent\assets\reels\2026-05-08_logic-loom-dhedixy7b-q\captions\captions_synced.srt" `
  -VideoPath "C:\Users\saura\Documents\youtubeVideoAgent\assets\reels\2026-05-08_logic-loom-dhedixy7b-q\final\reel_base.mp4" `
  -OutputVideoPath "C:\Users\saura\Documents\youtubeVideoAgent\assets\reels\2026-05-08_logic-loom-dhedixy7b-q\final\reel_v1_captioned.mp4" `
  -MaxChars 13
```

Then run watermark finalizer:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\finalize_logicloom_reel.ps1 `
  -InputVideo "C:\Users\saura\Documents\youtubeVideoAgent\assets\reels\2026-05-08_logic-loom-dhedixy7b-q\final\reel_v1_captioned.mp4" `
  -OutputVideo "C:\Users\saura\Documents\youtubeVideoAgent\assets\reels\2026-05-08_logic-loom-dhedixy7b-q\final\reel_v2_logicloom.mp4"
```
