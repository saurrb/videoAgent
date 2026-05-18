param(
  [Parameter(Mandatory = $true)][string]$Topic,
  [Parameter(Mandatory = $true)][string]$SourceDir,
  [string]$ReelRoot = "",
  [string]$LogoPath = "",
  [switch]$SkipBrandValidation
)

$ErrorActionPreference = "Stop"

function Invoke-External {
  param(
    [Parameter(Mandatory = $true)][string]$FilePath,
    [Parameter(Mandatory = $true)][string[]]$ArgumentList,
    [Parameter(Mandatory = $true)][string]$StepName
  )
  & $FilePath @ArgumentList | Out-Host
  if ($LASTEXITCODE -ne 0) {
    throw "$StepName failed with exit code $LASTEXITCODE"
  }
}

$projectRoot = Split-Path $PSScriptRoot -Parent
$date = Get-Date -Format "yyyy-MM-dd"
$hour = Get-Date -Format "HH"

if ([string]::IsNullOrWhiteSpace($ReelRoot)) {
  $ReelRoot = Join-Path $projectRoot "assets\reels\$date`_$hour`_$Topic"
}

$finalDir = Join-Path $ReelRoot "final"
$captionsDir = Join-Path $ReelRoot "captions"
$voiceDir = Join-Path $ReelRoot "voice"
New-Item -ItemType Directory -Force -Path $finalDir, $captionsDir, $voiceDir | Out-Null

$ffmpeg = Join-Path $projectRoot "tools\ffmpeg\ffmpeg-8.1.1-essentials_build\bin\ffmpeg.exe"
if (-not (Test-Path $ffmpeg)) { throw "ffmpeg not found: $ffmpeg" }
if (-not (Test-Path $SourceDir)) { throw "Source dir not found: $SourceDir" }

$concat = Join-Path $SourceDir "concat.txt"
$stitched = Join-Path $finalDir "scenes_stitched.mp4"
$voiced = Join-Path $finalDir "scenes_stitched_voiced.mp4"
$voicedWithMusic = Join-Path $finalDir "scenes_stitched_voiced_with_music.mp4"

$words = Join-Path $captionsDir "word_timestamps.json"
$srt = Join-Path $captionsDir "captions.srt"
$ass = Join-Path $captionsDir "captions.ass"

$finalCaptioned = Join-Path $finalDir "final_captioned.mp4"
$finalCaptionedWithMusic = Join-Path $finalDir "final_captioned_with_music.mp4"
$branded = Join-Path $finalDir "final_captioned_branded.mp4"
$brandedWithMusic = Join-Path $finalDir "final_captioned_branded_with_music.mp4"

$latestMp3 = Get-ChildItem "$env:USERPROFILE\Downloads\*.mp3" -ErrorAction Stop |
  Sort-Object LastWriteTime -Descending |
  Select-Object -First 1
if (-not $latestMp3) { throw "No mp3 found in Downloads." }
$audio = Join-Path $voiceDir "$Topic`_voice.mp3"
Copy-Item $latestMp3.FullName $audio -Force

# Build concat in timestamp order so first-created/downloaded clip is scene 1.
$clips = Get-ChildItem $SourceDir -Filter "*.mp4" | Sort-Object LastWriteTime, Name
if (-not $clips) { throw "No .mp4 clips found in source: $SourceDir" }
$concatLines = $clips | ForEach-Object { "file '$($_.FullName.Replace('\','/'))'" }
# ffmpeg concat demuxer rejects BOM; use UTF8 without BOM.
[System.IO.File]::WriteAllLines($concat, $concatLines, (New-Object System.Text.UTF8Encoding($false)))

Invoke-External -FilePath $ffmpeg -ArgumentList @("-y", "-f", "concat", "-safe", "0", "-i", $concat, "-c", "copy", $stitched) -StepName "Scene stitch"

