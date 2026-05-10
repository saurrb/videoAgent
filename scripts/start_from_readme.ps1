param(
  [int]$Minutes = 1,
  [string]$Name = ""
)

$ErrorActionPreference = "Stop"

function Sanitize-Name([string]$value) {
  $v = $value.Trim().ToLowerInvariant()
  $v = $v -replace "[^a-z0-9\-_\s]", ""
  $v = $v -replace "\s+", "-"
  return $v
}

if ($Minutes -lt 1) { throw "Minutes must be >= 1." }

$targetSeconds = $Minutes * 60
$defaultName = "readme-$($Minutes)min-video"
$safeName = Sanitize-Name ($(if ([string]::IsNullOrWhiteSpace($Name)) { $defaultName } else { $Name }))

$repoRoot = Split-Path $PSScriptRoot -Parent
$newWorkspaceOutput = & powershell -ExecutionPolicy Bypass -File (Join-Path $repoRoot "scripts\new-reel-workspace.ps1") -Name $safeName
if ($LASTEXITCODE -ne 0) { throw "Failed to create workspace" }

$workspace = ($newWorkspaceOutput | Select-String -Pattern "^Created:\s+(.+)$").Matches.Groups[1].Value
if ([string]::IsNullOrWhiteSpace($workspace)) { throw "Could not parse workspace path from output: $newWorkspaceOutput" }

$briefPath = Join-Path $workspace "meta\production_brief_auto.md"
$scenePromptPath = Join-Path $workspace "meta\scene_prompts_auto.md"
$checklistPath = Join-Path $workspace "meta\run_checklist_auto.md"
$scriptPath = Join-Path $workspace "script\script_v1.txt"
$speechmaInputPath = Join-Path $workspace "voice\speechma_input_v1.txt"
$grokPromptPath = Join-Path $workspace "meta\grok_scene_prompts_v1.md"

$brief = @"
# Production Brief (Start From README)

- Workspace: $workspace
- Target duration: ~$targetSeconds sec ($Minutes minute video)
- Mode: Operator command mode (no YouTube URL required)
- Speechma PRO voice: Brian
- Speechma PRO effects: Pitch=0, Speed=25, Volume=200

## Mandatory order

1. Write script and generate Speechma voice first.
2. Enforce duration gate:
   - if target is $Minutes minute(s), voice should be close to $targetSeconds sec.
3. Only then generate Grok scene prompt pack.
4. Every scene is fixed at 6s.
5. Scene count formula: ceil(voice_seconds / 6).
6. Grok downloads path is always:
   C:\Users\saura\Downloads\grok-folder-1
"@

$scenePrompts = @"
# Scene Prompt Pack (Operator Mode)

- Global style + scene prompts must be delivered in ONE fenced copy block.
- Video mode: 9:16 vertical.
- Fixed duration per scene: 6s.
- Scene count: ceil(voice_seconds / 6).
  - ~1 min voice -> 9-10 scenes
  - ~2 min voice -> 19-20 scenes
  - ~4 min voice -> 39-40 scenes
"@

$checklist = @"
# Run Checklist (Operator Mode)

User manual inputs only:
1. "start from readme" (or "start from readme $Minutes minute video")
2. "done" after Grok scenes are generated to:
   C:\Users\saura\Downloads\grok-folder-1

After user says done:
- import/move Grok files into workspace scenes
- generate/import Speechma voice in workspace
- ensure Downloads has no Grok/Speechma trace
- stitch + captions (75% top) + branding + final QA + publish
"@

Set-Content -Path $briefPath -Value $brief -Encoding UTF8
Set-Content -Path $scenePromptPath -Value $scenePrompts -Encoding UTF8
Set-Content -Path $checklistPath -Value $checklist -Encoding UTF8

# Auto-run phase 1 outputs so this command never stops at "ready".
$sceneCount = [int][math]::Ceiling($targetSeconds / 6.0)

$script = @"
# Hook
If your relationship patterns keep hurting you, this might be the reset you need.

# Script v1 (Corey-only target: ~$targetSeconds sec)
Most people say love is complicated.
But the pattern is usually simple.
You ignore reality, then call it confusion.

Attraction is not commitment.
Chemistry is not character.
Words are not consistency.

When someone is hot and cold, believe the pattern.
When someone avoids clarity, believe the pattern.
When someone only shows up on their terms, believe the pattern.

You don't fix this by chasing harder.
You fix this by raising standards.
Slow down.
Observe behavior.
Match effort.
Set boundaries early.

If you're in breakup pain, stop negotiating attraction.
Give space.
Get your life back in order.
Body, mission, discipline, emotional control.

Confidence is not forcing outcomes.
Confidence is staying calm enough to walk away from misalignment.

Love gets easier when your self-respect gets stronger.
Protect your peace.
Master yourself.
Then choose only what is consistent, reciprocal, and clear.
"@
Set-Content -Path $scriptPath -Value $script -Encoding UTF8

& powershell -ExecutionPolicy Bypass -File (Join-Path $repoRoot "scripts\prepare_speechma_input.ps1") `
  -ScriptPath $scriptPath `
  -OutPath $speechmaInputPath | Out-Host

$grokPack = @(
  '```text',
  'GLOBAL STYLE (apply to every scene)',
  'Hand-drawn doodle animation on clean white background, black marker outlines, simple cartoon stick-figure people, colorful pastel accent shapes and text, playful psychology infographic motion, smooth 2D motion. Dynamic popping text, icons (brain, heart, chat bubble), energetic intro movement. No photorealism, no 3D render, no dark cinematic look, no characters talking, only side and background sound.',
  '',
  'RULES',
  '- Vertical 9:16',
  '- Fixed 6 seconds each scene',
  "- Total scenes: $sceneCount",
  '- Keep exact style continuity across all scenes',
  '',
  'SCENE LIST',
  "- Generate scene01 to scene$('{0:D2}' -f $sceneCount), one clip per scene id.",
  '- Keep each scene as a distinct beat in the same visual language.',
  '```'
) -join [Environment]::NewLine
Set-Content -Path $grokPromptPath -Value $grokPack -Encoding UTF8

Write-Output "Workspace ready: $workspace"
Write-Output "TargetSeconds: $targetSeconds"
Write-Output "Auto phase-1 done:"
Write-Output "- Script: $scriptPath"
Write-Output "- Speechma input: $speechmaInputPath"
Write-Output "- Grok prompt pack: $grokPromptPath"
Write-Output ""
Write-Output "MANUAL CHECKPOINT: Copy-paste this entire Grok prompt block, generate scenes to C:\Users\saura\Downloads\grok-folder-1, then reply: done"
Write-Output "-----BEGIN_GROK_PROMPT_BLOCK-----"
Get-Content -Raw $grokPromptPath | Write-Output
Write-Output "-----END_GROK_PROMPT_BLOCK-----"
