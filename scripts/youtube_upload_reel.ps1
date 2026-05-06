param(
  [Parameter(Mandatory=$true)][string]$VideoPath,
  [Parameter(Mandatory=$true)][string]$Title,
  [string]$Description = "",
  [string]$Tags = "shorts,reels,content creation,ai video,caption sync",
  [ValidateSet("private","unlisted","public")][string]$Privacy = "private",
  [string]$TokenPath = "C:\Users\saura\Documents\youtubeVideoAgent\secrets\youtube_token.json",
  [string]$PythonExe = "C:\Users\saura\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe"
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path $PythonExe)) { throw "Python not found: $PythonExe" }
if (-not (Test-Path $TokenPath)) { throw "Token not found: $TokenPath" }
if (-not (Test-Path $VideoPath)) { throw "Video not found: $VideoPath" }

& $PythonExe ".\scripts\youtube_upload.py" `
  --token $TokenPath `
  --video $VideoPath `
  --title $Title `
  --description $Description `
  --tags $Tags `
  --privacy $Privacy
