param(
  [Parameter(Mandatory=$true)][string]$VideoPath,
  [int]$MinWidth = 1080,
  [int]$MinHeight = 1920,
  [int]$MinSeconds = 15,
  [int]$MaxSeconds = 65,
  [switch]$RequireAudio,
  [switch]$RequireLogicLoomFileName,
  [switch]$RequireBrandFileName
)

$ErrorActionPreference = "Stop"

$repoRoot = Split-Path $PSScriptRoot -Parent
$ffprobe = Join-Path $repoRoot "tools\ffmpeg\ffmpeg-8.1.1-essentials_build\bin\ffprobe.exe"

if (-not (Test-Path $ffprobe)) { throw "ffprobe not found: $ffprobe" }
if (-not (Test-Path $VideoPath)) { throw "Video not found: $VideoPath" }

$resolved = (Resolve-Path $VideoPath).Path
$json = & $ffprobe -v error -print_format json -show_format -show_streams $resolved
if ($LASTEXITCODE -ne 0) { throw "ffprobe failed for $resolved" }

$probe = $json | ConvertFrom-Json
$videoStream = $probe.streams | Where-Object { $_.codec_type -eq "video" } | Select-Object -First 1
$audioStream = $probe.streams | Where-Object { $_.codec_type -eq "audio" } | Select-Object -First 1

if (-not $videoStream) { throw "No video stream found: $resolved" }
if ($RequireAudio -and -not $audioStream) { throw "No audio stream found: $resolved" }

$duration = [double]$probe.format.duration
if ($videoStream.width -lt $MinWidth) { throw "Width $($videoStream.width) is below minimum $MinWidth" }
if ($videoStream.height -lt $MinHeight) { throw "Height $($videoStream.height) is below minimum $MinHeight" }
if ($duration -lt $MinSeconds -or $duration -gt $MaxSeconds) {
  throw "Duration $([math]::Round($duration, 2))s is outside ${MinSeconds}-${MaxSeconds}s"
}

if ($RequireLogicLoomFileName -or $RequireBrandFileName) {
  $name = [System.IO.Path]::GetFileNameWithoutExtension($resolved).ToLowerInvariant()
  if ($name -notmatch "logicloom|logic-loom|logic_loom|playbook|relationship-playbook|relationship_playbook") {
    throw "Final filename must include logicloom or playbook branding token: $resolved"
  }
}

[PSCustomObject]@{
  video = $resolved
  durationSeconds = [math]::Round($duration, 2)
  width = [int]$videoStream.width
  height = [int]$videoStream.height
  videoCodec = $videoStream.codec_name
  audioCodec = if ($audioStream) { $audioStream.codec_name } else { "" }
  publishReady = $true
} | ConvertTo-Json
