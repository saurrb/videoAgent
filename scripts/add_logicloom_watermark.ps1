param(
  [Parameter(Mandatory=$true)][string]$InputVideo,
  [string]$OutputVideo = "",
  [string]$HandleText = "@logicloom",
  [ValidateSet("bottom-right")][string]$Position = "bottom-right",
  [int]$FontSize = 38,
  [int]$BoxX = 790,
  [int]$BoxY = 1800,
  [int]$BoxW = 290,
  [int]$BoxH = 120,
  [switch]$SkipValidation
)

$ErrorActionPreference = "Stop"

$repoRoot = Split-Path $PSScriptRoot -Parent
$ffmpeg = Join-Path $repoRoot "tools\ffmpeg\ffmpeg-8.1.1-essentials_build\bin\ffmpeg.exe"
$ffprobe = Join-Path $repoRoot "tools\ffmpeg\ffmpeg-8.1.1-essentials_build\bin\ffprobe.exe"

if (-not (Test-Path $ffmpeg)) { throw "ffmpeg not found: $ffmpeg" }
if (-not (Test-Path $ffprobe)) { throw "ffprobe not found: $ffprobe" }
if (-not (Test-Path $InputVideo)) { throw "Input video not found: $InputVideo" }

if ([string]::IsNullOrWhiteSpace($OutputVideo)) {
  $in = Get-Item $InputVideo
  $OutputVideo = Join-Path $in.Directory.FullName ($in.BaseName + "_logicloom.mp4")
}

# Current default coords cover the typical Grok bottom-right watermark region on 1080x1920 reels.
$drawBox = "drawbox=x=${BoxX}:y=${BoxY}:w=${BoxW}:h=${BoxH}:color=black@1.0:t=fill"
$drawText = "drawtext=font='Nunito Sans':text='${HandleText}':x=820:y=1840:fontsize=${FontSize}:fontcolor=white:borderw=4:bordercolor=black@1.0"

$vf = "$drawBox,$drawText"

& $ffmpeg -y -i $InputVideo -vf $vf -c:v libx264 -preset veryfast -crf 18 -c:a copy -movflags +faststart $OutputVideo | Out-Host

if (-not $SkipValidation) {
  $validate = Join-Path $PSScriptRoot "test_reel_publish_ready.ps1"
  & powershell -ExecutionPolicy Bypass -File $validate -VideoPath $OutputVideo -RequireLogicLoomFileName
  if ($LASTEXITCODE -ne 0) { throw "Publish-ready validation failed: $OutputVideo" }
}

Write-Output $OutputVideo
