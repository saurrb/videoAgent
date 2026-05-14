import http from "node:http";
import fs from "node:fs";
import path from "node:path";
import os from "node:os";
import { promisify } from "node:util";
import { execFile as execFileCb } from "node:child_process";

const execFile = promisify(execFileCb);

const PORT = Number(process.env.SPEECHMA_API_PORT || 8787);
const HOST = process.env.SPEECHMA_API_HOST || "127.0.0.1";
const REPO_ROOT = process.cwd();

function json(res, status, data) {
  const body = JSON.stringify(data, null, 2);
  res.writeHead(status, { "Content-Type": "application/json; charset=utf-8" });
  res.end(body);
}

async function run(cmd, args, opts = {}) {
  try {
    const { stdout, stderr } = await execFile(cmd, args, {
      cwd: REPO_ROOT,
      maxBuffer: 1024 * 1024 * 20,
      ...opts,
    });
    return { stdout: stdout ?? "", stderr: stderr ?? "" };
  } catch (error) {
    const stdout = error.stdout ?? "";
    const stderr = error.stderr ?? "";
    throw new Error(
      `Command failed: ${cmd} ${args.join(" ")}\n${stdout}\n${stderr}\n${error.message}`,
    );
  }
}

function parseJsonFromOutput(text) {
  const trimmed = text.trim();
  const start = trimmed.indexOf("{");
  const end = trimmed.lastIndexOf("}");
  if (start < 0 || end < 0 || end <= start) {
    throw new Error(`Could not parse JSON from output: ${trimmed.slice(0, 400)}`);
  }
  return JSON.parse(trimmed.slice(start, end + 1));
}

async function detectSpeechmaPageId() {
  const { stdout } = await run("browseros-cli", ["pages", "--json"]);
  const parsed = JSON.parse(stdout);
  const pages = parsed.pages || [];
  const hit = pages.find((p) => String(p.url || "").includes("speechmapro.com"));
  if (!hit) return null;
  return Number(hit.pageId);
}

async function ensureSpeechmaPageId(preferredPageId) {
  const { stdout } = await run("browseros-cli", ["pages", "--json"]);
  const parsed = JSON.parse(stdout);
  const pages = parsed.pages || [];

  if (Number.isFinite(Number(preferredPageId))) {
    const preferred = pages.find((p) => Number(p.pageId) === Number(preferredPageId));
    if (preferred && String(preferred.url || "").includes("speechmapro.com")) {
      return Number(preferred.pageId);
    }
  }

  const existing = pages.find((p) => String(p.url || "").includes("speechmapro.com"));
  if (existing) return Number(existing.pageId);

  // Auto-open Speechma if no tab is available.
  await run("browseros-cli", ["open", "https://speechmapro.com"]);
  await new Promise((r) => setTimeout(r, 2000));
  const detected = await detectSpeechmaPageId();
  if (!detected) {
    throw new Error("Could not open/detect Speechma tab in BrowserOS.");
  }
  return detected;
}

async function setSpeechmaText(pageId, text) {
  const b64 = Buffer.from(text, "utf8").toString("base64");
  const js = `(() => { const b64 = \`${b64}\`; const txt = atob(b64); const el = document.getElementById(\`textInput\`); if(!el) return {ok:false}; el.value = txt; el.dispatchEvent(new Event(\`input\`,{bubbles:true})); el.dispatchEvent(new Event(\`change\`,{bubbles:true})); return {ok:true,len: txt.length}; })()`;
  const { stdout } = await run("browseros-cli", ["eval", "--page", String(pageId), js]);
  return parseJsonFromOutput(stdout);
}

async function getAudioCounts(pageId, phrase) {
  const js = `(() => { const total=[...document.querySelectorAll(\`.audio-text\`)].length; const matches=[...document.querySelectorAll(\`.audio-text\`)].filter(e => (e.textContent||\`\`).includes(\`${phrase.replace(/`/g, "")}\`)).length; return {total, matches}; })()`;
  const { stdout } = await run("browseros-cli", ["eval", "--page", String(pageId), js]);
  return parseJsonFromOutput(stdout);
}

