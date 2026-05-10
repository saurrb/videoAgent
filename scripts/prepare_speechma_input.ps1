param(
  [Parameter(Mandatory = $true)][string]$ScriptPath,
  [Parameter(Mandatory = $true)][string]$OutPath
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path $ScriptPath)) { throw "Missing ScriptPath: $ScriptPath" }

$raw = Get-Content -Raw -Path $ScriptPath

# Convert our internal script format into Speechma-friendly narration text:
# - Drop markdown headers like "# Hook", "# Script v1 (60s)"
# - Drop bracketed stage directions (if present)
# - Keep real line breaks (Speechma benefits from them)
# - Collapse excessive blank lines
$lines = $raw -split "\r?\n"
$outLines = New-Object System.Collections.Generic.List[string]
foreach ($line in $lines) {
  $t = $line.TrimEnd()

  if ([string]::IsNullOrWhiteSpace($t)) {
    # preserve blanks, but we'll collapse later
    $outLines.Add("")
    continue
  }

  # Skip markdown headings.
  if ($t -match "^\s*#") { continue }

  # Skip common stage directions.
  if ($t -match "^\s*\\[.*\\]\\s*$") { continue }
  if ($t -match "^\s*\\(.*\\)\\s*$") { continue }

  $outLines.Add($t)
}

# Collapse multiple blank lines.
$collapsed = New-Object System.Collections.Generic.List[string]
$prevBlank = $false
foreach ($l in $outLines) {
  $isBlank = [string]::IsNullOrWhiteSpace($l)
  if ($isBlank -and $prevBlank) { continue }
  $collapsed.Add($l.TrimEnd())
  $prevBlank = $isBlank
}

$final = ($collapsed -join "`r`n").Trim()

New-Item -ItemType Directory -Force -Path (Split-Path $OutPath -Parent) | Out-Null
Set-Content -Path $OutPath -Value $final -Encoding UTF8

Write-Host "Wrote Speechma input:" $OutPath
Write-Host "Chars:" $final.Length
