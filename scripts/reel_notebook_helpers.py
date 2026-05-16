from __future__ import annotations

import json
import shutil
import subprocess
import time
from pathlib import Path

import requests


def detect_speechma_page_id() -> int:
    try:
        raw = subprocess.check_output(["browseros-cli", "pages", "--json"], text=True)
        obj = json.loads(raw)
        for page in obj.get("pages", []):
            if "speechmapro.com" in str(page.get("url", "")):
                return int(page.get("pageId"))
    except Exception:
        pass
    return 0


def load_voices_auto() -> list[str]:
    page_id = detect_speechma_page_id()
    if page_id <= 0:
        return []
    js = r"""(() => { const out=[]; const seen=new Set(); const nodes=Array.from(document.querySelectorAll('[data-voice-name], .voice-item, .voice-card, .voice-option, li, button, a, div')); for (const n of nodes) { const txt=(n.textContent||'').replace(/\s+/g,' ').trim(); if (!txt || txt.length<3 || txt.length>120) continue; const low=txt.toLowerCase(); if (!(low.includes('english') || low.includes('hindi') || low.includes('spanish') || low.includes('multilingual') || low.includes('male') || low.includes('female') || low.includes('india') || low.includes('us') || low.includes('uk'))) continue; if (seen.has(txt)) continue; seen.add(txt); out.push(txt);} return {voices: out.slice(0,400)}; })()"""
    try:
        raw = subprocess.check_output(
            ["browseros-cli", "eval", "--page", str(page_id), js], text=True
        )
        s = raw.strip()
        a, b = s.find("{"), s.rfind("}")
        if a < 0 or b <= a:
            return []
        obj = json.loads(s[a : b + 1])
        return [v for v in obj.get("voices", []) if isinstance(v, str)]
    except Exception:
        return []


def copy_with_retry(src: Path, dst: Path, retries: int = 12, delay: float = 1.0) -> str:
    src = src.resolve()
    dst = dst.resolve()
    if src == dst:
        return "same"
    last = None
    for _ in range(retries):
        try:
            shutil.copy2(str(src), str(dst))
            return "copied"
        except PermissionError as err:
            last = err
            time.sleep(delay)
    raise last if last else RuntimeError("copy failed")


def api_alive(api_url: str) -> bool:
    try:
        return requests.get(api_url + "/health", timeout=2).ok
    except Exception:
        return False


def ensure_api_running(api_url: str, project_root: Path) -> None:
    if api_alive(api_url):
        return
    try:
        subprocess.Popen(
            ["npm.cmd", "run", "speechma:api"],
            cwd=str(project_root),
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            creationflags=0x08000000,
        )
    except FileNotFoundError:
        subprocess.Popen(
            ["node", str(project_root / "scripts" / "speechma_api_server.mjs")],
            cwd=str(project_root),
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            creationflags=0x08000000,
        )
    for _ in range(40):
        if api_alive(api_url):
            return
        time.sleep(1)
    raise RuntimeError("Speechma API did not start on 127.0.0.1:8787.")

