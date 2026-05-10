# videoAgent

Starter repository for the `videoAgent` project.

## Reel Pipeline (Minimal Input)

Fastest start in a fresh tab:

`Create a reel from this YouTube link using our default pipeline: <PASTE_LINK>`

Expected behavior for this prompt:

- run end-to-end automatically
- do not stop at planning
- stop only on hard blockers

1. One-time setup:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\setup_reel_pipeline.ps1
```

2. Start a reel from a YouTube link:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\start_reel_from_youtube.ps1 `
  -YoutubeUrl "https://www.youtube.com/watch?v=<id>" `
  -Name "topic-short-name" `
  -TargetSeconds 40
```

3. Then follow:

- `docs/youtube-link-to-reel-system.md`
- `docs/reels-production-sop.md`
- `docs/captions-ytshort-playbook.md`
- `docs/reel-ops-postmortem-2026-05-09.md` (manual-effort reduction + robust flow)

## Operator Command Mode

Manual inputs are limited to:

1. `start from readme` (or `start from readme N minute video`)
2. `done` (after you run Grok prompts and scenes are saved to `C:\Users\saura\Downloads\grok-folder-1`)

Duration rule:

- If user says `start from readme 4 minute video`, target duration is ~240 seconds.
- The same duration rule applies to any `N minute video` command.

## Prompt Delivery Rule (Mandatory)

When providing Grok scene prompts to the user, always deliver them in one complete copy block:

- single fenced code block
- includes global style + scene-by-scene prompts
- ready to copy-paste without extra formatting edits

Do not split prompts across multiple messages unless the user explicitly asks.

Scene length rule:

- Every scene prompt must be fixed to `6s`.
- Scene count must be computed as: `ceil(voice_seconds / 6)`.
- Examples:
  - ~1 minute voice: 9-10 scenes
  - ~2 minute voice: 19-20 scenes
  - ~4 minute voice: 39-40 scenes

## Mandatory Docs Order (Always Follow)

For every new reel run, follow docs in this order:

1. `docs/youtube-link-to-reel-system.md` (end-to-end flow and guardrails)
2. `docs/reels-production-sop.md` (production steps + QA gates)
3. `docs/captions-ytshort-playbook.md` (caption build/burn standards)
4. `docs/meta-api-setup.md` (publishing + Meta fallback behavior)
5. `docs/reel-ops-postmortem-2026-05-09.md` (what failed before, robust defaults)

## Robustness Guardrail (From 2026-05-09 Failures)

Before marking any reel done, all items below must be true:

1. Grok control path was correct: `Imagine -> Agent (Beta) -> Empty Canvas -> Video -> 9:16`.
2. For scene2+ prompt input, replace text with `Ctrl+A -> Backspace -> Paste -> Generate` (no partial edits).
3. Each scene is generated and downloaded before moving to next prompt.
4. Scene files are true MP4 outputs in workspace `scenes/` (not previews/screenshots).
5. Speechma PRO voice was generated in current workspace and used in final stitch.
6. Final audio length is hard-locked to target reel length (for 1 min: exactly `60.000s`).
7. Captions are full narration captions (not scene-topic-only placeholders).
8. Captions are positioned at target safe height for this run (if requested: ~75% from top).
9. Playbook branding style matches project reference final style (pure white bottom-right box + The Relationship Playbook logo overlay).
10. Final file passes preflight and has visual screenshot proof from mid and end timestamps.

If any item fails, do not publish.

## Permanent Rule: Speechma PRO Voice Is Mandatory

Do not stitch scenes or create final video unless all are true:

1. Speechma PRO voice was generated for the current workspace run.
2. Voice is saved as `voice/voice_v1.mp3`.
3. Raw Speechma download is retained in `voice/` for traceability.
4. Proof screenshots exist for:
   - input text
   - voice effects (`Pitch=0`, `Speed=25`, `Volume=200`)
   - generated audio row before download
5. Final captions must be regenerated from this same `voice/voice_v1.mp3` timing before publish.
6. Duration gate before scene prompt generation:
   - voice must be between `60s` and `120s` for short reels unless user explicitly requested another target duration
   - for `N minute video` requests, voice must be close to `N * 60s` before scene prompting
7. Move (do not copy) Speechma downloads from `Downloads` into workspace `voice/`.

If any item is missing, treat as blocked and stop before stitch/final.

## Permanent Rule: No Downloads Trace

- Grok and Speechma artifacts must not be left in `C:\Users\saura\Downloads`.
- Always move artifacts into workspace folders (`scenes/`, `voice/`) and clean leftovers.

## Permanent Rule: Grok Automation Completion Proof

Before using scene outputs for stitch/final, take a final screenshot of Grok Automation panel that shows:

1. Prompt queue is fully completed for the active group.
2. No row is `Running`, `Retrying`, or `Pending`.
3. Every required scene row shows `Completed 100%`.

If this screenshot proof is missing, do not proceed to stitch/final.

## Mandatory Grok Timer Workflow (All Projects)

Every time a Grok image/video/stitch generation is submitted, run a local timer wait in terminal.
This is required to avoid random clicking and to standardize wait/retry behavior.

Timer script:

`scripts/wait_for_grok_generation.ps1`

Default wait windows:

- image: soft check `45s`, hard timeout `120s`
- video: soft check `90s`, hard timeout `240s`
- stitch: soft check `180s`, hard timeout `420s`

Example (video + auto-import to `scene02.mp4`):

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\wait_for_grok_generation.ps1 `
  -Type video `
  -Since (Get-Date) `
  -Workspace "C:\ABS\PATH\assets\reels\YYYY-MM-DD_name" `
  -SceneNumber 2
```

