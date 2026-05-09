# Meta API Setup

Meta API posting is available in this project. Use it for publishing reels, images, and videos when the media file is available at a public HTTPS URL. Prefer API posting over BrowserOS UI posting for repeatable uploads because it is faster, less fragile, and uses fewer Codex tokens.

Discovered from the open BrowserOS Meta Business Suite tab:

- Business ID: `2769494620082352`
- Asset ID from composer URL: `1942710539310781`
- Composer account label: `Flora knows Nothing and floraknowsnothing`
- Meta app name: `Logic Loom Reel Publisher`
- Meta app ID: `1880527262622448`
- Facebook Page ID: `1942710539310781`
- Instagram account: `@floraknowsnothing`
- Instagram business account ID: `17841427733287840`

## Requirements

- A Meta developer app.
- A Facebook Page connected to the Instagram professional account.
- A public HTTPS URL for each final MP4 before publishing to Instagram.

Use these permissions for the classic Facebook Login + Instagram Graph API flow:

- `pages_show_list`
- `pages_read_engagement`
- `business_management`
- `pages_manage_posts`
- `pages_manage_metadata`
- `instagram_basic`
- `instagram_content_publish`
- `instagram_business_basic`
- `instagram_business_content_publish`

Notes:
- `pages_manage_posts` is required for create/edit/delete Page posts and reels through API.
- If OAuth returns `Invalid Scopes: pages_manage_posts`, your app configuration is not currently eligible for that permission in its current use case/product setup.
- Creating a brand-new Facebook Page is generally not available as a standard public Graph API operation for this flow. Use Meta UI for page creation, then use API for management and posting.

## OAuth

Create a Meta app at:

`https://developers.facebook.com/apps/`

Add this OAuth redirect URI:

`http://localhost:8766/`

Run OAuth:

```powershell
$py = "C:\Users\saura\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe"
& $py .\scripts\meta_oauth.py `
  --app-id "<META_APP_ID>" `
  --app-secret "<META_APP_SECRET>" `
  --token-out ".\secrets\meta_token.json"
```

Open the printed `AUTH_URL` in BrowserOS, approve the requested permissions, and select the correct Page/Instagram account.

## Check And Save Config

```powershell
$py = "C:\Users\saura\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe"
& $py .\scripts\meta_api_check.py `
  --token ".\secrets\meta_token.json" `
  --save-config ".\secrets\meta_config.json"
```

This discovers Pages, Page access tokens, and the connected Instagram business account.

## Publish Instagram Reel

The video must be a direct public HTTPS MP4 URL, not a local file path and not a Google Drive preview page.

```powershell
$py = "C:\Users\saura\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe"
& $py .\scripts\meta_publish_instagram_reel.py `
  --config ".\secrets\meta_config.json" `
  --video-url "https://example.com/final-reel.mp4" `
  --caption "Caption text #shorts #reels" `
  --share-to-feed
```

Wrapper:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\meta_publish_reel.ps1 `
  -VideoUrl "https://example.com/final-reel.mp4" `
  -Caption "Caption text #shorts #reels" `
  -ShareToFeed
```

## Publish Facebook Reel From Local MP4 (Primary)

Use the local uploader wrapper when final video exists on disk:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\meta_publish_local_reels.ps1 `
  -VideoPath "C:\ABS\PATH\final\reel_v2_logicloom.mp4" `
  -Caption "Caption text #reels" `
  -Platforms "facebook"
```

Expected successful console sequence:

- `FACEBOOK_VIDEO_ID=...`
- `FACEBOOK_STATUS=processing:... publishing:...`
- `FACEBOOK_STATUS=processing:complete publishing:complete`

## If Facebook Says Success But Reel Is Not Visible

Use this fallback publish path:

- Upload as page video through `/{page_id}/videos` with `published=true`.
- Capture and use returned `permalink_url`.

Reason: on some runs `video_reels` returns success while the reel is not surfaced immediately in page feeds.

## App Compliance Troubleshooting (Ineligible Warning)

If Developer Dashboard shows `Currently Ineligible for Submission`:

Required fields that commonly block:

- `User data deletion`
- `Category`
- `App icon (1024x1024)`

Known fixes:

1. Set values in `Settings -> Basic`.
2. In `Settings -> Advanced`, enable:
   - `Allow API Access to app settings`
3. Re-apply fields via Graph API when UI state is stale.
4. If icon upload fails:
   - use plain 1024x1024 RGB icon with stripped metadata;
   - retry in a clean browser session.
