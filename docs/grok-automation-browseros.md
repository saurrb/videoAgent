# Grok Automation + BrowserOS (Practical Workflow)

## Status

Extension side-panel automation is deprecated for this project.
Use the old Grok method as default:

1. Open `https://grok.com/imagine`
2. `Agent (Beta)` -> `Empty Canvas`
3. Manual/DOM prompt submit on Grok page
4. Download scene MP4s from Grok canvas cards

Do not rely on extension panel control in this repo workflow.

This workflow is based on the official guide:
`https://github.com/trgkyle/grok-automation-user-guide`

## What we confirmed from the guide

1. The extension works only on `grok.com/imagine`.
2. Prompt batches are separated by blank lines.
3. Text-to-Video mode is the right mode for reel scene clip generation.
4. Random Delay and Concurrent Prompts are key controls for safe queueing.
5. Download organization is handled by extension settings (folder + auto rename).

## BrowserOS constraint in this environment

In this setup, BrowserOS can control the Grok page DOM, but it does not reliably expose the Chrome extension side panel DOM.
Because of that, full click-automation of extension panel buttons is not stable from BrowserOS CLI.

## Implemented runner

Use `scripts/grok_submit_batch_browseros.ps1` to automate prompt submission on Grok itself (DOM-level):

- Parses prompt blocks from a `.txt` file (blank-line separated).
- Filters blocks (default pattern targets scene output blocks).
- Forces common controls (`Video`, `9:16`, `6s`, `480p`) best-effort.
- Submits prompts with random delay (same concept as extension Random Delay).

### Dry run

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\grok_submit_batch_browseros.ps1 `
  -PromptFile "C:\Users\saura\Documents\youtubeVideoAgent\assets\reels\2026-05-08_logic-loom-dhedixy7b-q\meta\grok_automation_prompts_v1.txt" `
  -PageId 2 `
  -DryRun
```

### Live run

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\grok_submit_batch_browseros.ps1 `
  -PromptFile "C:\Users\saura\Documents\youtubeVideoAgent\assets\reels\2026-05-08_logic-loom-dhedixy7b-q\meta\grok_automation_prompts_v1.txt" `
  -PageId 2 `
  -StartIndex 1 `
  -MaxPrompts 9 `
  -DelayMinSeconds 20 `
  -DelayMaxSeconds 30
```

## Recommended pair with download automation

Run this in a second terminal while generation is happening:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\monitor_grok_downloads.ps1 `
  -Workspace "C:\Users\saura\Documents\youtubeVideoAgent\assets\reels\2026-05-08_logic-loom-dhedixy7b-q" `
  -StartScene 1 -Count 9
```

This keeps `scene01.mp4 ... scene09.mp4` mapped into the reel workspace as files arrive.

## Mandatory Completion Check (Do Not Skip)

Before moving to stitch/captions/final:

1. Open the Grok Automation panel queue view.
2. Take a final screenshot of the queue status.
3. Confirm all required prompts for the group are `Completed 100%`.
4. Confirm there are no rows in `Running`, `Retrying`, or `Pending`.

If any prompt is still retrying/pending/running, continue waiting/retry handling and do not proceed.

## Option 3: Side panel UI automation (AutoHotkey) [Deprecated]

This path is no longer recommended for this project and is kept only as historical reference.

### 1) Calibrate once per machine/layout

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\grok_extension_calibrate.ps1 `
  -WindowTitle "Imagine Agent Mode - Grok" `
  -ConfigPath ".\config\grok_extension_ui.json"
```

### 2) Run batch submission via side panel clicks

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\grok_extension_run_ui.ps1 `
  -PromptFile "C:\Users\saura\Documents\youtubeVideoAgent\assets\reels\2026-05-08_logic-loom-dhedixy7b-q\meta\grok_automation_prompts_v1.txt" `
  -ConfigPath ".\config\grok_extension_ui.json" `
  -StartIndex 1 `
  -MaxPrompts 9 `
  -DelayMinSeconds 20 `
  -DelayMaxSeconds 30
```

### 3) Pair with auto-import

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\monitor_grok_downloads.ps1 `
  -Workspace "C:\Users\saura\Documents\youtubeVideoAgent\assets\reels\2026-05-08_logic-loom-dhedixy7b-q" `
  -StartScene 1 -Count 9
```

### Notes

- Requires AutoHotkey v2 installed.
- Keep Chromium focused on Grok while automation is running.
- If layout/zoom changes, rerun calibration.
