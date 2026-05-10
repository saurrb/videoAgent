param(
  [Parameter(Mandatory = $true)][string]$PromptFile,
  [string]$WindowTitle = "BrowserOS",
  [int]$PromptX = 1690,
  [int]$PromptY = 748,
  [int]$RunX = 1768,
  [int]$RunY = 1008,
  [int]$ScrollSteps = 14,
  [int]$ScrollDelta = -120,
  [int]$WaitAfterOpenSeconds = 3
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path $PromptFile)) {
  throw "Prompt file not found: $PromptFile"
}

# Always start from a fresh Imagine tab.
& browseros-cli open https://grok.com/imagine --json | Out-Null
Start-Sleep -Seconds $WaitAfterOpenSeconds

# Run native extension automation (clear old text, paste, scroll, run).
& powershell -ExecutionPolicy Bypass -File "$PSScriptRoot\run_grok_extension_ui_native.ps1" `
  -PromptFile $PromptFile `
  -WindowTitle $WindowTitle `
  -PromptX $PromptX `
  -PromptY $PromptY `
  -RunX $RunX `
  -RunY $RunY `
  -ScrollSteps $ScrollSteps `
  -ScrollDelta $ScrollDelta
