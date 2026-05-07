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
  --max-chars $MaxChars

& $ff -y -i $VideoPath -vf "ass='$($OutputAssPath -replace '\\', '\\\\' -replace ':', '\\:')'" -c:a copy $OutputVideoPath

Write-Output "DONE: $OutputVideoPath"
