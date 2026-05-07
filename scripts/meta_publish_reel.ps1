param(
  [Parameter(Mandatory=$true)][string]$VideoUrl,
  [string]$Caption = "",
  [string]$ConfigPath = "C:\Users\saura\Documents\youtubeVideoAgent\secrets\meta_config.json",
  [string]$PythonExe = "C:\Users\saura\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe",
  [switch]$ShareToFeed
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path $PythonExe)) { throw "Python not found: $PythonExe" }
if (-not (Test-Path $ConfigPath)) { throw "Meta config not found: $ConfigPath" }
if ($VideoUrl -notmatch '^https://') { throw "VideoUrl must be a public HTTPS URL to the MP4 file." }

$argsList = @(
  ".\scripts\meta_publish_instagram_reel.py",
  "--config", $ConfigPath,
  "--video-url", $VideoUrl,
  "--caption", $Caption
)

if ($ShareToFeed) {
  $argsList += "--share-to-feed"
}

& $PythonExe @argsList
