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
- Speechma PRO voice: Christopher
- Speechma PRO effects: Pitch=10, Speed=25, Volume=200
- Objective: Recreate the storytelling energy and pacing, not a direct copy.

## Creative Direction

- Build scene-by-scene from hook to payoff.
- Keep visuals high-detail and coherent across scenes.
- Use human-like voice and sync scene transitions to narration beats.
- Keep captions inside 9:16 safe frame at all times.

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
- Voice: Speechma PRO Christopher
- Voice effects: Pitch=10, Speed=25, Volume=200

## Automation + manual mix

1. Run setup once:
   `powershell -ExecutionPolicy Bypass -File .\scripts\setup_reel_pipeline.ps1`
2. Start new project from YouTube:
   `powershell -ExecutionPolicy Bypass -File .\scripts\start_reel_from_youtube.ps1 -YoutubeUrl "<url>" -Name "<title>"`
3. In BrowserOS, generate scene images and animations from `meta/scene_prompts_auto.md`.
4. Save outputs to `grok_outputs/` or `meta_ai_outputs/`.
5. Stitch to base reel in `final/reel_base.mp4`.
6. Run caption build using `scripts/run_caption_pipeline.ps1`.
7. Finalize publish-ready Logic Loom video:
   `powershell -ExecutionPolicy Bypass -File .\scripts\finalize_logicloom_reel.ps1 -InputVideo "ABS\PATH\final\reel_captioned.mp4"`
8. Write platform captions and US America RPM-focused hashtags in `meta/platform_caption_hashtags.md`.
9. Review screenshot samples and `test_reel_publish_ready.ps1` output before upload.
"@

Set-Content -Path $briefPath -Value $brief -Encoding UTF8
Set-Content -Path $scenePromptPath -Value $scenePrompts -Encoding UTF8
Set-Content -Path $checklistPath -Value $checklist -Encoding UTF8

Write-Output "Workspace ready: $workspace"
Write-Output "Reference video: $sourceMp4"
Write-Output "Reference audio: $sourceAudio"
Write-Output "Frames: $framesDir"
Write-Output "Contact sheet: $contactSheet"
