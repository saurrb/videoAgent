param(
  [Parameter(Mandatory = $true)][string]$Workspace,
  [int]$StartScene = 2,
  [int]$Count = 3,
  [int]$PollSeconds = 3,
  [int]$TimeoutSeconds = 1800,
  [datetime]$Since = (Get-Date)
)

$ErrorActionPreference = "Stop"

$downloads = Join-Path $env:USERPROFILE "Downloads"
$seen = @{}
$imported = 0
$scene = $StartScene
$start = Get-Date

if (-not (Test-Path $Workspace)) {
  throw "Workspace not found: $Workspace"
}

Write-Output "Monitoring Grok downloads..."
Write-Output "Workspace: $Workspace"
Write-Output "Target scenes: $StartScene to $($StartScene + $Count - 1)"
Write-Output "Since: $Since"

while ($imported -lt $Count) {
  if (((Get-Date) - $start).TotalSeconds -ge $TimeoutSeconds) {
    throw "Timeout waiting for Grok downloads."
  }

  $latest = Get-ChildItem $downloads -Filter "grok-*.mp4" -File -ErrorAction SilentlyContinue |
    Where-Object { $_.LastWriteTime -ge $Since } |
    Sort-Object LastWriteTime -Descending |
    Select-Object -First 1

  if ($latest) {
    $fileKey = "$($latest.FullName)|$($latest.LastWriteTimeUtc.Ticks)|$($latest.Length)"
    if ($seen.ContainsKey($fileKey)) {
      Start-Sleep -Seconds $PollSeconds
      continue
    }
    $seen[$fileKey] = $true
    & powershell -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot "import_grok_scene_download.ps1") `
      -Workspace $Workspace -SceneNumber $scene | Out-Host
    $imported++
    $scene++
  }

  Start-Sleep -Seconds $PollSeconds
}

Write-Output "Done. Imported $imported scene(s)."
