param(
  [Parameter(Mandatory = $true)]
  [string]$Name
)

$ErrorActionPreference = "Stop"

function Sanitize-Name([string]$value) {
  $v = $value.Trim().ToLowerInvariant()
  $v = $v -replace "[^a-z0-9\-_\s]", ""
  $v = $v -replace "\s+", "-"
  return $v
}

$safeName = Sanitize-Name $Name
$date = Get-Date -Format "yyyy-MM-dd"
$root = Join-Path $PSScriptRoot "..\assets\reels"
$workspace = Join-Path $root "$date`_$safeName"

$dirs = @(
  $workspace,
  (Join-Path $workspace "script"),
  (Join-Path $workspace "voice"),
  (Join-Path $workspace "scenes"),
  (Join-Path $workspace "captions"),
  (Join-Path $workspace "edit"),
  (Join-Path $workspace "final"),
  (Join-Path $workspace "meta")
)

foreach ($d in $dirs) {
  New-Item -ItemType Directory -Path $d -Force | Out-Null
}

$scriptTemplate = @"
# Hook


# Script v1

"@

$scenePlanTemplate = @"
# Scene Plan v1

- Scene 1 (0:00-0:05):
- Scene 2 (0:05-0:12):
- Scene 3 (0:12-0:20):
- Scene 4 (0:20-0:28):
"@

$publishLogTemplate = @"
# Publish Log

| DateTime | Platform | URL | Hook | Notes |
|---|---|---|---|---|
"@

$platformCaptionTemplate = @"
# Platform Captions + Hashtags

## Caption


## Hashtags

Use US America hashtags by default for better RPM and US audience fit. Keep tags relevant to the reel topic, audience, and platform.

Default mix:
- 3-5 US/America audience or market tags
- 3-5 niche topic tags
- 2-4 format/discovery tags for reels/shorts

Do not use unrelated trend tags or non-US geo tags unless the reel specifically targets that audience.

## Facebook / Instagram


## YouTube Shorts


"@

Set-Content -Path (Join-Path $workspace "script\script_v1.txt") -Value $scriptTemplate -Encoding UTF8
Set-Content -Path (Join-Path $workspace "meta\scene_plan_v1.md") -Value $scenePlanTemplate -Encoding UTF8
Set-Content -Path (Join-Path $workspace "meta\publish_log.md") -Value $publishLogTemplate -Encoding UTF8
Set-Content -Path (Join-Path $workspace "meta\platform_caption_hashtags.md") -Value $platformCaptionTemplate -Encoding UTF8

Write-Output "Created: $workspace"
