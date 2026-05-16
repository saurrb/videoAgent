from __future__ import annotations

import json
from pathlib import Path

import ipywidgets as widgets
import requests
from IPython.display import display

from scripts.reel_notebook_helpers import (
    copy_with_retry,
    ensure_api_running,
    load_voices_auto,
)


def step2_ui(
    reel_root: Path,
    script_from_cell: Path,
    input_from_cell: Path,
    settings_json: Path,
) -> None:
    saved = {"voiceLabel": "", "pitch": 0, "speed": 25, "volume": 200}
    if settings_json.exists():
        try:
            old = json.loads(settings_json.read_text(encoding="utf-8"))
            for k in saved:
                if k in old:
                    saved[k] = old[k]
        except Exception:
            pass

    title = widgets.HTML(f"<b>Step 2: Narration + Voice Settings</b><br><code>{reel_root}</code>")
    text_box = widgets.Textarea(
        value="",
        placeholder="Paste your Speechma narration text here...",
        layout=widgets.Layout(width="100%", height="220px"),
    )
    load_voices_btn = widgets.Button(description="Load Voices", button_style="info", icon="refresh")
    load_default_btn = widgets.Button(
        description="Load Default Setting", button_style="warning", icon="download"
    )

    saved_voice = str(saved.get("voiceLabel") or "")
    voice_opts = [("Default (Current Speechma voice)", "")]
    if saved_voice:
        voice_opts.append((f"Saved: {saved_voice}", saved_voice))
    voice_dropdown = widgets.Dropdown(
        options=voice_opts,
        value=(saved_voice if saved_voice else ""),
        description="Voice:",
        layout=widgets.Layout(width="95%"),
    )
    pitch_slider = widgets.IntSlider(value=int(saved["pitch"]), min=-100, max=100, step=1, description="Pitch:")
    speed_slider = widgets.IntSlider(value=int(saved["speed"]), min=-100, max=100, step=1, description="Speed:")
    volume_slider = widgets.IntSlider(value=int(saved["volume"]), min=0, max=200, step=1, description="Volume:")
    save_btn = widgets.Button(description="Save Text + Settings", button_style="success", icon="save")
    status = widgets.Output()

    def on_load_voices(_):
        with status:
            status.clear_output()
            voices = load_voices_auto()
            if not voices:
                print("No voices detected. Open Speechma voice panel and try again.")
                return
            opts = [("Default (Current Speechma voice)", "")] + [(v, v) for v in voices]
            if saved_voice and saved_voice not in [v for _, v in opts]:
                opts.append((f"Saved: {saved_voice}", saved_voice))
            voice_dropdown.options = opts
            if saved_voice:
                voice_dropdown.value = saved_voice
            print(f"Loaded {len(voices)} voice options from active Speechma tab.")

    def on_load_default(_):
        with status:
            status.clear_output()
            if not settings_json.exists():
                print("No saved defaults found yet.")
                return
            cfg = json.loads(settings_json.read_text(encoding="utf-8"))
            pitch_slider.value = int(cfg.get("pitch", 0) or 0)
            speed_slider.value = int(cfg.get("speed", 25) or 25)
            volume_slider.value = int(cfg.get("volume", 200) or 200)
            v = str(cfg.get("voiceLabel", "") or "")
            if v and v not in [x for _, x in voice_dropdown.options]:
                voice_dropdown.options = list(voice_dropdown.options) + [(f"Saved: {v}", v)]
            voice_dropdown.value = v if v else ""
            print("Loaded default settings.")

    def on_save(_):
        with status:
            status.clear_output()
            script_from_cell.parent.mkdir(parents=True, exist_ok=True)
            input_from_cell.parent.mkdir(parents=True, exist_ok=True)
            settings_json.parent.mkdir(parents=True, exist_ok=True)
            text = text_box.value.replace("\r", "").strip()
            if not text:
                script_from_cell.write_text("", encoding="utf-8")
                input_from_cell.write_text("", encoding="utf-8")
                print(
                    "Narration text is empty. Cleared saved speech text. Step 3 will be blocked until you save non-empty text."
                )
            else:
                script_from_cell.write_text(text + "\n", encoding="utf-8")
                input_from_cell.write_text(text + "\n", encoding="utf-8")
            settings = {
                "pageId": 0,
                "voiceLabel": str(voice_dropdown.value or ""),
                "pitch": int(pitch_slider.value),
                "speed": int(speed_slider.value),
                "volume": int(volume_slider.value),
            }
            settings_json.write_text(json.dumps(settings, indent=2), encoding="utf-8")
            print("Saved as default settings:", settings)

    load_voices_btn.on_click(on_load_voices)
    load_default_btn.on_click(on_load_default)
    save_btn.on_click(on_save)
    display(
        widgets.VBox(
            [
                title,
                text_box,
                widgets.HBox([load_voices_btn, load_default_btn]),
                voice_dropdown,
                pitch_slider,
                speed_slider,
                volume_slider,
                save_btn,
                status,
            ]
        )
    )


