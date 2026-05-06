# Grok Agent Playbook (Images, Videos, Stitch)

Last updated: 2026-05-06

## Purpose

Use Grok agent mode to generate scene visuals, animate scenes, and stitch clips for 30 to 60 second reels.

## Standard Grok Flow

1. Open Grok agent and set project objective for one reel only.
2. Generate scene images first (high detail, 9:16 framing, consistent identity/style).
3. Animate each scene with explicit motion prompts.
4. Download every approved clip immediately to local workspace.
5. Stitch clips in Grok (or locally if Grok stitch output is weak).
6. Export stitched base video and continue with local caption pipeline.

## Common Challenges and Fixes

1. Wrong mode selected (image vs video vs stitch):
   - Fix: hover/inspect controls before every action and confirm active mode.
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

## File Discipline

- Save Grok outputs under reel workspace:
  - `grok_outputs/videos/`
  - `grok_outputs/stitch/`
  - `review_frames/`
- Keep best candidates only in `final/`; move rejects out of working set.
