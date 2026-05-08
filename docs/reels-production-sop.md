# Reels Production SOP (Reusable)

Last updated: 2026-05-07

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

- Hook: high-stakes, curiosity-driven first line that makes the viewer feel they need the answer.
- Script target: 30-45 seconds for psychology/educational reels.
- Default retention style:
  - short lines, usually 3-8 words
  - first 2 seconds create tension or danger
  - one curiosity line before the list, such as `Watch closely.`
  - use a 3-pattern structure when possible
  - include hard resets: `No doubt.`, `Just confidence.`, `But intelligent people look different.`
  - avoid soft academic phrasing like `Psychology says...`; prefer `Psychology has a name for this.`
  - end with a reversal that reframes the hook
- Save to: `script/script_v1.txt`

Default script shape:

```text
The most dangerous person in the room
is usually the one who thinks
they are the smartest.

Psychology has a name for this.

The less people understand,
the more certain they sound.

Watch closely.

Low-awareness thinking follows 3 patterns.

First: absolute certainty.
...

Because real intelligence
is not sounding confident.

It is being aware enough
to question yourself.
```

## 3) Generate Voiceover (Speechma PRO Default)

- Provider: `https://speechmapro.com/`
- Voice: `Brian`
- Voice Effects:
  - Pitch: `0`
  - Speed: `25`
  - Volume: `200`
- Save to: `voice/voice_v1.mp3`
- Keep script and audio versioned together.
- Always capture screenshot proof of selected voice + effect values before generating.
- Close/dismiss popup overlays before generation.
- If captcha appears, complete it manually, then continue automation flow.
- For multiline scripts, avoid literal `\n`; prefer line-by-line input with `Enter` key presses.
- Do not use local TTS as a substitute for Speechma PRO in the default pipeline. If Speechma PRO cannot generate or download the audio, stop as blocked.

## 4) Scene Plan

Break script into scene beats:

- Scene 1: 0:00-0:05 hook
- Scene 2: 0:05-0:12 supporting line
- Scene 3: 0:12-0:20 emotional pivot
- Scene 4: 0:20-0:28 open-loop CTA

Store in: `meta/scene_plan_v1.md`

## 5) Generate Scene Videos (Meta AI/Grok via BrowserOS CLI)

- Create one clip per beat.
- Each scene must be an actual animated video clip, not a still image, screenshot crop, contact-sheet crop, or browser preview thumbnail.
- Keep same character identity and visual style.
- BrowserOS CLI is default for navigation and clicks.
- Take screenshots before important clicks and after each major browser state change. Do not keep clicking when the UI is unclear.
- If a browser site starts failing, open a new tab, return to the last known working area on that site, and inspect the state with screenshots before restarting the task.
- For every new reel, start Grok in a fresh new tab and keep that working tab selected/in front so the user can see the active canvas.
- In Grok, capture screenshots between each meaningful step: new tab, Agent (Beta), Empty Canvas, control verification, prompt before submit, generated result, and download state.
- If a generated clip opens in a separate media tab, return immediately to the working Grok canvas tab after inspection; do not continue workflow from media-only tabs.
- Click the generated video card in canvas to reveal the in-canvas action row, then use that row for download.
- Use the bottom-left zoom `+ / -` controls to fit the full card/action row before attempting download clicks.
- After each Grok download click, import the newest file into the workspace scene slot:
  `powershell -ExecutionPolicy Bypass -File .\scripts\import_grok_scene_download.ps1 -Workspace "C:\ABSOLUTE\PATH\assets\reels\YYYY-MM-DD_name"`
- In Grok, always enter through:
  1. new tab at `Imagine`
  2. `Agent (Beta)`
  3. `Empty Canvas`
  4. `Video`
  5. `9:16 Vertical`
- Mandatory before each generation:
  - hover over relevant controls and read tooltips/options
  - confirm image/video mode, quality preset, duration, aspect ratio, and motion settings
  - confirm target save location and scene filename
  - set explicit timer window before submit:
    - image: `45s` soft check, `120s` hard timeout
    - video: `90s` soft check, `240s` hard timeout
    - stitch: `180s` soft check, `420s` hard timeout
- Save as:
  - `scenes/scene01.mp4`
  - `scenes/scene02.mp4`
  - `scenes/scene03.mp4`
  - `scenes/scene04.mp4`
- After each generated scene, do immediate local download and quick review before moving to next scene.
- When style is stable, batch 2-3 scene requests in one Grok prompt (for example scene02-scene04) to reduce total turnaround time, then download/import each resulting clip in sequence.
- If a generated clip is visible/playable in the browser but cannot be downloaded as an MP4 into the workspace, stop as blocked. Do not recreate the scene from screenshots.

### 5.1) Grok Challenges and Mitigation

