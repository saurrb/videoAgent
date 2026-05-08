param(
  [Parameter(Mandatory=$true)][string]$AudioPath,
  [Parameter(Mandatory=$true)][string]$SrtPath,
  [Parameter(Mandatory=$true)][string]$VideoPath,
  [Parameter(Mandatory=$true)][string]$OutputVideoPath,
  [string]$OutputAssPath = "",
  [string]$OutputWordsPath = "",
  [int]$MaxChars = 16
)

$py = "C:\Users\saura\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe"
$repoRoot = Split-Path $PSScriptRoot -Parent
$ff = Join-Path $repoRoot "tools\ffmpeg\ffmpeg-8.1.1-essentials_build\bin\ffmpeg.exe"
$extractWords = Join-Path $PSScriptRoot "extract_word_timestamps.py"
$buildAss = Join-Path $PSScriptRoot "build_wordtimed_ass.py"

if (-not (Test-Path $py)) { throw "Python not found: $py" }
if (-not (Test-Path $ff)) { throw "ffmpeg not found: $ff" }
if (-not (Test-Path $extractWords)) { throw "Missing script: $extractWords" }
if (-not (Test-Path $buildAss)) { throw "Missing script: $buildAss" }

if ([string]::IsNullOrWhiteSpace($OutputWordsPath)) {
  $OutputWordsPath = [System.IO.Path]::ChangeExtension($SrtPath, ".word_timestamps.json")
}
if ([string]::IsNullOrWhiteSpace($OutputAssPath)) {
  $OutputAssPath = [System.IO.Path]::ChangeExtension($SrtPath, ".wordtimed.ass")
}

& $py $extractWords `
  --audio $AudioPath `
  --out $OutputWordsPath

& $py $buildAss `
  --srt $SrtPath `
  --words $OutputWordsPath `
  --out $OutputAssPath `
  --max-chars $MaxChars `
  --preset ytshort `
  --chunk-size 2

function Escape-AssPathForFfmpeg([string]$p) {
  # ffmpeg `ass` filter uses ':' to separate options, so we must escape the drive colon.
  # Use forward slashes to avoid backslash escaping issues.
  $abs = [System.IO.Path]::GetFullPath($p) -replace '\\', '/'
  if ($abs.Length -ge 2 -and $abs[1] -eq ':') {
    return $abs.Substring(0, 1) + '\:' + $abs.Substring(2)
  }
  return $abs
}

$assEsc = Escape-AssPathForFfmpeg $OutputAssPath
& $ff -y -i $VideoPath -vf "ass='$assEsc'" -c:a copy $OutputVideoPath | Out-Host

if ($LASTEXITCODE -ne 0) { throw "ffmpeg failed to burn captions." }

Write-Output "DONE: $OutputVideoPath"
