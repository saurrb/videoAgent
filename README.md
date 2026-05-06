# videoAgent

Starter repository for the `videoAgent` project.

## Reel Pipeline (Minimal Input)

Fastest start in a fresh tab:

`Create a reel from this YouTube link using our default pipeline: <PASTE_LINK>`

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