- Wrong mode (image/video/stitch): verify mode every run via hover+inspect.
- Wrong Grok workspace: use `Agent (Beta)` and `Empty Canvas`; do not prompt from the default Imagine feed.
- Weak or overdone animation: separate camera-motion and subject-motion instructions.
- Scene-voice mismatch: map each scene prompt to exact script beat and duration.
- Stitch instability on larger sets: stitch in smaller batches, then final combine locally.
- Inconsistent visual identity: keep fixed identity/style anchors in every scene prompt.
- Broken/stale Grok tab: open a new tab to Grok, enter `Agent (Beta)`, screenshot-check whether the last canvas is recoverable, and continue there when possible. If it is not recoverable, start a new `Empty Canvas`.
- Hidden/background Grok work: bring the active Grok tab to the front before every important action and screenshot it.
- Media-tab drift: when an `assets.grok.com` (or other video-only) tab opens, switch back to the active Grok canvas tab before the next click or prompt.

Reference: `docs/grok-agent-playbook.md`

## 6) Captions

- Generate transcript timing (manual or STT-assisted).
- Save SRT as: `captions/captions_v1.srt`
- Use the approved caption scripts/settings below. Do not substitute an ad-hoc caption burn unless the user explicitly approves it.
- Keep captions fast-paced and tightly chunked to match the script rhythm, so the full narration fits naturally inside a short reel without feeling rushed.
- If a strong retention script runs long, tighten the script before slowing captions or extending the reel.

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
- For fast scripts, use 1-3 word caption chunks and avoid full-sentence caption blocks.
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
- Every scene is animated video, not still-image filler.
- Source scene assets exist as downloaded/generated MP4s in the workspace.
- Speechma PRO audio exists locally and matches the script version.
- Character identity consistent across scenes.
- Audio peak not clipping.
- Active highlighted word is aligned with spoken word.
- Captions never go outside visible frame.
- No unnecessary blinking/shaking on static caption spans.
- Browser UI options were hover-inspected before generation runs.
- Scene cuts follow voice phrase boundaries.
- Rejected outputs moved to recycle/trash flow, not hard-deleted.
- Screenshot evidence captured across phases so manual re-instructions are minimized.
- Iterative fixes were applied in each phase until quality matched target.
- If any of these fail, do not upload. Report the blocker or regenerate the weak phase.

## 8.1) Publish-Ready Logic Loom Final (Mandatory)

Before publishing, generate a branded final that replaces the bottom-right Grok watermark area with `@logicloom` and validates the MP4 locally:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\finalize_logicloom_reel.ps1 `
  -InputVideo "C:\ABSOLUTE\PATH\final\reel_v1_captioned.mp4" `
  -OutputVideo "C:\ABSOLUTE\PATH\final\reel_v2_logicloom.mp4"
```

Use the `_logicloom` output for Facebook/Instagram and YouTube uploads. Do not upload a Grok raw export or a captioned file that has not passed this preflight.

What the preflight checks:

- video stream exists
- audio stream exists
- size is at least 1080x1920
- duration is inside the expected short-form range
- final filename includes `logicloom`, `logic-loom`, or `logic_loom`

If you only need to re-check a final file:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\test_reel_publish_ready.ps1 `
  -VideoPath "C:\ABSOLUTE\PATH\final\reel_v2_logicloom.mp4" `
  -RequireAudio `
  -RequireLogicLoomFileName
```

## 8.2) Manual-Intervention Reduction Rules

- Every repeated final edit must be scripted before the next upload.
- Browser-only steps need visible screenshots before generation, after generation, and before publish.
- Captions, watermark, and MP4 validation happen locally; do not verify those by eye only.
- Save final captions/hashtags to `meta/` before opening upload pages.
- Use US America hashtags by default for better RPM and US audience fit. Keep them relevant; do not pad with unrelated trend tags.
- Prefer API upload helpers for YouTube when auth is ready; use browser upload only for approvals or blocked API scopes.

## 10) Iterative-by-Phase Rule (Mandatory)

Do not wait until final export to improve. Iterate in every phase:

1. Script phase: refine hook clarity and beat pacing.
2. Voice phase: refine tone, pace, and intelligibility.
3. Scene generation phase: refine prompts/settings from screenshot review.
4. Stitch phase: refine cut points and transition rhythm.
5. Caption phase: refine timing, style, and frame safety.
6. Final QA phase: re-check sampled frames and only then lock final.

Use screenshot feedback continuously so the system can run with minimal repeated manual inputs.

## 11) Completion Rule (Mandatory)

- A reel request is not complete at planning stage.
- Continue execution until:
  1. final rendered reel exists in `final/`
  2. captions/voice sync QA has passed
  3. output path is shared
- Only pause for hard blockers (auth/captcha/permissions/outage), then resume immediately after unblock.

## 9) Publish + Log

Before opening upload pages, create or update `meta/platform_caption_hashtags.md` with:

- final post caption
- Facebook/Instagram caption version
- YouTube Shorts caption version
- US America RPM-focused hashtags mixed with relevant niche tags

Record in `meta/publish_log.md`:

- Post URL
- Date/time (timezone)
- Hook version
- 2h / 24h metrics (views, watch time proxy, comments, shares)
