param(
  [int]$PageId = 1,
  [int]$Pitch = 0,
  [int]$Speed = 25,
  [int]$Volume = 200
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
  const set = (id, val) => {
    const el = document.getElementById(id);
    if (!el) return { id, ok: false };
    el.value = String(val);
    el.dispatchEvent(new Event(`input`, { bubbles: true }));
    el.dispatchEvent(new Event(`change`, { bubbles: true }));
    return { id, ok: true, value: el.value };
  };

  const out = {
    pitch: set(`pitchSlider`, __PITCH__),
    speed: set(`rateSlider`, __SPEED__),
    volume: set(`volumeSlider`, __VOLUME__),
  };

  const remember = Array.from(document.querySelectorAll(`button, [role=button], a, div, span`))
    .find(n => (n.textContent || ``).trim().toLowerCase() === `remember settings`);
  if (remember) { remember.click(); out.rememberSettings = true; }

  out.now = {
    pitch: document.getElementById(`pitchSlider`) && document.getElementById(`pitchSlider`).value,
    speed: document.getElementById(`rateSlider`) && document.getElementById(`rateSlider`).value,
    volume: document.getElementById(`volumeSlider`) && document.getElementById(`volumeSlider`).value,
  };

  return out;
})()
'@

$js = $js.Replace("__PITCH__", [string]$Pitch).
  Replace("__SPEED__", [string]$Speed).
  Replace("__VOLUME__", [string]$Volume)

browseros-cli eval --page $PageId $js | Out-Host
