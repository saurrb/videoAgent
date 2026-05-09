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

Use the finalizer for every reel before upload. It replaces the bottom-right Grok watermark area with `@logicloom`, then runs an `ffprobe` preflight for duration, size, stream health, audio, and Logic Loom filename.

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\finalize_logicloom_reel.ps1 `
  -InputVideo "C:\ABS\PATH\final\reel_v1_captioned.mp4" `
  -OutputVideo "C:\ABS\PATH\final\reel_v2_logicloom.mp4"
```

Use only the validated `_logicloom` output for Facebook, Instagram, and YouTube uploads.

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

Preflight only:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\test_reel_publish_ready.ps1 `
  -VideoPath "C:\ABS\PATH\final\reel_v2_logicloom.mp4" `
  -RequireAudio `
  -RequireLogicLoomFileName
```

## YouTube API

Use this setup guide:

- `docs/youtube-api-setup.md`

Quick upload helper:

- `scripts/youtube_upload_reel.ps1`
