param(
  [Parameter(Mandatory=$true)][string]$InputVideo,
  [string]$OutputVideo = "",
  [string]$LogoPath = "",
  [double]$LogoXRatio = 0.8213461538,
  [double]$LogoYRatio = 0.8962765957,
  [double]$LogoWRatio = 0.1766826923,
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
  $OutputVideo = Join-Path $in.Directory.FullName ($in.BaseName + "_playbook.mp4")
}

if ([string]::IsNullOrWhiteSpace($LogoPath)) {
  $LogoPath = Join-Path $repoRoot "assets\branding\logo_rounded_more.png"
}
if (-not (Test-Path $LogoPath)) { throw "Logo not found: $LogoPath" }

$resolvedInput = (Resolve-Path $InputVideo).Path
$probeJson = & $ffprobe -v error -print_format json -show_streams $resolvedInput
if ($LASTEXITCODE -ne 0) { throw "ffprobe failed for $resolvedInput" }
$probe = $probeJson | ConvertFrom-Json
$videoStream = $probe.streams | Where-Object { $_.codec_type -eq "video" } | Select-Object -First 1
if (-not $videoStream) { throw "No video stream found: $resolvedInput" }
$w = [int]$videoStream.width
$h = [int]$videoStream.height

$logoX = [int][Math]::Round($w * $LogoXRatio)
$logoY = [int][Math]::Round($h * $LogoYRatio)
$logoW = [int][Math]::Round($w * $LogoWRatio)

$filterComplex = "[1:v]scale=${logoW}:-1[logo];[0:v][logo]overlay=x=${logoX}:y=${logoY}:format=auto[v]"

& $ffmpeg -y -i $InputVideo -i $LogoPath -filter_complex $filterComplex -map "[v]" -map 0:a? -c:v libx264 -preset medium -crf 16 -pix_fmt yuv420p -c:a copy -movflags +faststart $OutputVideo | Out-Host

if (-not $SkipValidation) {
  $validate = Join-Path $PSScriptRoot "test_reel_publish_ready.ps1"
  & powershell -ExecutionPolicy Bypass -File $validate -VideoPath $OutputVideo -RequireBrandFileName
  if ($LASTEXITCODE -ne 0) { throw "Publish-ready validation failed: $OutputVideo" }
}

Write-Output $OutputVideo
