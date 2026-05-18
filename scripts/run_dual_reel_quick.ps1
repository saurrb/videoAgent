param(
  [string]$SourceDir = "C:\Users\saura\Downloads\grok-folder-1",
  [string]$Topic = "",
  [string]$Logo = "logo1",
  [string]$LogoPath = "",
  [switch]$RequireBrandValidation
)

$ErrorActionPreference = "Stop"

$projectRoot = Split-Path $PSScriptRoot -Parent
$date = Get-Date -Format "yyyy-MM-dd"
$hour = Get-Date -Format "HH"
$minuteStamp = Get-Date -Format "mm"
$topicValue = if ([string]::IsNullOrWhiteSpace($Topic)) { $minuteStamp } else { $Topic }
$reelRoot = Join-Path $projectRoot "assets\reels\$date`_${hour}h`_${topicValue}m"

if ([string]::IsNullOrWhiteSpace($LogoPath)) {
  $logosDir = Join-Path $projectRoot "assets\branding\logos"
  $logoFile = if ([System.IO.Path]::GetExtension($Logo)) { $Logo } else { "$Logo.png" }
  $candidate = Join-Path $logosDir $logoFile
  if (-not (Test-Path $candidate)) {
    throw "Logo not found: $candidate. Use -Logo logo1/logo2... or pass -LogoPath."
  }
  $LogoPath = $candidate
}

$cmd = @(
  "-ExecutionPolicy", "Bypass",
  "-File", (Join-Path $projectRoot "scripts\build_dual_output_reel.ps1"),
  "-Topic", $topicValue,
  "-SourceDir", $SourceDir,
  "-ReelRoot", $reelRoot,
  "-LogoPath", $LogoPath
)

# Default: skip strict publish validation so low-res drafts (e.g., 416x752) still finish.
if (-not $RequireBrandValidation) {
  $cmd += "-SkipBrandValidation"
}

& powershell @cmd | Out-Host
if ($LASTEXITCODE -ne 0) {
  throw "build_dual_output_reel.ps1 failed with exit code $LASTEXITCODE"
}

$finalDir = Join-Path $reelRoot "final"
if (Test-Path $finalDir) {
  Start-Process explorer.exe $finalDir
}
