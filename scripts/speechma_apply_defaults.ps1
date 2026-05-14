param(
  [int]$PageId = 1,
  [int]$Pitch = 0,
  [int]$Speed = 25,
  [int]$Volume = 200,
  [string]$VoiceLabel = ""
)

$ErrorActionPreference = "Stop"

function Require-Cmd([string]$name) {
  $cmd = Get-Command $name -ErrorAction SilentlyContinue
  if (-not $cmd) { throw "Missing required command on PATH: $name" }
}

Require-Cmd "browseros-cli"

# Speechma effects sliders use stable ids in DOM:
# - pitchSlider (min -100, max 100)
# - rateSlider  (min -100, max 100)  # Speechma labels this as Speed
# - volumeSlider (min 0, max 200)
#
# Important: We use JS template literals (`...`) instead of quoted strings because
# the BrowserOS eval transport can be finicky with quotes/escaping.

$js = @'
(() => {
  const normalize = (s) => (s || ``).toLowerCase().replace(/\s+/g, ` `).trim();
  const requestedVoiceRaw = atob(`__VOICE_B64__`);

  const set = (id, val) => {
    const el = document.getElementById(id);
    if (!el) return { id, ok: false };
    el.value = String(val);
    el.dispatchEvent(new Event(`input`, { bubbles: true }));
    el.dispatchEvent(new Event(`change`, { bubbles: true }));
    return { id, ok: true, value: el.value };
  };

  const out = {
    voice: { ok: false, requested: requestedVoiceRaw },
  };

  // Try selecting requested voice label from Speechma voice list.
  const requestedVoice = normalize(requestedVoiceRaw);
  if (requestedVoice) {
    const openVoiceBtn =
      document.querySelector(`#voice-selection-panel`) ||
      Array.from(document.querySelectorAll(`button, [role=button], a, div, span`))
        .find(n => (n.textContent || ``).toLowerCase().includes(`voice`));
    if (openVoiceBtn) { openVoiceBtn.click(); }

    const candidates = Array.from(document.querySelectorAll(
      `[data-voice-name], .voice-item, .voice-card, .voice-option, li, div, button, a`
    ));
    const hit = candidates.find((el) => {
      const t = normalize(el.textContent || ``);
      return t && t.includes(requestedVoice);
    });
    if (hit) {
      hit.click();
      out.voice = {
        ok: true,
        requested: requestedVoiceRaw,
        selectedText: (hit.textContent || ``).trim().slice(0, 180),
      };
    } else {
      out.voice = { ok: false, requested: requestedVoiceRaw, reason: `not_found` };
    }
  }

  const remember = Array.from(document.querySelectorAll(`button, [role=button], a, div, span`))
    .find(n => (n.textContent || ``).trim().toLowerCase() === `remember settings`);
  if (remember) { remember.click(); out.rememberSettings = true; }

  // Apply sliders after voice selection, because voice change can reset effects.
  out.pitch = set(`pitchSlider`, __PITCH__);
  out.speed = set(`rateSlider`, __SPEED__);
  out.volume = set(`volumeSlider`, __VOLUME__);

  out.now = {
    pitch: document.getElementById(`pitchSlider`) && document.getElementById(`pitchSlider`).value,
    speed: document.getElementById(`rateSlider`) && document.getElementById(`rateSlider`).value,
    volume: document.getElementById(`volumeSlider`) && document.getElementById(`volumeSlider`).value,
  };

  return out;
})()
'@

$voiceB64 = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($VoiceLabel))
$js = $js.Replace("__PITCH__", [string]$Pitch).
  Replace("__SPEED__", [string]$Speed).
  Replace("__VOLUME__", [string]$Volume).
  Replace("__VOICE_B64__", $voiceB64)

browseros-cli eval --page $PageId $js | Out-Host
