param(
  [string]$DownloadsDir = "$env:USERPROFILE\Downloads"
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path $DownloadsDir)) {
  throw "Downloads directory not found: $DownloadsDir"
}

$patterns = @(
  "speechma_audio_*.mp3",
  "grok-*.mp4",
  "*_grok-video-*.mp4"
)

$removed = @()
foreach ($p in $patterns) {
  $files = Get-ChildItem -Path $DownloadsDir -Filter $p -File -ErrorAction SilentlyContinue
  foreach ($f in $files) {
    Remove-Item -LiteralPath $f.FullName -Force
    $removed += $f.FullName
  }
}

Write-Output "Removed files: $($removed.Count)"
foreach ($r in $removed) {
  Write-Output $r
}
