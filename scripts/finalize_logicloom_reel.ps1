param(
  [Parameter(Mandatory=$true)][string]$InputVideo,
  [string]$OutputVideo = "",
  [string]$LogoPath = "",
  [int]$MinSeconds = 15,
  [int]$MaxSeconds = 65
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path $InputVideo)) { throw "Input video not found: $InputVideo" }

if ([string]::IsNullOrWhiteSpace($OutputVideo)) {
  $in = Get-Item $InputVideo
  $OutputVideo = Join-Path $in.Directory.FullName ($in.BaseName + "_playbook.mp4")
}

$watermarkScript = Join-Path $PSScriptRoot "add_logicloom_watermark.ps1"
$validateScript = Join-Path $PSScriptRoot "test_reel_publish_ready.ps1"

Write-Output "Applying Playbook branding..."
& powershell -ExecutionPolicy Bypass -File $watermarkScript `
  -InputVideo $InputVideo `
  -OutputVideo $OutputVideo `
  -LogoPath $LogoPath `
  -SkipValidation

if ($LASTEXITCODE -ne 0) { throw "Watermark step failed" }

Write-Output "Running publish-ready preflight..."
& powershell -ExecutionPolicy Bypass -File $validateScript `
  -VideoPath $OutputVideo `
  -MinSeconds $MinSeconds `
  -MaxSeconds $MaxSeconds `
  -RequireAudio `
  -RequireBrandFileName

if ($LASTEXITCODE -ne 0) { throw "Publish-ready preflight failed" }

Write-Output "PUBLISH_READY: $OutputVideo"
