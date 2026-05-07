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

## Publish-Ready Final

Use the finalizer for every reel before upload. It replaces the bottom-right Grok watermark area with `@logicloom`, then runs an `ffprobe` preflight for duration, size, stream health, audio, and Logic Loom filename.

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\finalize_logicloom_reel.ps1 `
  -InputVideo "C:\ABS\PATH\final\reel_v1_captioned.mp4" `
  -OutputVideo "C:\ABS\PATH\final\reel_v2_logicloom.mp4"
```

Use only the validated `_logicloom` output for Facebook, Instagram, and YouTube uploads.

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
