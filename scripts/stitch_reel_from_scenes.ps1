param(
  [Parameter(Mandatory = $true)][string]$Workspace,
  [int]$Scenes = 10,
  [string]$VoicePath = "",
  [string]$OutVideo = ""
)

$ErrorActionPreference = "Stop"

$repoRoot = Split-Path $PSScriptRoot -Parent
$ffmpeg = Join-Path $repoRoot "tools\ffmpeg\ffmpeg-8.1.1-essentials_build\bin\ffmpeg.exe"
$ffprobe = Join-Path $repoRoot "tools\ffmpeg\ffmpeg-8.1.1-essentials_build\bin\ffprobe.exe"

if (-not (Test-Path $ffmpeg)) { throw "ffmpeg not found: $ffmpeg" }
if (-not (Test-Path $ffprobe)) { throw "ffprobe not found: $ffprobe" }
if (-not (Test-Path $Workspace)) { throw "Workspace not found: $Workspace" }

$scenesDir = Join-Path $Workspace "scenes"
$voiceDir = Join-Path $Workspace "voice"
$finalDir = Join-Path $Workspace "final"
$editDir = Join-Path $Workspace "edit"
New-Item -ItemType Directory -Path $finalDir -Force | Out-Null
New-Item -ItemType Directory -Path $editDir -Force | Out-Null

if ([string]::IsNullOrWhiteSpace($VoicePath)) {
  $VoicePath = Join-Path $voiceDir "voice_v1.mp3"
}
if ([string]::IsNullOrWhiteSpace($OutVideo)) {
  $OutVideo = Join-Path $finalDir "reel_base.mp4"
}
if (-not (Test-Path $VoicePath)) { throw "Voice not found: $VoicePath" }

$concatPath = Join-Path $editDir "scenes_concat.txt"
$lines = @()
for ($i = 1; $i -le $Scenes; $i++) {
  $name = ("scene{0:D2}.mp4" -f $i)
  $p = Join-Path $scenesDir $name
  if (-not (Test-Path $p)) { throw "Missing scene: $p" }
  $abs = [System.IO.Path]::GetFullPath($p) -replace "'", "''"
  $lines += "file '$abs'"
}
Set-Content -Path $concatPath -Value ($lines -join "`n") -Encoding UTF8

$tmpVideo = Join-Path $editDir "_scenes_concat.mp4"
& $ffmpeg -y -f concat -safe 0 -i $concatPath -c copy $tmpVideo | Out-Host
& $ffmpeg -y -i $tmpVideo -i $VoicePath -c:v copy -c:a aac -b:a 192k -shortest $OutVideo | Out-Host

$dur = & $ffprobe -v error -show_entries format=duration -of default=nw=1:nk=1 $OutVideo
Write-Output "DONE: $OutVideo"
Write-Output "DURATION: $dur"
