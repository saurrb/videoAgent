param(
  [Parameter(Mandatory = $true)][string]$PromptFile,
  [int]$PageId = 2,
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
  if (-not $cmd) { throw "Missing required command on PATH: $name" }
}

function Invoke-BrowserEval([int]$TargetPage, [string]$Js) {
  $result = & browseros-cli eval --page $TargetPage $Js
  if ($LASTEXITCODE -ne 0) {
    throw "browseros-cli eval failed."
  }
  return $result
}

function Parse-PromptBlocks([string]$Text, [string]$Pattern) {
  $blocks = $Text -split "(?:\r?\n){2,}" |
    ForEach-Object { $_.Trim() } |
    Where-Object { $_ -ne "" }

  if ([string]::IsNullOrWhiteSpace($Pattern)) {
    return $blocks
  }

  $filtered = $blocks | Where-Object { $_ -match $Pattern }
  if ($filtered.Count -gt 0) { return $filtered }
  return $blocks
}

function New-SubmissionText([string]$Block) {
  $lines = $Block -split "\r?\n" | ForEach-Object { $_.TrimEnd() }
  $drop = @(
    "^SCENES?\d*.*$",
    "^Project objective:.*$",
    "^STYLE ANCHORS.*$",
    "^NEGATIVE:.*$"
  )

  $clean = New-Object System.Collections.Generic.List[string]
  foreach ($line in $lines) {
    if ([string]::IsNullOrWhiteSpace($line)) { continue }
    $skip = $false
    foreach ($rx in $drop) {
      if ($line -match $rx) { $skip = $true; break }
    }
    if (-not $skip) {
      $normalized = $line -replace "^\s*Scene\d+\s*:\s*", ""
      $normalized = $normalized -replace "\s*Output:\s*scene\d+\.mp4\s*$", ""
      if (-not [string]::IsNullOrWhiteSpace($normalized)) {
        $clean.Add($normalized.Trim())
      }
    }
  }
  return ($clean -join "`n").Trim()
}

function Get-SnapshotText([int]$TargetPage) {
  $snap = & browseros-cli snap --page $TargetPage
  if ($LASTEXITCODE -ne 0) { throw "browseros-cli snap failed." }
  return ($snap | Out-String)
}

function Find-SnapshotIdByPattern([string]$Snapshot, [string]$Pattern) {
  $lines = $Snapshot -split "\r?\n"
  foreach ($line in $lines) {
    if ($line -match "^\[(\d+)\].*$Pattern") {
      return [int]$Matches[1]
    }
  }
  return $null
}

function Invoke-BrowserClick([int]$TargetPage, [int]$ElementId) {
  & browseros-cli click --page $TargetPage $ElementId | Out-Null
  if ($LASTEXITCODE -ne 0) { throw "browseros-cli click failed for element [$ElementId]." }
}

function Invoke-BrowserFill([int]$TargetPage, [int]$ElementId, [string]$Text) {
  & browseros-cli fill --page $TargetPage $ElementId $Text | Out-Null
  if ($LASTEXITCODE -ne 0) { throw "browseros-cli fill failed for element [$ElementId]." }
}

function Invoke-BrowserEnter([int]$TargetPage) {
  & browseros-cli key --page $TargetPage Enter | Out-Null
  if ($LASTEXITCODE -ne 0) { throw "browseros-cli key Enter failed." }
}

function Submit-PromptByEval([int]$TargetPage, [string]$PromptText) {
  $promptBytes = [System.Text.Encoding]::UTF8.GetBytes($PromptText)
  $promptB64 = [System.Convert]::ToBase64String($promptBytes)
  $submitJs = @'
(() => {
  const raw = "__PROMPT_B64__";
  const promptText = decodeURIComponent(escape(atob(raw)));
  const editor = document.querySelector(".tiptap.ProseMirror[contenteditable='true'], [contenteditable='true'][role='textbox']");
  if (!editor) return { ok: false, reason: "editor_not_found" };
  editor.focus();
  editor.innerHTML = "";
  const lines = promptText.split("\n");
  for (const line of lines) {
    const p = document.createElement("p");
    p.textContent = line;
    editor.appendChild(p);
  }
  editor.dispatchEvent(new Event("input", { bubbles: true }));
  editor.dispatchEvent(new Event("change", { bubbles: true }));
  const submit = Array.from(document.querySelectorAll("button")).find(b => ((b.textContent || "").trim() === "Submit" && !b.disabled));
  if (!submit) return { ok: false, reason: "submit_disabled" };
  submit.click();
  return { ok: true };
})()
'@
  $js = $submitJs.Replace("__PROMPT_B64__", $promptB64)
  $result = Invoke-BrowserEval -TargetPage $TargetPage -Js ($js -replace "(\r\n|\n|\r)", " ")
  if ($result -notmatch '"ok"\s*:\s*true') {
    throw "Eval submit failed: $result"
  }
}

