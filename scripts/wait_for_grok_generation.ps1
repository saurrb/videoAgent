param(
  [Parameter(Mandatory = $true)]
  [ValidateSet("image", "video", "stitch")]
  [string]$Type,
  [datetime]$Since = (Get-Date),
  [string]$Workspace,
  [int]$SceneNumber
)

$ErrorActionPreference = "Stop"

switch ($Type) {
  "image"  { $soft = 45;  $hard = 120 }
  "video"  { $soft = 90;  $hard = 240 }
  "stitch" { $soft = 180; $hard = 420 }
}

Write-Output "Timer started for '$Type' generation."
Write-Output "Soft check: ${soft}s | Hard timeout: ${hard}s"
Write-Output "Started at: $Since"

Start-Sleep -Seconds $soft
Write-Output "Soft check reached. Inspect Grok canvas now and take screenshot."

$elapsed = $soft
$downloads = Join-Path $env:USERPROFILE "Downloads"

while ($elapsed -lt $hard) {
  $found = Get-ChildItem $downloads -Filter "grok-*.mp4" -File -ErrorAction SilentlyContinue |
    Where-Object { $_.LastWriteTime -ge $Since } |
    Sort-Object LastWriteTime -Descending |
    Select-Object -First 1

  if ($found) {
    Write-Output "Detected Grok file: $($found.FullName)"
    if ($Workspace) {
      $importArgs = @(
        "-ExecutionPolicy", "Bypass",
        "-File", (Join-Path $PSScriptRoot "import_grok_scene_download.ps1"),
        "-Workspace", $Workspace
      )
      if ($SceneNumber) {
        $importArgs += @("-SceneNumber", "$SceneNumber")
      }
      & powershell @importArgs | Out-Host
    }
    exit 0
  }

  Start-Sleep -Seconds 20
  $elapsed += 20
  Write-Output "Waiting... ${elapsed}s/${hard}s"
}

Write-Output "Hard timeout reached (${hard}s). Use Grok recovery sequence before retry."
exit 2
