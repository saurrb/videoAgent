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
$ff = "C:\Users\saura\Documents\videoAgent\tools\ffmpeg\ffmpeg-8.1.1-essentials_build\bin\ffmpeg.exe"

if ([string]::IsNullOrWhiteSpace($OutputWordsPath)) {
  $OutputWordsPath = [System.IO.Path]::ChangeExtension($SrtPath, ".word_timestamps.json")
}
if ([string]::IsNullOrWhiteSpace($OutputAssPath)) {
  $OutputAssPath = [System.IO.Path]::ChangeExtension($SrtPath, ".wordtimed.ass")
}

& $py "C:\Users\saura\Documents\videoAgent\scripts\extract_word_timestamps.py" `
  --audio $AudioPath `
  --out $OutputWordsPath

& $py "C:\Users\saura\Documents\videoAgent\scripts\build_wordtimed_ass.py" `
  --srt $SrtPath `
  --words $OutputWordsPath `
  --out $OutputAssPath `
  --max-chars $MaxChars

& $ff -y -i $VideoPath -vf "ass='$($OutputAssPath -replace '\\', '\\\\' -replace ':', '\\:')'" -c:a copy $OutputVideoPath

Write-Output "DONE: $OutputVideoPath"
