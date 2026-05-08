# Speechma Local API

Run repetitive Speechma generation with one local API call.

## Start server

```powershell
cd C:\Users\saura\Documents\youtubeVideoAgent
npm run speechma:api
```

Server: `http://127.0.0.1:8787`

## Health check

```powershell
curl http://127.0.0.1:8787/health
```

## Generate audio (single call)

```powershell
curl -X POST http://127.0.0.1:8787/speechma/run `
  -H "Content-Type: application/json" `
  -d '{
    "workspacePath": "C:\\Users\\saura\\Documents\\youtubeVideoAgent\\assets\\reels\\2026-05-08_logic-loom-dhedixy7b-q",
    "pageId": 8,
    "pitch": 0,
    "speed": 25,
    "volume": 200
  }'
```

## What it automates

1. Cleans script text for Speechma input:
`script/script_v1.txt -> voice/speechma_input_v1.txt`
2. Applies Voice Effects defaults:
`Pitch=0`, `Speed=25`, `Volume=200`, and keeps `Remember settings`.
3. Pastes narration-only text into Speechma textbox.
4. Captures proof screenshots:
`analysis/speechma_proof_api/01_speechma_input_after_write.png` and
`analysis/speechma_proof_api/02_voice_effects.png`.
5. Clicks `Generate Audio`, waits for the new row, downloads mp3, and saves:
`voice/voice_v1.mp3`
6. Returns output JSON with duration and file paths.

## Notes

- BrowserOS must be running and have an open Speechma tab.
- If `pageId` is missing or stale, the server auto-resolves a valid Speechma tab.
- If no Speechma tab exists, the server auto-opens `https://speechmapro.com`.
- If `matchPhrase` is missing, the server uses the first non-empty line from cleaned speech input.
