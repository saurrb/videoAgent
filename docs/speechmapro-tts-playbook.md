# Speechma PRO TTS Playbook

Last updated: 2026-05-06

## Goal

Generate consistent reel narration audio from `https://speechmapro.com/` with:

- Voice: `Brian Multilingual`
- Effects: `Pitch=-6`, `Speed=6`, `Volume=150`

And save downloadable MP3 files into local workspace.

## BrowserOS CLI Flow (Default)

1. Open site:

```powershell
.\node_modules\.bin\browseros-cli.cmd open https://speechmapro.com
```

2. Capture UI snapshot and identify IDs for:
   - Text area (`Text to convert to speech`)
   - `Brian Multilingual` card
   - `Generate Audio` button
   - latest row `Download` button

```powershell
.\node_modules\.bin\browseros-cli.cmd snap -p <page_id>
```

3. Select voice card by ID (from `snap` output).
4. Fill text area with **real multiline text** (see newline rule below).
5. Open voice effects and set sliders:
   - Pitch `-6`
   - Speed `6`
   - Volume `150`
6. Generate audio.
7. Download latest generated row (or download-all ZIP).

## Critical Issue We Faced: Literal `\n` Instead of New Lines

### What went wrong

Using quoted strings like:

```powershell
"line1\nline2\nline3"
```

can end up typing the characters `\` and `n` literally in the textbox in this flow.

### Correct method (mandatory)

Use a PowerShell here-string with actual line breaks:

```powershell
$txt = @'
Line 1
Line 2
Line 3
Line 4
Line 5
'@
.\node_modules\.bin\browseros-cli.cmd fill <textbox_id> $txt -p <page_id>
```

Do **not** use `\n` for line breaks in BrowserOS text fill commands.

### Most reliable method (preferred)

Use line-by-line typing with explicit `Enter` key presses:

```powershell
.\node_modules\.bin\browseros-cli.cmd click <textbox_id> -p <page_id>
.\node_modules\.bin\browseros-cli.cmd fill <textbox_id> "Line 1" -p <page_id>
.\node_modules\.bin\browseros-cli.cmd key Enter -p <page_id>
.\node_modules\.bin\browseros-cli.cmd fill <textbox_id> "Line 2" -p <page_id>
```

Repeat for all lines. This avoids accidental escaped text issues.

## Verification Checklist (Must Pass)

1. Screenshot shows text split across multiple visible lines in textbox.
2. Voice card selected: `Brian Multilingual`.
3. Effect values set to `-6`, `6`, `150`.
4. Generated row appears in `Generated Audios`.
5. MP3 file exists locally after download.

## Example Evidence from This Repo

- Multiline input screenshot:
  - `assets/analysis/speechmapro_iter4/01_multiline_input_verified.png`
- Multiline via Enter-key method screenshot:
  - `assets/analysis/speechmapro_iter4/02_multiline_enter_method.png`
- Downloaded MP3:
  - `assets/analysis/speechmapro_iter4/downloads/speechma_audio_Brian Multilingual_at_5_50_20 PM_on_May_6th_2026.mp3`
  - `assets/analysis/speechmapro_iter4/downloads/speechma_audio_Brian Multilingual_at_5_54_01 PM_on_May_6th_2026.mp3`

## Repeat Rule for Future Runs

Every new TTS generation should:

1. Use here-string multiline input.
2. Take at least one pre-generate screenshot.
3. Download and confirm file presence locally.
