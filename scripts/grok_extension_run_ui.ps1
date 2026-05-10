param(
  [Parameter(Mandatory = $true)][string]$PromptFile,
  [string]$ConfigPath = ".\config\grok_extension_ui.json",
  [string]$AhkExePath = "",
  [int]$AhkTimeoutSeconds = 25,
  [int]$StartIndex = 1,
  [int]$MaxPrompts = 0,
  [int]$DelayMinSeconds = 20,
  [int]$DelayMaxSeconds = 30,
  [string]$FilterPattern = "Output:\s*scene\d+\.mp4",
  [switch]$DryRun
)

$ErrorActionPreference = "Stop"

function Require-Cmd([string]$name) {
  $cmd = Get-Command $name -ErrorAction SilentlyContinue
  if (-not $cmd) { throw "Missing command: $name" }
}

function Find-AhkExe {
  $candidates = @(
    "$env:ProgramFiles\AutoHotkey\v2\AutoHotkey64.exe",
    "$env:ProgramFiles\AutoHotkey\v2\AutoHotkey.exe",
    "$env:ProgramFiles\AutoHotkey\AutoHotkey64.exe",
    "$env:ProgramFiles\AutoHotkey\AutoHotkey.exe"
  )
  foreach ($c in $candidates) {
    if (Test-Path $c) { return $c }
  }
  $fromPath = Get-Command AutoHotkey64.exe -ErrorAction SilentlyContinue
  if ($fromPath) { return $fromPath.Source }
  $fromPath = Get-Command AutoHotkey.exe -ErrorAction SilentlyContinue
  if ($fromPath) { return $fromPath.Source }
  return $null
}

function Parse-PromptBlocks([string]$text) {
  $lines = $text -split "\r?\n" | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne "" }
  $sceneLines = $lines | Where-Object { $_ -match $FilterPattern }
  if ($sceneLines.Count -gt 0) {
    return $sceneLines
  }

  return $text -split "(?:\r?\n){2,}" |
    ForEach-Object { $_.Trim() } |
    Where-Object { $_ -ne "" }
}

function Normalize-Prompt([string]$text) {
  $x = $text.Trim()
  $x = $x -replace "^\s*Scene\d+\s*:\s*", ""
  $x = $x -replace "\s*Output:\s*scene\d+\.mp4\s*$", ""
  return $x.Trim()
}

function Invoke-AhkRunner {
  param(
    [Parameter(Mandatory = $true)][string]$AhkExe,
    [Parameter(Mandatory = $true)][string]$ScriptPath,
    [Parameter(Mandatory = $true)][string[]]$Arguments,
    [Parameter(Mandatory = $true)][int]$TimeoutSeconds
  )

  $psi = New-Object System.Diagnostics.ProcessStartInfo
  $psi.FileName = $AhkExe
  $psi.UseShellExecute = $false
  $psi.CreateNoWindow = $true
  foreach ($arg in $Arguments) {
    [void]$psi.ArgumentList.Add([string]$arg)
  }

  $proc = [System.Diagnostics.Process]::Start($psi)
  if (-not $proc) {
    throw "Failed to start AutoHotkey process."
  }

  $waited = $proc.WaitForExit($TimeoutSeconds * 1000)
  if (-not $waited) {
    try { $proc.Kill($true) } catch {}
    return @{
      TimedOut = $true
      ExitCode = $null
    }
  }

  return @{
    TimedOut = $false
    ExitCode = $proc.ExitCode
  }
}

Require-Cmd "powershell"

if (-not (Test-Path $PromptFile)) { throw "Prompt file not found: $PromptFile" }
if (-not (Test-Path $ConfigPath)) { throw "Config not found: $ConfigPath. Run scripts\\grok_extension_calibrate.ps1 first." }
if ($DelayMaxSeconds -lt $DelayMinSeconds) { throw "DelayMaxSeconds must be >= DelayMinSeconds." }

