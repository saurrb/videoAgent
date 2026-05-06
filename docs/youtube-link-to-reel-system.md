# YouTube Link -> Reel System (Production Playbook)

Last updated: 2026-05-06

This document captures what we learned end-to-end: bottlenecks we hit, what fixed them, and the repeatable workflow for creating a reel/short from a YouTube reference with minimal user input.

## 1) Minimal Input Contract

For next runs, you only need to provide:

1. YouTube link
2. Reel name (short slug)
3. Optional voice preference

Everything else follows this playbook.

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

## 5) Production Flow (Repeatable)

1. Analyze reference pacing from extracted frames/contact sheet.
2. Write script with hook-first structure (first 1-2 seconds).
3. Generate voice (prefer stable, human-like voice).
4. Create scene prompts per beat (image prompt + animation prompt).
5. Generate scene clips in Meta AI / Grok via BrowserOS.
6. Stitch clips to narration timing.
7. Add word-level timed captions using repo scripts.
8. Run screenshot QA at multiple timestamps.
9. Iterate until quality target is met.

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

- generation inside Meta AI / Grok / ElevenLabs
- choosing best takes
- platform posting approvals

## 10) Fast Start for Future Requests

When you give a new YouTube link, we should do exactly:

1. Run `start_reel_from_youtube.ps1`
2. Fill scene prompts from the generated brief
3. Generate clips + voice
4. Stitch + caption pipeline
5. Iterative screenshot QA
6. Final export in `final/`

That gives near-minimal-input reel creation from here forward.
