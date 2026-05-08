param(
  [Parameter(Mandatory = $true)][string]$YoutubeUrl,
  [Parameter(Mandatory = $true)][string]$Name,
  [int]$TargetSeconds = 40
)

$ErrorActionPreference = "Stop"

function Sanitize-Name([string]$value) {
  $v = $value.Trim().ToLowerInvariant()
  $v = $v -replace "[^a-z0-9\-_\s]", ""
  $v = $v -replace "\s+", "-"
  return $v
}

$repoRoot = Split-Path $PSScriptRoot -Parent
$ytDlp = Join-Path $repoRoot "tools\yt-dlp\yt-dlp.exe"
$ffmpeg = Join-Path $repoRoot "tools\ffmpeg\ffmpeg-8.1.1-essentials_build\bin\ffmpeg.exe"
$ffmpegDir = Split-Path $ffmpeg -Parent

if (-not (Test-Path $ytDlp)) { throw "Missing yt-dlp at $ytDlp" }
if (-not (Test-Path $ffmpeg)) { throw "Missing ffmpeg at $ffmpeg" }

$safe = Sanitize-Name $Name

$newWorkspaceOutput = & powershell -ExecutionPolicy Bypass -File (Join-Path $repoRoot "scripts\new-reel-workspace.ps1") -Name $safe
if ($LASTEXITCODE -ne 0) { throw "Failed to create workspace" }

$workspace = ($newWorkspaceOutput | Select-String -Pattern "^Created:\s+(.+)$").Matches.Groups[1].Value
if ([string]::IsNullOrWhiteSpace($workspace)) { throw "Could not parse workspace path from output: $newWorkspaceOutput" }

$referenceDir = Join-Path $workspace "reference"
$analysisDir = Join-Path $workspace "analysis"
$framesDir = Join-Path $analysisDir "frames"
New-Item -ItemType Directory -Path $referenceDir -Force | Out-Null
New-Item -ItemType Directory -Path $framesDir -Force | Out-Null

$sourceMp4 = Join-Path $referenceDir "source.mp4"
$sourceAudio = Join-Path $referenceDir "source_audio.m4a"

Write-Output "Downloading reference video..."
& $ytDlp --ffmpeg-location $ffmpegDir -f "bv*+ba/b" --merge-output-format mp4 -o $sourceMp4 $YoutubeUrl | Out-Host
if (-not (Test-Path $sourceMp4)) { throw "Reference video not downloaded." }

Write-Output "Downloading best audio..."
& $ytDlp --ffmpeg-location $ffmpegDir -f "ba" -o $sourceAudio $YoutubeUrl | Out-Host

Write-Output "Extracting timeline frames..."
& $ffmpeg -y -i $sourceMp4 -vf "fps=1/2,scale=540:-2" (Join-Path $framesDir "f%03d.jpg") | Out-Host

$contactSheet = Join-Path $analysisDir "contact_sheet.jpg"
& $ffmpeg -y -framerate 1 -i (Join-Path $framesDir "f%03d.jpg") -frames:v 1 -vf "tile=4x4:padding=10:margin=10" -update 1 $contactSheet | Out-Host

$briefPath = Join-Path $workspace "meta\production_brief_auto.md"
$scenePromptPath = Join-Path $workspace "meta\scene_prompts_auto.md"
$checklistPath = Join-Path $workspace "meta\run_checklist_auto.md"

$brief = @"
# Production Brief (Auto Seed)

- Source URL: $YoutubeUrl
- Workspace: $workspace
- Target duration: $TargetSeconds sec
- Speechma PRO voice: Brian
- Speechma PRO effects: Pitch=0, Speed=25, Volume=200
- Objective: Recreate the storytelling energy and pacing, not a direct copy.

## Creative Direction

- Build scene-by-scene from hook to payoff.
- Keep visuals high-detail and coherent across scenes.
- Use human-like voice and sync scene transitions to narration beats.
- Keep captions inside 9:16 safe frame at all times.
- Write scripts in the Logic Loom retention style:
  - danger/tension hook in the first 1-2 seconds
  - short 3-8 word lines
  - pattern interrupts like "Watch closely."
  - 3-pattern structure when the topic supports it
  - final reversal that reframes the hook

