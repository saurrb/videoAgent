param(
  [string]$WindowTitle = "Imagine Agent Mode - Grok",
  [string]$ConfigPath = ".\config\grok_extension_ui.json"
)

$ErrorActionPreference = "Stop"

function Require-Cmd([string]$name) {
  $cmd = Get-Command $name -ErrorAction SilentlyContinue
  if (-not $cmd) { throw "Missing command: $name" }
}

Require-Cmd "powershell"
Add-Type -AssemblyName System.Windows.Forms

Write-Output "Calibration target window: $WindowTitle"
Write-Output "Bring Chromium/Grok window to front and keep extension side panel visible."
Write-Output "When ready, hover the mouse over each target and press Enter."

Start-Sleep -Seconds 1

Write-Output ""
Write-Output "Step 1/2: Hover over extension 'Prompts' textbox input area, then press Enter."
[void](Read-Host)
$p1 = [System.Windows.Forms.Cursor]::Position
Write-Output "Captured prompt textbox at: X=$($p1.X), Y=$($p1.Y)"

Write-Output ""
Write-Output "Step 2/2: Hover over extension 'Run' button, then press Enter."
[void](Read-Host)
$p2 = [System.Windows.Forms.Cursor]::Position
Write-Output "Captured Run button at: X=$($p2.X), Y=$($p2.Y)"

Write-Output ""
Write-Output "Step 3/2: Hover over top-left corner of Grok browser content area, then press Enter."
[void](Read-Host)
$p0 = [System.Windows.Forms.Cursor]::Position
Write-Output "Captured window reference at: X=$($p0.X), Y=$($p0.Y)"

$promptRelX = $p1.X - $p0.X
$promptRelY = $p1.Y - $p0.Y
$runRelX = $p2.X - $p0.X
$runRelY = $p2.Y - $p0.Y

$config = [ordered]@{
  windowTitle = $WindowTitle
  promptX = $promptRelX
  promptY = $promptRelY
  runX = $runRelX
  runY = $runRelY
  preDelayMs = 1000
  openHotkey = "-"
}

$targetDir = Split-Path -Parent $ConfigPath
if ($targetDir -and -not (Test-Path $targetDir)) {
  New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
}

($config | ConvertTo-Json -Depth 5) | Set-Content -Path $ConfigPath -Encoding UTF8
Write-Output ""
Write-Output "Saved calibration: $ConfigPath"
Write-Output "prompt=($promptRelX,$promptRelY), run=($runRelX,$runRelY)"