Require-Cmd "browseros-cli"

if (-not (Test-Path $PromptFile)) {
  throw "Prompt file not found: $PromptFile"
}

if ($DelayMaxSeconds -lt $DelayMinSeconds) {
  throw "DelayMaxSeconds must be >= DelayMinSeconds."
}

$raw = Get-Content -Raw -Path $PromptFile
$blocks = Parse-PromptBlocks -Text $raw -Pattern $FilterPattern
if ($blocks.Count -eq 0) {
  throw "No prompt blocks found."
}

$startZero = [Math]::Max(0, $StartIndex - 1)
if ($startZero -ge $blocks.Count) {
  throw "StartIndex is out of range. Total prompts: $($blocks.Count)"
}

$selected = $blocks[$startZero..($blocks.Count - 1)]
if ($MaxPrompts -gt 0 -and $selected.Count -gt $MaxPrompts) {
  $selected = $selected[0..($MaxPrompts - 1)]
}

Write-Output "Prompt file: $PromptFile"
Write-Output "Total parsed blocks: $($blocks.Count)"
Write-Output "Submitting from index: $StartIndex"
Write-Output "Prompts to run now: $($selected.Count)"
Write-Output "Target page: $PageId"
Write-Output "Delay window: ${DelayMinSeconds}-${DelayMaxSeconds}s"
if ($DryRun) { Write-Output "Mode: DRY RUN (no submit)" }

if (-not $DryRun) {
  $snapshot = Get-SnapshotText -TargetPage $PageId
  $imagineId = Find-SnapshotIdByPattern -Snapshot $snapshot -Pattern 'link "Imagine"|clickable "Imagine'
  if ($imagineId -gt 0) {
    Invoke-BrowserClick -TargetPage $PageId -ElementId $imagineId
    Start-Sleep -Seconds 2
  } else {
    Write-Output "Imagine link not found in snapshot; continuing on current page."
  }

  $shotDir = Join-Path (Split-Path $PromptFile -Parent) "..\analysis\grok_automation_debug"
  New-Item -ItemType Directory -Path $shotDir -Force | Out-Null
  & browseros-cli ss --page $PageId --full --out (Join-Path $shotDir "01_before_submit.png") | Out-Null
}

$idx = $StartIndex
foreach ($block in $selected) {
  $submission = New-SubmissionText -Block $block
  if ([string]::IsNullOrWhiteSpace($submission)) {
    Write-Output "[$idx] Skipped (empty after cleanup)."
    $idx++
    continue
  }

  Write-Output "[$idx] Preparing prompt ($($submission.Length) chars)"
  if ($DryRun) {
    $preview = if ($submission.Length -gt 140) { $submission.Substring(0, 140) + "..." } else { $submission }
    Write-Output "[$idx] DRY RUN preview: $preview"
    $idx++
    continue
  }

  $snapshot = Get-SnapshotText -TargetPage $PageId

  $videoId = Find-SnapshotIdByPattern -Snapshot $snapshot -Pattern 'button "Video"|radio "Video"|clickable "Video"'
  if ($videoId -gt 0) { Invoke-BrowserClick -TargetPage $PageId -ElementId $videoId }

  $aspectId = Find-SnapshotIdByPattern -Snapshot $snapshot -Pattern 'button "9:16"|radio "9:16"|clickable "9:16"'
  if ($aspectId -gt 0) { Invoke-BrowserClick -TargetPage $PageId -ElementId $aspectId }

  $durationId = Find-SnapshotIdByPattern -Snapshot $snapshot -Pattern 'button "6s"|radio "6s"|clickable "6s"'
  if ($durationId -gt 0) { Invoke-BrowserClick -TargetPage $PageId -ElementId $durationId }

  $inputId = Find-SnapshotIdByPattern -Snapshot $snapshot -Pattern 'How can I help you today\?|What do you want to know\?'
  if ($inputId -gt 0) {
    Invoke-BrowserFill -TargetPage $PageId -ElementId $inputId -Text $submission
    Invoke-BrowserEnter -TargetPage $PageId
  } else {
    Submit-PromptByEval -TargetPage $PageId -PromptText $submission
  }
  Write-Output "[$idx] Submitted."

  if ($idx -lt ($StartIndex + $selected.Count - 1)) {
    $wait = Get-Random -Minimum $DelayMinSeconds -Maximum ($DelayMaxSeconds + 1)
    Write-Output "[$idx] Waiting ${wait}s before next prompt."
    Start-Sleep -Seconds $wait
  }

  $idx++
}

if (-not $DryRun) {
  $shotDir = Join-Path (Split-Path $PromptFile -Parent) "..\analysis\grok_automation_debug"
  & browseros-cli ss --page $PageId --full --out (Join-Path $shotDir "02_after_submit.png") | Out-Null
}

Write-Output "Done."