$ahkExe = if ([string]::IsNullOrWhiteSpace($AhkExePath)) { Find-AhkExe } else { $AhkExePath }
if (-not $DryRun -and -not $ahkExe) {
  throw "AutoHotkey v2 not found. Install AutoHotkey v2 first."
}
if (-not $DryRun -and -not (Test-Path $ahkExe)) {
  throw "AutoHotkey executable not found: $ahkExe"
}

$config = Get-Content -Raw -Path $ConfigPath | ConvertFrom-Json
$all = Parse-PromptBlocks -text (Get-Content -Raw -Path $PromptFile)
if ($all.Count -eq 0) { throw "No prompt blocks found in PromptFile." }

$startZero = [Math]::Max(0, $StartIndex - 1)
if ($startZero -ge $all.Count) {
  throw "StartIndex out of range. Total blocks: $($all.Count)"
}

$selected = $all[$startZero..($all.Count - 1)]
if ($MaxPrompts -gt 0 -and $selected.Count -gt $MaxPrompts) {
  $selected = $selected[0..($MaxPrompts - 1)]
}

$tmpDir = Join-Path $env:TEMP ("grok-ui-run-" + [guid]::NewGuid().ToString("N"))
New-Item -ItemType Directory -Path $tmpDir -Force | Out-Null
$logPath = Join-Path $tmpDir "runner.log"

Write-Output "Prompt file: $PromptFile"
Write-Output "Config: $ConfigPath"
Write-Output "AutoHotkey: $ahkExe"
Write-Output "Prompts selected: $($selected.Count)"
Write-Output "Delay window: ${DelayMinSeconds}-${DelayMaxSeconds}s"
if ($DryRun) { Write-Output "Mode: DRY RUN (no UI clicks)." }

$scriptPath = Join-Path $PSScriptRoot "grok_extension_clicker_v2.ahk"
$openHotkey = [string]$config.openHotkey
if ([string]::IsNullOrWhiteSpace($openHotkey)) {
  $openHotkey = "-"
}
$ahkWatchdogMs = [Math]::Max(5000, ($AhkTimeoutSeconds * 1000) - 1000)

$index = $StartIndex
foreach ($prompt in $selected) {
  $prompt = Normalize-Prompt -text $prompt
  $tmpPrompt = Join-Path $tmpDir ("prompt_{0:D3}.txt" -f $index)
  Set-Content -Path $tmpPrompt -Value $prompt -Encoding UTF8

  Write-Output "[$index] Ready ($($prompt.Length) chars)"
  if ($DryRun) {
    $preview = if ($prompt.Length -gt 120) { $prompt.Substring(0, 120) + "..." } else { $prompt }
    Write-Output "[$index] DRY RUN preview: $preview"
  }
  else {
    $args = @(
      $scriptPath,
      [string]$config.windowTitle,
      $tmpPrompt,
      [string]$config.promptX,
      [string]$config.promptY,
      [string]$config.runX,
      [string]$config.runY,
      [string]$config.preDelayMs,
      $openHotkey,
      $logPath,
      [string]$ahkWatchdogMs
    )

    $result = Invoke-AhkRunner -AhkExe $ahkExe -ScriptPath $scriptPath -Arguments $args -TimeoutSeconds $AhkTimeoutSeconds
    if ($result.TimedOut) {
      $tail = if (Test-Path $logPath) { (Get-Content $logPath | Select-Object -Last 6) -join " | " } else { "" }
      throw "AutoHotkey timed out at prompt index $index after ${AhkTimeoutSeconds}s. Log: $tail"
    }
    if ($result.ExitCode -ne 0) {
      $tail = if (Test-Path $logPath) { (Get-Content $logPath | Select-Object -Last 4) -join " | " } else { "" }
      throw "AutoHotkey click runner failed at prompt index $index (exit code $($result.ExitCode)). Log: $tail"
    }
    Write-Output "[$index] Submitted."
  }

  if ($index -lt ($StartIndex + $selected.Count - 1)) {
    $wait = Get-Random -Minimum $DelayMinSeconds -Maximum ($DelayMaxSeconds + 1)
    Write-Output "[$index] Waiting ${wait}s"
    if (-not $DryRun) { Start-Sleep -Seconds $wait }
  }
  $index++
}

Write-Output "Done."