def run_step3(
    project_root: Path,
    reel_root: Path,
    voice_dir: Path,
    audio: Path,
    script_from_cell: Path,
    settings_json: Path,
    api_url: str = "http://127.0.0.1:8787",
):
    bar = widgets.IntProgress(
        value=0, min=0, max=100, description="Step 3:", bar_style="info", layout=widgets.Layout(width="70%")
    )
    status = widgets.HTML("Preparing Speechma API...")
    display(widgets.VBox([bar, status]))

    bar.value = 10
    status.value = "Checking local Speechma API..."
    ensure_api_running(api_url, project_root)

    if not script_from_cell.exists():
        bar.bar_style = "danger"
        status.value = f"Missing input file: <code>{script_from_cell}</code>. Run Step 2 first."
        raise FileNotFoundError(str(script_from_cell))
    text_for_speechma = script_from_cell.read_text(encoding="utf-8").strip()
    if not text_for_speechma:
        bar.bar_style = "danger"
        status.value = "Step 3 blocked: narration text is blank. Paste text in Step 2 and save again."
        raise RuntimeError("Narration text is blank in script_from_cell.txt")

    settings = {"pageId": 0, "voiceLabel": "", "pitch": 0, "speed": 25, "volume": 200}
    if settings_json.exists():
        loaded = json.loads(settings_json.read_text(encoding="utf-8"))
        settings.update({k: loaded.get(k, settings[k]) for k in settings})

    payload = {
        "workspacePath": str(reel_root),
        "scriptPath": str(script_from_cell),
        "pageId": int(settings["pageId"] or 0),
        "voiceLabel": str(settings["voiceLabel"] or ""),
        "pitch": int(settings["pitch"] or 0),
        "speed": int(settings["speed"] or 25),
        "volume": int(settings["volume"] or 200),
    }
    bar.value = 45
    status.value = "Calling local Speechma API..."
    data = requests.post(api_url + "/speechma/run", json=payload, timeout=600).json()
    if not data.get("ok"):
        bar.bar_style = "danger"
        status.value = f"Speechma API failed: <code>{data.get('error','unknown error')}</code>"
        raise RuntimeError(data.get("error", "Speechma API failed"))

    bar.value = 80
    status.value = "Finalizing voice file..."
    voice_dir.mkdir(parents=True, exist_ok=True)
    api_out = Path(data.get("outputVoicePath", "")) if data.get("outputVoicePath") else None
    if api_out and api_out.exists():
        result = copy_with_retry(api_out, audio)
    else:
        candidates = sorted(
            (Path.home() / "Downloads").glob("speechma_audio_*.mp3"),
            key=lambda p: p.stat().st_mtime,
            reverse=True,
        )
        if not candidates:
            bar.bar_style = "danger"
            status.value = "No Speechma MP3 found in API output or Downloads."
            raise RuntimeError("No Speechma MP3 found")
        result = copy_with_retry(candidates[0], audio)

    bar.value = 100
    bar.bar_style = "success"
    status.value = f"Done ({result}). Voice ready at <code>{audio}</code>"
    return data