Batch download auto-import monitor (for multi-scene Grok prompts):

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\monitor_grok_downloads.ps1 `
  -Workspace "C:\ABS\PATH\assets\reels\YYYY-MM-DD_name" `
  -StartScene 2 `
  -Count 3 `
  -Since (Get-Date)
```

## Publish-Ready Final

Use the finalizer for every reel before upload. It replaces the bottom-right Grok watermark area with the Playbook white-box + logo preset, then runs an `ffprobe` preflight for duration, size, stream health, audio, and branding filename checks.

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\finalize_logicloom_reel.ps1 `
  -InputVideo "C:\ABS\PATH\final\reel_v1_captioned.mp4" `
  -OutputVideo "C:\ABS\PATH\final\reel_v2_playbook.mp4"
```

Use only the validated `_playbook` (or equivalent branded) output for Facebook, Instagram, and YouTube uploads.

## Meta API Posting

Meta API posting is configured for this project. Reels, images, and videos can be posted through the API instead of the browser UI when the final media is available at a public HTTPS URL.

Configured Meta assets:

- App: `Logic Loom Reel Publisher`
- Facebook Page: `Flora knows Nothing`
- Instagram: `@floraknowsnothing`

Primary setup/reference doc:

- `docs/meta-api-setup.md`

Instagram Reel wrapper:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\meta_publish_reel.ps1 `
  -VideoUrl "https://example.com/final-reel.mp4" `
  -Caption "Caption text #reels" `
  -ShareToFeed
```

Important: Meta publishing APIs require a public HTTPS media URL. Local file paths in `assets/reels/...` must be uploaded to temporary public storage first.

Facebook visibility guardrail (mandatory):

1. Primary publish can use `/{page_id}/video_reels`.
2. After publish, check video status and ensure `publishing_phase.publish_status=published`.
3. If status is `draft` or post is not visible on page feed, immediately fallback to:
   - `/{page_id}/videos` with `published=true`
4. Do not mark Facebook as done until a live Facebook permalink is returned and opens publicly.

Preflight only:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\test_reel_publish_ready.ps1 `
  -VideoPath "C:\ABS\PATH\final\reel_v2_playbook.mp4" `
  -RequireAudio `
  -RequireBrandFileName
```

## YouTube API

Use this setup guide:

- `docs/youtube-api-setup.md`

Quick upload helper:

- `scripts/youtube_upload_reel.ps1`
