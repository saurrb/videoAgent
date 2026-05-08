param(
  [Parameter(Mandatory = $true)][string]$Text,
  [string]$OutDir = "",
  [int]$DurationSeconds = 6,
  [string]$Preset = "ytshort",
  [int]$ChunkSize = 2,
  [int]$MaxChars = 13
)

$ErrorActionPreference = "Stop"

$repoRoot = Split-Path $PSScriptRoot -Parent
$py = "C:\Users\saura\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe"
$ff = Join-Path $repoRoot "tools\ffmpeg\ffmpeg-8.1.1-essentials_build\bin\ffmpeg.exe"
$buildAss = Join-Path $PSScriptRoot "build_wordtimed_ass.py"

if (-not (Test-Path $py)) { throw "Python not found: $py" }
if (-not (Test-Path $ff)) { throw "ffmpeg not found: $ff" }
if (-not (Test-Path $buildAss)) { throw "Missing script: $buildAss" }

if ([string]::IsNullOrWhiteSpace($OutDir)) {
  $OutDir = Join-Path $repoRoot "assets\\analysis\\caption_test"
}

New-Item -ItemType Directory -Path $OutDir -Force | Out-Null

$baseVideo = Join-Path $OutDir "blank_base.mp4"
$framePng = Join-Path $OutDir "blank_frame.png"
$srtPath = Join-Path $OutDir "test.srt"
$wordsPath = Join-Path $OutDir "word_timestamps.json"
$assPath = Join-Path $OutDir "captions.ass"
$outVideo = Join-Path $OutDir "blank_captioned.mp4"

function AbsPath([string]$p) {
  return [System.IO.Path]::GetFullPath($p)
}

# 1) Generate a blank 9:16 reel-sized base video WITH audio (so downstream steps don't break).
& $ff -y `
  -f lavfi -i ("color=c=#0B0B0B:s=1080x1920:r=30:d=" + $DurationSeconds) `
  -f lavfi -i "anullsrc=channel_layout=stereo:sample_rate=44100" `
  -shortest `
  -c:v libx264 -pix_fmt yuv420p -crf 18 `
  -c:a aac -b:a 128k `
  $baseVideo | Out-Host

# 2) Export a single PNG frame (handy for quick inspection / thumbnails).
& $ff -y -i $baseVideo -frames:v 1 -update 1 $framePng | Out-Host

# 3) Build a tiny SRT and synthetic per-word timestamps for testing.
$safeText = ($Text -replace "`r", " " -replace "`n", " ").Trim()
if ([string]::IsNullOrWhiteSpace($safeText)) { throw "Text cannot be empty." }

$srt = @"
1
00:00:00,000 --> 00:00:{0},000
{1}
"@ -f ([string]$DurationSeconds).PadLeft(2, '0'), $safeText
Set-Content -Path $srtPath -Value $srt -Encoding UTF8

$tokens = @($safeText -split '\s+' | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
if ($tokens.Count -eq 0) { throw "No words found in Text." }

$step = [Math]::Max(0.08, $DurationSeconds / $tokens.Count)
$words = @()
for ($i = 0; $i -lt $tokens.Count; $i++) {
  $start = [Math]::Round($i * $step, 3)
  $end = [Math]::Round([Math]::Min($DurationSeconds, ($i + 1) * $step), 3)
  if ($end -le $start) { $end = [Math]::Round($start + 0.06, 3) }
  $words += [PSCustomObject]@{ word = $tokens[$i]; start = $start; end = $end }
}
@($words) | ConvertTo-Json -Depth 3 | Set-Content -Path $wordsPath -Encoding UTF8

# 4) Generate ASS using the same production script.
& $py $buildAss `
  --srt (AbsPath $srtPath) `
  --words (AbsPath $wordsPath) `
  --out (AbsPath $assPath) `
  --preset $Preset `
  --chunk-size $ChunkSize `
  --max-chars $MaxChars | Out-Host

# 5) Burn captions into the blank base.
# ffmpeg `ass` filter treats `:` as an option separator; escape the drive colon only.
$assAbs = (AbsPath $assPath) -replace '\\', '/'
$assFfmpeg = $assAbs
if ($assFfmpeg.Length -ge 2 -and $assFfmpeg[1] -eq ':') {
  # Escape drive colon for ffmpeg filter parsing: C:/... -> C\:/...
  $assFfmpeg = $assFfmpeg.Substring(0, 1) + '\:' + $assFfmpeg.Substring(2)
}
& $ff -y -i $baseVideo `
  -vf "ass='$assFfmpeg'" `
  -c:a copy `
  $outVideo | Out-Host

Write-Output "BASE: $baseVideo"
Write-Output "FRAME: $framePng"
Write-Output "SRT: $srtPath"
Write-Output "WORDS: $wordsPath"
Write-Output "ASS: $assPath"
Write-Output "OUT: $outVideo"
