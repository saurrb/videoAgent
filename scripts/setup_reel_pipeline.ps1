param(
  [string]$PythonExe = "C:\Users\saura\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe",
  [switch]$SkipNpm
)

$ErrorActionPreference = "Stop"

$repoRoot = Split-Path $PSScriptRoot -Parent
$ytDlp = Join-Path $repoRoot "tools\yt-dlp\yt-dlp.exe"
$ffmpeg = Join-Path $repoRoot "tools\ffmpeg\ffmpeg-8.1.1-essentials_build\bin\ffmpeg.exe"
$browserCli = Join-Path $repoRoot "node_modules\.bin\browseros-cli.cmd"

Write-Output "Checking core binaries..."
if (-not (Test-Path $ytDlp)) { throw "Missing yt-dlp at $ytDlp" }
if (-not (Test-Path $ffmpeg)) { throw "Missing ffmpeg at $ffmpeg" }

if (-not $SkipNpm) {
  Write-Output "Installing npm dependencies..."
  npm install | Out-Host
}

if (-not (Test-Path $browserCli)) {
  Write-Output "Installing browseros-cli..."
  npm install browseros-cli --save-dev | Out-Host
}

if (-not (Test-Path $PythonExe)) {
  throw "Python not found at $PythonExe"
}

Write-Output "Installing Python dependencies..."
& $PythonExe -m pip install --upgrade pip | Out-Host
& $PythonExe -m pip install faster-whisper srt | Out-Host

Write-Output "Setup complete."
Write-Output "yt-dlp: $ytDlp"
Write-Output "ffmpeg: $ffmpeg"
Write-Output "browseros-cli: $browserCli"
Write-Output "python: $PythonExe"
