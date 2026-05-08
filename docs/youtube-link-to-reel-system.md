# YouTube Link -> Reel System (Production Playbook)

Last updated: 2026-05-07

This document captures what we learned end-to-end: bottlenecks we hit, what fixed them, and the repeatable workflow for creating a reel/short from a YouTube reference with minimal user input.

## 1) Minimal Input Contract

Primary mode (single-input mode):

1. YouTube link only

Everything else is auto-defaulted.

Defaults:

- Reel name: auto from video title + date slug
- Target duration: 40 seconds
- Voice: Speechma PRO `Brian`
- Voice effects: `Pitch=0`, `Speed=25`, `Volume=200`
- Style baseline: cinematic, high-detail, caption-first reel format

Fallback mode (if user wants manual control), you may provide:

1. YouTube link
2. Reel name (short slug)
3. Optional voice preference

Everything else follows this playbook.

## 1.1) Minimal Prompt for New Tab

Use this exact prompt:

`Create a reel from this YouTube link using our default pipeline: <PASTE_LINK>`

Execution mode is implicit in this prompt:

- Continue end-to-end until final reel is exported in `final/`.
- Do not stop at planning/docs/script-only output.
- Stop only for hard blockers (login/captcha/permission/payment wall/tool outage).
- If blocked, report the blocker and continue immediately after unblock.
- If a mandatory asset cannot be created or downloaded at production quality, stop as blocked. Do not fabricate a lower-quality substitute.

## 2) One-Time Setup

Run once on this machine:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\setup_reel_pipeline.ps1
```

What this ensures:

- `browseros-cli` available in project
- Python dependencies (`faster-whisper`, `srt`) available
- Repo binaries for `yt-dlp` and `ffmpeg` are present

## 3) Start a New Reel from a YouTube Link

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\start_reel_from_youtube.ps1 `
  -YoutubeUrl "https://www.youtube.com/watch?v=<id>" `
  -Name "topic-short-name" `
  -TargetSeconds 40
```

This auto-creates:

- `assets/reels/YYYY-MM-DD_<name>/` workspace
- downloaded reference video/audio
- extracted timeline frames + contact sheet
- seeded brief/checklist/prompt-pack in `meta/`

## 4) Standard Folder Structure

Inside each reel workspace:

- `script/` narration text versions
- `voice/` voice outputs
- `scenes/` reference stills and scene clips
- `captions/` SRT, word timestamps, ASS
- `edit/` stitch lists and intermediate files
- `final/` base and captioned finals
- `meta/` plans, prompts, QA logs
- `analysis/` extracted frames and contact sheet

## 5) Production Flow (Repeatable, Hardened)

1. Analyze reference pacing from extracted frames/contact sheet and write beat timings first.
2. Write script with a high-retention hook in the first 1-2 seconds and lock script version before generation.
   - Prefer danger/tension hooks over neutral explainers.
   - Use short line breaks for reel pacing.
   - Add a curiosity reset before the structure, such as `Watch closely.`
   - Use `3 patterns`, `3 signs`, or `3 mistakes` when the topic supports it.
   - End with a sharp reversal that makes the viewer rethink the hook.
3. Generate voice first, then adjust scene timings to voice (never the opposite).
   - Default provider: `https://speechmapro.com/`
   - Default voice: `Brian`
   - Voice effects baseline: `Pitch=0`, `Speed=25`, `Volume=200`
4. Build scene prompts in pairs per scene:
   - image prompt (identity, wardrobe, lighting, lens, mood, 9:16)
   - animation prompt (camera move, subject motion, intensity, transition intent)
5. Use BrowserOS CLI as the default control surface for Meta/Grok/Speechma PRO UI steps.
6. Before clicking generate, run UI discovery protocol:
   - open Grok in a fresh new tab for the current reel/canvas
   - keep the active Grok tab selected/in front so the user can see the working canvas
   - take screenshots between new tab, Agent (Beta), Empty Canvas, control verification, prompt submission, result review, and download
   - if a generated clip opens in a separate media tab, switch back to the working Grok canvas tab before continuing
   - click the generated video card to expose its in-canvas action row; use that row for download/export
   - use bottom-left zoom `+ / -` to fit the full card and action row before download clicks
   - hover every relevant button/control
   - read tooltips/options
   - verify mode (image/video/stitch), duration, aspect ratio, quality preset
   - confirm output folder naming before generation
   - for Grok specifically, enter through `Imagine` -> `Agent (Beta)` -> `Empty Canvas` before prompting
7. Generate scenes one-by-one, keep best take, and immediately save to local workspace with scene index.
   - Helper import command after each Grok download click:
     `powershell -ExecutionPolicy Bypass -File .\scripts\import_grok_scene_download.ps1 -Workspace "C:\ABSOLUTE\PATH\assets\reels\YYYY-MM-DD_name"`
   - Timer discipline for Grok runs:
     - images: soft check `45s`, hard timeout `120s`
     - videos: soft check `90s`, hard timeout `240s`
     - stitch jobs: soft check `180s`, hard timeout `420s`
   - For speed, batch request `2-3` scenes in one Grok prompt once style is locked; then download/import each clip with strict scene numbering.