async function clickGenerate(pageId) {
  const js =
    "(() => { const nodes = Array.from(document.querySelectorAll(`button, [role=button], a, div, span`)); const btn = nodes.find(n => (n.textContent || ``).trim().toLowerCase() === `generate audio`); if (!btn) return { ok:false, reason:`no_button` }; btn.click(); return { ok:true }; })()";
  const { stdout } = await run("browseros-cli", ["eval", "--page", String(pageId), js]);
  return parseJsonFromOutput(stdout);
}

async function clickDownloadByPhrase(pageId, phrase) {
  const js = `(() => {
    const phrase = \`${phrase.replace(/`/g, "")}\`;
    const els = [...document.querySelectorAll(\`.audio-text\`)].filter(e => (e.textContent || \`\`).includes(phrase));
    if (!els.length) return { ok:false, reason:\`no_match\` };
    const target = els[0];
    let el = target;
    for (let i=0;i<10 && el;i++) {
      const btn = el.querySelector?.(\`button.audio-control-btn.download-btn\`) || el.querySelector?.(\`button.download-btn\`) || el.querySelector?.(\`.download-btn\`);
      if (btn) { btn.click(); return { ok:true, level:i }; }
      el = el.parentElement;
    }
    return { ok:false, reason:\`no_btn\` };
  })()`.replace(/\r?\n/g, " ");
  const { stdout } = await run("browseros-cli", ["eval", "--page", String(pageId), js]);
  return parseJsonFromOutput(stdout);
}

function latestSpeechmaDownload() {
  const downloads = path.join(os.homedir(), "Downloads");
  const files = fs
    .readdirSync(downloads)
    .filter((name) => /^speechma_audio_.*\.mp3$/i.test(name))
    .map((name) => {
      const full = path.join(downloads, name);
      const st = fs.statSync(full);
      return { name, full, mtimeMs: st.mtimeMs };
    })
    .sort((a, b) => b.mtimeMs - a.mtimeMs);
  return files[0] || null;
}

async function ffprobeDuration(filePath) {
  const ffprobe = path.join(
    REPO_ROOT,
    "tools",
    "ffmpeg",
    "ffmpeg-8.1.1-essentials_build",
    "bin",
    "ffprobe.exe",
  );
  const { stdout } = await run(ffprobe, [
    "-v",
    "error",
    "-show_entries",
    "format=duration",
    "-of",
    "default=noprint_wrappers=1:nokey=1",
    filePath,
  ]);
  return Number(stdout.trim());
}