# Output 1: voice only (existing behavior)
Invoke-External -FilePath $ffmpeg -ArgumentList @("-y", "-i", $stitched, "-i", $audio, "-c:v", "copy", "-c:a", "aac", "-map", "0:v:0", "-map", "1:a:0", "-shortest", $voiced) -StepName "Voice-only mux"

# Output 2: source audio/music + voice mix
Invoke-External -FilePath $ffmpeg -ArgumentList @(
  "-y", "-i", $stitched, "-i", $audio,
  "-filter_complex", "[0:a]volume=0.70[bg];[1:a]volume=2.0[voice];[bg][voice]amix=inputs=2:duration=first:dropout_transition=2[aout]",
  "-map", "0:v:0", "-map", "[aout]", "-c:v", "copy", "-c:a", "aac", "-shortest", $voicedWithMusic
) -StepName "Voice+music mux"

& python (Join-Path $projectRoot "scripts\extract_word_timestamps.py") --audio $audio --out $words | Out-Host
if ($LASTEXITCODE -ne 0) { throw "Word timestamp generation failed with exit code $LASTEXITCODE" }
& python (Join-Path $projectRoot "scripts\build_srt_from_words.py") --words $words --out $srt | Out-Host
if ($LASTEXITCODE -ne 0) { throw "SRT generation failed with exit code $LASTEXITCODE" }
& python (Join-Path $projectRoot "scripts\build_wordtimed_ass.py") --srt $srt --words $words --out $ass --preset logicloom_ref | Out-Host
if ($LASTEXITCODE -ne 0) { throw "ASS generation failed with exit code $LASTEXITCODE" }

$assFilter = $ass.Replace("\", "/").Replace(":", "\:")
Invoke-External -FilePath $ffmpeg -ArgumentList @("-y", "-i", $voiced, "-vf", "ass='$assFilter'", "-c:a", "copy", $finalCaptioned) -StepName "Caption burn (voice-only)"
Invoke-External -FilePath $ffmpeg -ArgumentList @("-y", "-i", $voicedWithMusic, "-vf", "ass='$assFilter'", "-c:a", "copy", $finalCaptionedWithMusic) -StepName "Caption burn (voice+music)"

if ([string]::IsNullOrWhiteSpace($LogoPath)) {
  $LogoPath = Join-Path $projectRoot "assets\branding\dark_rounded_logo4.png"
}

$wmScript = Join-Path $projectRoot "scripts\add_logicloom_watermark.ps1"
$wmArgs1 = @("-ExecutionPolicy", "Bypass", "-File", $wmScript, "-InputVideo", $finalCaptioned, "-OutputVideo", $branded, "-LogoPath", $LogoPath)
$wmArgs2 = @("-ExecutionPolicy", "Bypass", "-File", $wmScript, "-InputVideo", $finalCaptionedWithMusic, "-OutputVideo", $brandedWithMusic, "-LogoPath", $LogoPath)
if ($SkipBrandValidation) {
  $wmArgs1 += "-SkipValidation"
  $wmArgs2 += "-SkipValidation"
}

& powershell @wmArgs1 | Out-Host
if ($LASTEXITCODE -ne 0) { throw "Branding (voice-only) failed with exit code $LASTEXITCODE" }
& powershell @wmArgs2 | Out-Host
if ($LASTEXITCODE -ne 0) { throw "Branding (voice+music) failed with exit code $LASTEXITCODE" }

Write-Host ""
Write-Host "====================================="
Write-Host "FINAL VIDEOS CREATED"
Write-Host $branded
Write-Host $brandedWithMusic
Write-Host "====================================="

# Keep only final deliverables in /final.
$keep = @(
  [System.IO.Path]::GetFullPath($stitched),
  [System.IO.Path]::GetFullPath($branded),
  [System.IO.Path]::GetFullPath($brandedWithMusic)
)
Get-ChildItem -Path $finalDir -File -Filter "*.mp4" | ForEach-Object {
  $p = [System.IO.Path]::GetFullPath($_.FullName)
  if ($keep -notcontains $p) {
    Remove-Item -LiteralPath $_.FullName -Force
  }
}
