param(
  [Parameter(Mandatory=$true)][string]$VideoPath,
  [Parameter(Mandatory=$true)][string]$Caption,
  [string]$Platforms = "facebook,instagram",
  [string]$ConfigPath = "C:\Users\saura\Documents\youtubeVideoAgent\secrets\meta_config.json",
  [string]$PythonExe = "C:\Users\saura\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe",
  [switch]$ShareToFeed
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path $PythonExe)) { throw "Python not found: $PythonExe" }
if (-not (Test-Path $ConfigPath)) { throw "Meta config not found: $ConfigPath" }
if (-not (Test-Path $VideoPath)) { throw "Video not found: $VideoPath" }

$argsList = @(
  ".\scripts\meta_publish_local_reels.py",
  "--config", $ConfigPath,
  "--video", $VideoPath,
  "--caption", $Caption,
  "--platforms", $Platforms
)

if ($ShareToFeed) {
  $argsList += "--share-to-feed"
}

& $PythonExe @argsList
