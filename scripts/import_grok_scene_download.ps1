param(
  [Parameter(Mandatory = $true)][string]$Workspace,
  [int]$SceneNumber
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path $Workspace)) {
  throw "Workspace not found: $Workspace"
}

$scenesDir = Join-Path $Workspace "scenes"
if (-not (Test-Path $scenesDir)) {
  New-Item -ItemType Directory -Path $scenesDir -Force | Out-Null
}

$downloadsDir = Join-Path $env:USERPROFILE "Downloads"
$latest = Get-ChildItem $downloadsDir -Filter "grok-*.mp4" -File |
  Sort-Object LastWriteTime -Descending |
  Select-Object -First 1

if (-not $latest) {
  throw "No grok-*.mp4 found in Downloads."
}

if (-not $SceneNumber) {
  $existing = Get-ChildItem $scenesDir -Filter "scene*.mp4" -File
  $SceneNumber = $existing.Count + 1
}

$targetName = ("scene{0:D2}.mp4" -f $SceneNumber)
$targetPath = Join-Path $scenesDir $targetName
Move-Item -LiteralPath $latest.FullName -Destination $targetPath -Force

Write-Output "Imported: $($latest.FullName)"
Write-Output "Moved to: $targetPath"
