param(
  [Parameter(Mandatory = $true)][string]$PromptFile,
  [string]$WindowTitle = "Imagine - Grok",
  [int]$PromptX = 1640,
  [int]$PromptY = 575,
  [int]$RunX = 1745,
  [int]$RunY = 876,
  [int]$ScrollSteps = 8,
  [int]$ScrollDelta = -120,
  [int]$PreDelayMs = 500,
  [int]$PostPasteDelayMs = 400,
  [int]$PostScrollDelayMs = 200,
  [switch]$SkipActivate,
  [switch]$DryRun
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path $PromptFile)) {
  throw "Prompt file not found: $PromptFile"
}

Add-Type -AssemblyName System.Windows.Forms
Add-Type @"
using System;
using System.Runtime.InteropServices;
public static class NativeMouse {
  [DllImport("user32.dll")] public static extern bool SetCursorPos(int X, int Y);
  [DllImport("user32.dll")] public static extern void mouse_event(uint dwFlags, uint dx, uint dy, int dwData, UIntPtr dwExtraInfo);
  public const uint MOUSEEVENTF_LEFTDOWN = 0x0002;
  public const uint MOUSEEVENTF_LEFTUP = 0x0004;
  public const uint MOUSEEVENTF_WHEEL = 0x0800;
}
"@

function Click-At([int]$x, [int]$y) {
  [NativeMouse]::SetCursorPos($x, $y) | Out-Null
  Start-Sleep -Milliseconds 80
  [NativeMouse]::mouse_event([NativeMouse]::MOUSEEVENTF_LEFTDOWN, 0, 0, 0, [UIntPtr]::Zero)
  Start-Sleep -Milliseconds 40
  [NativeMouse]::mouse_event([NativeMouse]::MOUSEEVENTF_LEFTUP, 0, 0, 0, [UIntPtr]::Zero)
}

function Scroll-At([int]$x, [int]$y, [int]$steps, [int]$delta) {
  [NativeMouse]::SetCursorPos($x, $y) | Out-Null
  for ($i = 0; $i -lt $steps; $i++) {
    [NativeMouse]::mouse_event([NativeMouse]::MOUSEEVENTF_WHEEL, 0, 0, $delta, [UIntPtr]::Zero)
    Start-Sleep -Milliseconds 50
  }
}

$promptText = Get-Content -Raw -Path $PromptFile

$activated = $false
if (-not $SkipActivate) {
  $wshell = New-Object -ComObject WScript.Shell
  $activated = $wshell.AppActivate($WindowTitle)
  if (-not $activated) {
    throw "Could not activate window containing title: $WindowTitle"
  }
  Start-Sleep -Milliseconds $PreDelayMs
  Write-Output "Window activated: $WindowTitle"
}
else {
  Write-Output "SkipActivate enabled. Sending input to currently focused window."
  Start-Sleep -Milliseconds $PreDelayMs
}
Write-Output "Prompt chars: $($promptText.Length)"
Write-Output "Prompt box: ($PromptX,$PromptY)"
Write-Output "Run button: ($RunX,$RunY)"

if ($DryRun) {
  Write-Output "Dry run only. No UI input sent."
  exit 0
}

# Load prompt text into clipboard and paste into extension prompt textarea.
Set-Clipboard -Value $promptText
Click-At -x $PromptX -y $PromptY
Start-Sleep -Milliseconds 120
[System.Windows.Forms.SendKeys]::SendWait("^a")
Start-Sleep -Milliseconds 80
[System.Windows.Forms.SendKeys]::SendWait("{BACKSPACE}")
Start-Sleep -Milliseconds 80
[System.Windows.Forms.SendKeys]::SendWait("^v")
Start-Sleep -Milliseconds $PostPasteDelayMs

# Scroll extension panel down to reveal run button.
Scroll-At -x $PromptX -y $PromptY -steps $ScrollSteps -delta $ScrollDelta
Start-Sleep -Milliseconds $PostScrollDelayMs

# Click Run.
Click-At -x $RunX -y $RunY

Write-Output "Pasted prompts, scrolled panel, clicked Run."