8. Stitch to voice beats; avoid hard cuts inside active spoken phrases.
9. Run captions pipeline (SRT -> word timestamps -> ASS -> burn).
   - Keep captions fast-paced and tightly chunked to match the script rhythm.
   - The whole narration should fit naturally inside the target reel duration without feeling rushed.
   - If timing feels crowded, tighten the script before slowing captions.
10. Create final platform captions/hashtags.
   - Use US America hashtags by default for better RPM and US audience fit.
   - Save final caption/hashtag variants to `meta/platform_caption_hashtags.md` before upload.
11. Run `finalize_logicloom_reel.ps1` to add `@logicloom` and validate the MP4 before upload.
12. Run screenshot QA at multiple timestamps and iterate only weak scenes/caption blocks.

## 5.1) Hard Failure Rules From 2026-05-07 Incident

These are mandatory quality gates, not preferences:

1. Do not build a reel from browser screenshots, cropped screenshots, contact sheets, preview thumbnails, or still images when the workflow requires animated scene clips.
2. Do not replace Grok/Meta generated video clips with a still-image slideshow or fake motion unless the user explicitly asks for that fallback.
3. Do not use local Windows TTS, browser TTS, placeholder audio, or any non-Speechma voice when the default pipeline requires Speechma PRO. If Speechma PRO is blocked by login, captcha, popup, quota, or download failure, stop and report the blocker.
4. Do not upload anything unless every scene clip is an actual downloaded/generated video asset saved in the reel workspace, not merely visible in the browser.
5. Do not upload if Grok/Meta produces playable clips but the MP4 files cannot be downloaded. That is a blocker, not permission to use screenshots.
6. Do not upload if captions were not produced through the approved caption scripts/settings and verified in sampled frames.
7. The correct outcome under a blocker is: preserve evidence, report exactly what blocked, and wait/resume after unblock. A weak reel is worse than no reel.

## 5.2) Default Retention Writing Style

Use this style for Logic Loom psychology/education reels unless the user asks otherwise:

```text
The most dangerous person in the room
is usually the one who thinks
they are the smartest.

Psychology has a name for this.

The less people understand,
the more certain they sound.

No doubt.
No hesitation.
No self-questioning.

Just confidence.

And people mistake that confidence
for intelligence.

Watch closely.

Low-awareness thinking follows 3 patterns.
```

Rules:

- Keep most lines under 8 words.
- Use pattern interrupts every 2-4 lines.
- Prefer concrete phrases: `zero curiosity`, `ego over growth`, `absolute certainty`.
- Avoid slow setup, disclaimers, and textbook tone.
- Make the final 2 lines a memorable reversal.
- Write with caption pacing in mind: short spoken lines should become short 1-3 word caption chunks.

## 6) Caption System (Already Proven)

Use the YT-shorts style flow:

1. Generate/clean SRT.
2. Extract word timestamps.
3. Build ASS with active-word highlight.
4. Burn ASS into final video.

Primary refs:

- `docs/captions-ytshort-playbook.md`
- `docs/reels-production-sop.md`
- `scripts/run_caption_pipeline.ps1`

## 7) Bottlenecks We Hit + Stable Fixes

1. Highlight not aligned to spoken word.
   - Fix: word-level timestamps + ASS active-word overlays.
2. Captions overflowed outside frame.
   - Fix: strict `max chars`, safe margins, screenshot checks.
3. Captions looked like a static line instead of punchy words.
   - Fix: chunked short phrases + per-word active color transitions.
4. Too much blinking/shaking.
   - Fix: only animate on caption changes; no constant jitter.
5. Scene visuals not matching narration.
   - Fix: scene-by-scene prompts and clip timing tied to script beats.
6. Inconsistent quality pass to pass.
   - Fix: mandatory iterative review loop with frame sampling.
7. Forgetting available UI options in generation tools.
   - Fix: mandatory hover-and-tooltip pass before every generation cycle.
8. Drifting from BrowserOS CLI and doing ad-hoc manual flow.
   - Fix: BrowserOS CLI is the default documented control path for all web generation actions.
9. Folder/file confusion across iterations.
   - Fix: strict scene indexing and immediate local save with consistent names.
10. Grok watermark replacement was too manual.
   - Fix: `scripts/finalize_logicloom_reel.ps1` is the only approved finalization path.
11. Upload readiness depended on visual inspection.
   - Fix: `scripts/test_reel_publish_ready.ps1` validates streams, dimensions, duration, audio, and Logic Loom naming before upload.
12. Browser UI state was hard to audit later.
   - Fix: screenshot every major browser decision point and store the evidence in `analysis/` or `screenshots/`.
13. Generation wait time became inconsistent and wasteful.
   - Fix: enforce soft/hard timers per generation type and use batched multi-scene prompts after style lock.

## 8) Iterative QA Loop (Non-Negotiable)

For every version:

1. Export candidate.
2. Capture 8+ frames across timeline.
3. Check:
   - word highlight sync
   - caption in-frame
   - visual intensity and realism
   - transitions matching beat
