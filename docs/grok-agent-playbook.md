# Grok Agent Playbook (Images, Videos, Stitch)

Last updated: 2026-05-07

## Purpose

Use Grok agent mode to generate scene visuals, animate scenes, and stitch clips for 30 to 60 second reels.

## Standard Grok Flow

1. Open a fresh new browser tab for `https://grok.com/imagine`.
2. Click `Agent (Beta)` in the bottom prompt controls.
3. Start with `Empty Canvas` before entering any reel prompt.
4. Set generation controls before each run:
   - mode: `Video`
   - quality: `480p` for fast drafts, `720p` for approved finals
   - duration: `6s` or `10s` to match the scene beat
   - aspect ratio: `9:16 Vertical`
5. Set project objective for one reel only.
6. Generate scene images first when identity/style needs to be locked; otherwise generate scene videos directly from the beat prompt.
7. Animate each scene with explicit motion prompts.
8. Download every approved clip immediately to local workspace.
9. Stitch clips in Grok (or locally if Grok stitch output is weak).
10. Export stitched base video and continue with local caption pipeline.

## Timed Generation Protocol (Mandatory)

Use explicit timers after every Grok submit so we avoid random waiting/clicking.

- Image generation wait window: start at `45s`, hard timeout `120s`
- Video generation wait window (6-10s clips): start at `90s`, hard timeout `240s`
- Stitch generation wait window: start at `180s`, hard timeout `420s`

Rules:

1. Start timer immediately after clicking generate/send.
2. Do not click extra controls while timer is running unless there is a visible error.
3. At soft wait (`45s/90s/180s`), check canvas state and capture screenshot.
4. If still running, re-check every `20s` until hard timeout.
5. At hard timeout, run recovery rule (new tab -> Agent -> last canvas check) before retrying.

## Batch Prompt Protocol (Faster Throughput)

When style is already locked, request multiple scene clips in one Grok message:

1. In one prompt, ask for `scene02`, `scene03`, `scene04` with clear per-scene durations and style anchors.
2. Require separate outputs per scene (`one clip per scene id`).
3. After results appear, download/import each scene one-by-one using the in-canvas card action row.
4. Keep strict naming: `scene02.mp4`, `scene03.mp4`, `scene04.mp4`.

## Visibility and Screenshot Rule

Grok work must be visible to the user while it is happening.

- Always create a new Grok tab for a new reel/canvas.
- Keep the active working Grok tab selected/in front before typing prompts, clicking controls, generating, reviewing, or downloading.
- Take screenshots between major steps:
  - fresh Grok tab opened
  - `Agent (Beta)` selected
  - `Empty Canvas` opened
  - generation controls verified
  - prompt entered before submit
  - generation result visible
  - download/result state visible
- Store these screenshots in the reel workspace `analysis/` folder with clear names like `grok_scene01_before_submit.png`.
- If the user interrupts and asks what is happening, show or reference the latest screenshot before continuing.
- If a generated video opens in a separate `assets.grok.com` tab (or any media-only tab), use it only for quick inspection and immediately return to the active Grok canvas tab before any next action.
- Do not continue prompting, reviewing, or troubleshooting from media-only tabs.
- In Grok canvas view, click the generated video card itself to expose its action row. Use that in-canvas row for download/export actions.
- Before download clicks, use the bottom-left canvas zoom controls (`+` / `-`) to frame the full card and ensure the action row is visible.

## Non-Negotiable Asset Rule

Grok browser visibility is not enough. A scene is usable only after the actual generated MP4 has been downloaded to the reel workspace.

Forbidden substitutes:

- browser screenshots
- cropped canvas screenshots
- preview thumbnails
- contact sheets
- still-image slideshows made from Grok previews
- screen recordings of the browser unless the user explicitly approves that emergency fallback

If Grok generates a clip but the MP4 cannot be downloaded because of auth, 403, UI limitations, or missing download controls, stop and report a blocker. Do not manufacture a lower-quality local replacement.

## Required Entry Path

Do not type prompts into the default public Imagine feed.

Use this path every time:

1. New tab: `https://grok.com/imagine`
2. `Agent (Beta)`
3. `Empty Canvas`
4. `Video`
5. `9:16 Vertical`
6. prompt for the current scene only

## Common Challenges and Fixes

1. Wrong mode selected (image vs video vs stitch):
   - Fix: enter through `Agent (Beta)` -> `Empty Canvas`, then hover/inspect controls before every action and confirm active mode.
2. Character/style drift between scenes:
   - Fix: reuse the same identity descriptor and style anchors in every scene prompt.
3. Motion is too weak or too chaotic:
   - Fix: prompt camera motion and subject motion separately; keep one dominant movement.
4. Scene does not match narration:
   - Fix: scene prompts must be built from the exact script line/beat timing.
5. Stitch output exceeds or misses target duration:
   - Fix: trim/reorder clips by beat timing; enforce duration per scene before stitching.
6. Long stitch jobs fail or hang:
   - Fix: stitch in batches, then final combine locally with ffmpeg.
7. Download confusion or missing outputs:
   - Fix: download right after each success and use strict scene filenames.
8. Quality inconsistency across attempts:
   - Fix: iterative loop with screenshot review and regenerate only weak scenes.

## Browser Recovery Rule

When Grok is confusing, slow, or appears broken, do not keep clicking through the current tab.

1. Take a screenshot of the current state.
2. Open a new browser tab for `https://grok.com/imagine` and keep it in front.
3. Enter through `Imagine` -> `Agent (Beta)`.
4. Check with screenshots whether the last canvas is available and usable.
5. If the last canvas is usable, continue from it.
6. If the last canvas is missing, corrupted, or stuck, start a fresh `Empty Canvas`.
7. Screenshot each recovery step before submitting new prompts or generation actions.
8. If recovery opened any non-canvas media tabs, switch back to the working Grok canvas tab and keep it in front.

This recovery sequence must happen before declaring Grok unusable, and before any fallback to another generator.

## Iterative Checkpoints (Required)

For each phase, capture screenshots and verify:

1. Prompt phase: scene prompts match script lines.
2. Generation phase: output matches visual intent.
3. Stitch phase: transitions and pacing align with voice.
4. Final phase: no weak scene remains before captioning.

## Fallback Rules

1. If Grok animation underperforms for a scene, regenerate in Meta AI with same beat prompt.
2. If Grok stitch fails repeatedly, stitch locally with ffmpeg concat.
3. If a scene is still weak after 3 retries, replace that scene concept (not only wording).
4. Fallbacks must still produce actual animated video clips. Still images or screenshots are not acceptable fallback assets.

## File Discipline

- Save Grok outputs under reel workspace:
  - `grok_outputs/videos/`
  - `grok_outputs/stitch/`
  - `review_frames/`
- Keep best candidates only in `final/`; move rejects out of working set.
