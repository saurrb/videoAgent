# Run Checklist (Minimal Input Workflow)

## Inputs you provide

- YouTube link
- Reel theme title (2-4 words)
- Voice: Speechma PRO Brian
- Voice effects: Pitch=0, Speed=25, Volume=200

## Automation + manual mix

1. Run setup once:
   powershell -ExecutionPolicy Bypass -File .\scripts\setup_reel_pipeline.ps1
2. Start new project from YouTube:
   powershell -ExecutionPolicy Bypass -File .\scripts\start_reel_from_youtube.ps1 -YoutubeUrl "<url>" -Name "<title>"
3. In Speechma PRO (BrowserOS tab), apply default effects before generating any narration:
   powershell -ExecutionPolicy Bypass -File .\scripts\speechma_apply_defaults.ps1 -PageId 1 -Pitch 0 -Speed 25 -Volume 200
4. Open Grok in a fresh new tab for this reel, keep the working tab in front, then enter Imagine -> Agent (Beta) -> Empty Canvas.
5. Take screenshots between: new tab, Agent (Beta), Empty Canvas, controls verified, prompt before submit, generated result, and download state.
6. If a generated clip opens in a media-only tab, inspect quickly and return immediately to the working Grok canvas tab before continuing.
7. In Grok canvas, click the generated video card first to reveal its in-canvas action row, then click download from that row.
8. Use bottom-left zoom + / - controls so the full video card and action row are visible before download.
9. Start a timer immediately after each Grok generate/send:
   - image: soft 45s, hard 120s
   - video: soft 90s, hard 240s
   - stitch: soft 180s, hard 420s
   Timer helper:
   powershell -ExecutionPolicy Bypass -File .\scripts\wait_for_grok_generation.ps1 -Type video -Since (Get-Date) -Workspace "ABS\PATH\assets\reels\YYYY-MM-DD_name" -SceneNumber 2
10. In BrowserOS, generate scene images and animations from meta/scene_prompts_auto.md.
11. Once style is stable, batch prompt 2-3 scenes in one Grok message (example: scene02-scene04), then download/import each output with strict scene numbering.
12. Save outputs to grok_outputs/ or meta_ai_outputs/.
13. Stitch to base reel in inal/reel_base.mp4.
14. Run caption build using scripts/run_caption_pipeline.ps1.
15. Finalize publish-ready Logic Loom video:
   powershell -ExecutionPolicy Bypass -File .\scripts\finalize_logicloom_reel.ps1 -InputVideo "ABS\PATH\final\reel_captioned.mp4"
16. Write platform captions and US America RPM-focused hashtags in meta/platform_caption_hashtags.md.
17. Review screenshot samples and 	est_reel_publish_ready.ps1 output before upload.