async function speechmaRun(payload) {
  const workspace = payload.workspacePath;
  if (!workspace || !path.isAbsolute(workspace)) {
    throw new Error("workspacePath must be an absolute path.");
  }
  if (!fs.existsSync(workspace)) {
    throw new Error(`workspacePath does not exist: ${workspace}`);
  }

  const scriptPath = payload.scriptPath || path.join(workspace, "script", "script_v1.txt");
  const sourceRoot =
    payload.sourceRoot || path.join(REPO_ROOT, "coreywayne");
  const evidencePath =
    payload.evidencePath || path.join(workspace, "meta", "corey_topic_evidence.json");
  const outInputPath = payload.inputPath || path.join(workspace, "voice", "speechma_input_v1.txt");
  const proofDir = payload.proofDir || path.join(workspace, "analysis", "speechma_proof_api");
  const outVoicePath = payload.outputVoicePath || path.join(workspace, "voice", "voice_v1.mp3");
  const phraseFromPayload = payload.matchPhrase;
  const pitch = Number(payload.pitch ?? 0);
  const speed = Number(payload.speed ?? 25);
  const volume = Number(payload.volume ?? 200);
  const voiceLabel = String(payload.voiceLabel ?? "").trim();
  const pageId = await ensureSpeechmaPageId(payload.pageId);

  if (payload.topic) {
    await run("python", [
      path.join(REPO_ROOT, "scripts", "generate_corey_topic_script.py"),
      "--topic",
      String(payload.topic),
      "--source-root",
      sourceRoot,
      "--out-script",
      scriptPath,
      "--out-evidence",
      evidencePath,
    ]);
  }

  await run("powershell", [
    "-ExecutionPolicy",
    "Bypass",
    "-File",
    path.join(REPO_ROOT, "scripts", "prepare_speechma_input.ps1"),
    "-ScriptPath",
    scriptPath,
    "-OutPath",
    outInputPath,
  ]);

  await run("powershell", [
    "-ExecutionPolicy",
    "Bypass",
    "-File",
    path.join(REPO_ROOT, "scripts", "speechma_apply_defaults.ps1"),
    "-PageId",
    String(pageId),
    "-Pitch",
    String(pitch),
    "-Speed",
    String(speed),
    "-Volume",
    String(volume),
    "-VoiceLabel",
    voiceLabel,
  ]);

  const cleanText = fs.readFileSync(outInputPath, "utf8");
  const firstLine = cleanText
    .split(/\r?\n/)
    .map((s) => s.trim())
    .find((s) => s.length > 0);
  const phrase = phraseFromPayload || firstLine || "The smartest person you know";
  const setRes = await setSpeechmaText(pageId, cleanText);
  if (!setRes.ok) {
    throw new Error("Failed to set Speechma text input.");
  }

  await run("powershell", [
    "-ExecutionPolicy",
    "Bypass",
    "-File",
    path.join(REPO_ROOT, "scripts", "speechma_capture_proof.ps1"),
    "-PageId",
    String(pageId),
    "-OutDir",
    proofDir,
    "-Pitch",
    String(pitch),
    "-Speed",
    String(speed),
    "-Volume",
    String(volume),
  ]);

  const before = await getAudioCounts(pageId, phrase);
  const startedAt = Date.now();
  const genRes = await clickGenerate(pageId);
  if (!genRes.ok) {
    throw new Error(`Could not click Generate Audio: ${JSON.stringify(genRes)}`);
  }

  let detected = false;
  for (let i = 0; i < 36; i += 1) {
    await new Promise((r) => setTimeout(r, 5000));
    const now = await getAudioCounts(pageId, phrase);
    if (now.total > before.total || now.matches > before.matches) {
      detected = true;
      break;
    }
  }
  if (!detected) {
    throw new Error("Timed out waiting for a new Speechma generated row.");
  }

  const dlRes = await clickDownloadByPhrase(pageId, phrase);
  if (!dlRes.ok) {
    throw new Error(`Could not click download: ${JSON.stringify(dlRes)}`);
  }
  await new Promise((r) => setTimeout(r, 4000));

  const latest = latestSpeechmaDownload();
  if (!latest) {
    throw new Error("No speechma_audio_*.mp3 found in Downloads.");
  }
  if (latest.mtimeMs < startedAt - 2000) {
    throw new Error(`Latest Speechma download appears stale: ${latest.name}`);
  }

  fs.mkdirSync(path.dirname(outVoicePath), { recursive: true });
  fs.renameSync(latest.full, outVoicePath);
  const duration = await ffprobeDuration(outVoicePath);

  return {
    ok: true,
    pageId,
    scriptPath,
    inputPath: outInputPath,
    outputVoicePath: outVoicePath,
    proofDir,
    downloadedFile: latest.full,
    durationSeconds: duration,
    settings: { pitch, speed, volume, voiceLabel },
    matchPhraseUsed: phrase,
    topic: payload.topic || null,
    sourceRoot: payload.topic ? sourceRoot : null,
    evidencePath: payload.topic ? evidencePath : null,
  };
}

function readJsonBody(req) {
  return new Promise((resolve, reject) => {
    const chunks = [];
    req.on("data", (d) => chunks.push(d));
    req.on("end", () => {
      try {
        const raw = Buffer.concat(chunks).toString("utf8");
        resolve(raw ? JSON.parse(raw) : {});
      } catch (err) {
        reject(err);
      }
    });
    req.on("error", reject);
  });
}

const server = http.createServer(async (req, res) => {
  try {
    if (req.method === "GET" && req.url === "/health") {
      return json(res, 200, { ok: true, service: "speechma-local-api" });
    }
    if (req.method === "POST" && req.url === "/speechma/run") {
      const payload = await readJsonBody(req);
      const result = await speechmaRun(payload);
      return json(res, 200, result);
    }
    return json(res, 404, { ok: false, error: "Not found" });
  } catch (err) {
    return json(res, 500, { ok: false, error: err.message });
  }
});

server.listen(PORT, HOST, () => {
  console.log(`Speechma local API running at http://${HOST}:${PORT}`);
  console.log("POST /speechma/run");
});