4. Log issues in `meta/`.
5. Regenerate only weak scenes and re-stitch.

## 9) Automation Boundaries

Automated in repo:

- workspace scaffolding
- source capture + frame extraction
- caption timing and burn pipeline

Manual/agent UI steps (BrowserOS):

- generation inside Meta AI / Grok / Speechma PRO
- choosing best takes
- platform posting approvals

Grok-specific operational reference:

- `docs/grok-agent-playbook.md`

Grok entry path is mandatory:

1. Open a fresh new tab at `https://grok.com/imagine`.
2. Click `Agent (Beta)`.
3. Start with `Empty Canvas`.
4. Set `Video`, desired quality/duration, and `9:16 Vertical`.
5. Prompt one scene at a time.
6. Keep that working tab in front and screenshot each major state.

## 10) Fast Start for Future Requests

When you give a new YouTube link, we should do exactly:

1. Run `start_reel_from_youtube.ps1`
2. Fill scene prompts from the generated brief
3. Generate clips + voice
4. Stitch + caption pipeline
5. Iterative screenshot QA
6. Final export in `final/`
7. Branding watermark applied for publishing
8. Publish-ready preflight passed

That gives near-minimal-input reel creation from here forward.

Mandatory behavior:

- Single-link request means full execution mode, not analysis-only mode.
- The job is complete only after final render exists (plus quick QA evidence).
- A final render is valid only if it uses production-quality animated scene clips, Speechma PRO voice, approved caption styling, local finalizer branding, and publish-ready preflight.

## 11) Non-Negotiable Guardrails (New)

1. BrowserOS CLI first for Meta/Grok/ElevenLabs navigation and actions.
2. For Grok, always use `Agent (Beta)` -> `Empty Canvas` before entering scene prompts.
3. Hover+inspect controls before every generate action to discover hidden options.
4. Voice-first timing lock before scene stitching.
5. Scene-level saves after each successful generation (no batch waiting).
6. Captions must pass in-frame and active-word sync checks before final export.
7. Keep rejected variants in recycle/trash workflow, not hard-delete.
8. Use screenshot-driven operation in every phase so repeated manual guidance is minimized.
9. Run iterative improvement loops in each phase (script, voice, scene gen, stitch, captions, QA) until outputs match target quality.
10. Never downgrade the pipeline silently. Any fallback from Grok video, Speechma PRO voice, or approved captions requires explicit user approval.

## 12) Screenshot-Driven Execution Rule

- Capture screenshots while operating BrowserOS tools to read visible options/states and reduce back-and-forth manual input.
- For each major action, store evidence frames in workspace `analysis/` or `meta/` notes.
- If quality is off, diagnose from screenshots first, then adjust prompts/settings and rerun.
- Do not click randomly when a website is confusing, slow, or partially broken. Take a screenshot first, inspect what is visible, and decide the next action from evidence.
- If a site stops responding or the current tab state becomes unreliable, open a new tab for the same site and navigate back to the last known working area inside that website.
- If the previous canvas/session is visible in the new tab, inspect it with screenshots and continue from there. If it is not recoverable, start a fresh session/canvas and document that recovery step with screenshots.
- For Grok specifically: if the current canvas is not working, open a new tab, go to `Imagine` -> `Agent (Beta)`, check whether the last canvas is available, and only then choose `Empty Canvas` for a clean restart.
- For every new reel/canvas, do not reuse an old Grok tab by default. Start from a fresh Grok tab, keep it selected, and make the visible canvas the source of truth.
- Do not drift into media-only tabs. Any temporary `assets.grok.com` inspection must be followed by an immediate return to the active Grok canvas tab.
- Apply the same recovery rule to Speechma PRO, Meta Business Suite, YouTube Studio, and other browser tools: fresh tab, last working area, screenshot verification, then clean restart only when needed.

## 12.1) No-Manual-Finalization Rule

The final export path is:

```text
captioned MP4 -> finalize_logicloom_reel.ps1 -> validated _logicloom MP4 -> upload
```

Do not manually cover watermarks in an editor. Do not upload files that skip the finalizer. If preflight fails, fix the local export and rerun the finalizer before opening Meta Business Suite or YouTube.

Preflight does not prove creative quality by itself. A `_logicloom` file can be publish-ready technically but still invalid if it was made from screenshots, still-image filler, local TTS, or unapproved captions. Treat those as upstream failures.

## 13) Speechma PRO Voice Protocol (Default)

1. Open `https://speechmapro.com/` via BrowserOS CLI.
2. Paste script into `Input Text`.
3. Select `Brian`.
4. Open `Voice Effects` and set:
   - Pitch `0`
   - Speed `25`
   - Volume `200`
5. Capture a screenshot before generation to verify all settings.
6. Handle popup interruptions first (close/dismiss ad/support overlays) before clicking generate.
7. If captcha is shown, user completes captcha once, then resume generation flow.
8. Download output and save as `voice/voice_v1.mp3` (or next version).
9. For multiline scripts, use real line breaks via PowerShell here-string; never pass literal `\n` in fill text.

Detailed voice runbook:

- `docs/speechmapro-tts-playbook.md`
