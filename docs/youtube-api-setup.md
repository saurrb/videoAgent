# YouTube API Setup (Upload)

## 1) Enable API in Google Cloud

1. Open Google Cloud Console.
2. Create/select a project.
3. Enable **YouTube Data API v3**.
4. Configure OAuth consent screen (External is fine for personal use).
5. Create OAuth client ID:
   - Type: **Desktop app**
6. Download client secrets JSON.

Save it locally, for example:

`C:\Users\saura\Documents\youtubeVideoAgent\secrets\youtube_client_secret.json`

## 2) Install dependencies

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\setup_youtube_api.ps1
```

## 3) Run OAuth once

```powershell
C:\Users\saura\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe .\scripts\youtube_oauth_auth.py `
  --client-secrets "C:\Users\saura\Documents\youtubeVideoAgent\secrets\youtube_client_secret.json" `
  --token-out "C:\Users\saura\Documents\youtubeVideoAgent\secrets\youtube_token.json"
```

This opens browser auth and saves token.

Important:

- If Google shows account/channel chooser, select the YouTube channel identity you want to upload from (for example your Brand Channel), not only base Gmail profile.
- If upload later fails with `youtubeSignupRequired`, delete `secrets\youtube_token.json`, run OAuth again, and pick the channel identity.

## 4) Upload a video

Optional health check before uploading:

```powershell
C:\Users\saura\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe .\scripts\youtube_api_check.py `
  --token "C:\Users\saura\Documents\youtubeVideoAgent\secrets\youtube_token.json"
```

```powershell
C:\Users\saura\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe .\scripts\youtube_upload.py `
  --token "C:\Users\saura\Documents\youtubeVideoAgent\secrets\youtube_token.json" `
  --video "C:\ABS\PATH\final\reel_v1.mp4" `
  --title "My Reel Title" `
  --description "Short description" `
  --tags "reels,shorts,ai" `
  --privacy private
```

The script prints final YouTube URL.

## 5) Quick Upload Wrapper (Recommended)

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\youtube_upload_reel.ps1 `
  -VideoPath "C:\ABS\PATH\final\reel_v1.mp4" `
  -Title "My Reel Title" `
  -Description "My reel description" `
  -Privacy public
```

## Notes

- Keep `secrets/` out of git.
- First upload can take time due to resumable transfer.
- Use `private` or `unlisted` while testing.
