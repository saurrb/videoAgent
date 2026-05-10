param(
  [string]$PythonExe = "C:\Users\saura\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe"
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path $PythonExe)) {
  throw "Python not found at $PythonExe"
}

& $PythonExe -m pip install --upgrade pip | Out-Host
& $PythonExe -m pip install google-api-python-client google-auth-oauthlib | Out-Host

Write-Output "YouTube API Python dependencies installed."