## Default Script Style Example

The most dangerous person in the room
is usually the one who thinks
they are the smartest.

Psychology has a name for this.

The less people understand,
the more certain they sound.

No doubt.
No hesitation.
No self-questioning.

Just confidence.

And people mistake that confidence
for intelligence.

## Iteration Loop (Required)

1. Generate script and voice.
2. Create scene prompts (image first, then animate).
3. Produce clips in Meta AI and/or Grok.
4. Stitch clips and align with voice timing.
5. Run caption pipeline with word-level highlights.
6. Take 8 timeline screenshots and inspect:
   - caption in-frame
   - active word timing
   - visual intensity
   - transition quality
7. Refine and repeat until quality target is met.
"@

$scenePrompts = @"
# Scene Prompt Pack (Fill and Use)

For each scene:

- Scene ID:
- Duration target:
- Hook line:
- Image prompt (hyper-detailed, cinematic, 9:16):
- Animation prompt (camera motion + subject motion + lighting change):
- Negative prompt:
- Output file:

Recommended shape: 6 to 10 scenes for a 35 to 60 second reel.
"@

$checklist = @"
# Run Checklist (Minimal Input Workflow)

## Inputs you provide

- YouTube link
- Reel theme title (2-4 words)
- Voice: Speechma PRO Brian
- Voice effects: Pitch=0, Speed=25, Volume=200

## Automation + manual mix

1. Run setup once:
   `powershell -ExecutionPolicy Bypass -File .\scripts\setup_reel_pipeline.ps1`
2. Start new project from YouTube:
   `powershell -ExecutionPolicy Bypass -File .\scripts\start_reel_from_youtube.ps1 -YoutubeUrl "<url>" -Name "<title>"`
3. Open Grok in a fresh new tab for this reel, keep the working tab in front, then enter `Imagine -> Agent (Beta) -> Empty Canvas`.
4. Take screenshots between: new tab, Agent (Beta), Empty Canvas, controls verified, prompt before submit, generated result, and download state.
5. If a generated clip opens in a media-only tab, inspect quickly and return immediately to the working Grok canvas tab before continuing.
6. In Grok canvas, click the generated video card first to reveal its in-canvas action row, then click download from that row.
7. Use bottom-left zoom `+ / -` controls so the full video card and action row are visible before download.
8. Start a timer immediately after each Grok generate/send:
   - image: soft `45s`, hard `120s`
   - video: soft `90s`, hard `240s`
   - stitch: soft `180s`, hard `420s`
   Timer helper:
   `powershell -ExecutionPolicy Bypass -File .\scripts\wait_for_grok_generation.ps1 -Type video -Since (Get-Date) -Workspace "ABS\PATH\assets\reels\YYYY-MM-DD_name" -SceneNumber 2`
9. In BrowserOS, generate scene images and animations from `meta/scene_prompts_auto.md`.
10. Once style is stable, batch prompt 2-3 scenes in one Grok message (example: scene02-scene04), then download/import each output with strict scene numbering.
11. Save outputs to `grok_outputs/` or `meta_ai_outputs/`.
12. Stitch to base reel in `final/reel_base.mp4`.
13. Run caption build using `scripts/run_caption_pipeline.ps1`.
14. Finalize publish-ready Logic Loom video:
   `powershell -ExecutionPolicy Bypass -File .\scripts\finalize_logicloom_reel.ps1 -InputVideo "ABS\PATH\final\reel_captioned.mp4"`
15. Write platform captions and US America RPM-focused hashtags in `meta/platform_caption_hashtags.md`.
16. Review screenshot samples and `test_reel_publish_ready.ps1` output before upload.
"@

Set-Content -Path $briefPath -Value $brief -Encoding UTF8
Set-Content -Path $scenePromptPath -Value $scenePrompts -Encoding UTF8
Set-Content -Path $checklistPath -Value $checklist -Encoding UTF8

Write-Output "Workspace ready: $workspace"
Write-Output "Reference video: $sourceMp4"
Write-Output "Reference audio: $sourceAudio"
Write-Output "Frames: $framesDir"
Write-Output "Contact sheet: $contactSheet"
