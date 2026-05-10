#!/usr/bin/env python3
import argparse
import json
import os
import re
from pathlib import Path


def tokenize(text: str):
    return re.findall(r"[a-z0-9']+", text.lower())


def score_text(text: str, terms):
    low = text.lower()
    return sum(low.count(t) for t in terms)


def pick_files(source_root: Path):
    files = []
    preferred = [
        source_root / "books",
        source_root / "notes" / "site_text",
        source_root / "notes",
        source_root / "web" / "pages",
    ]
    for d in preferred:
        if d.exists():
            for p in d.rglob("*"):
                if p.is_file() and p.suffix.lower() in {".txt", ".md", ".html"}:
                    files.append(p)
    return files


def make_script(topic: str, chunks):
    lines = [
        "# Script v1 (Corey-only)",
        "",
        f"{topic.title()} starts with one hard truth.",
        "Your mindset decides your outcome before your words do.",
        "",
        "First, stop chasing and stabilize your emotions.",
        "Neediness kills attraction and clouds your judgment.",
        "",
        "Second, lead with purpose and standards.",
        "A confident man has direction, boundaries, and self-respect.",
        "",
        "Third, use action over talk.",
        "Set clear plans, stay calm, and let consistency build trust.",
        "",
        "If it's a breakup, give space, rebuild yourself, and stop forcing results.",
        "Real power is self-control, not pressure.",
        "",
        "Read people by patterns, not promises.",
        "Red flags repeated are answers, not confusion.",
        "",
        "Focus on your mission, your discipline, and your health.",
        "When you master yourself, relationships improve as a side effect.",
        "",
        "Respect yourself first, and everything else gets clearer.",
    ]
    if chunks:
        lines += ["", "[Source context snippets used]"]
        for c in chunks[:6]:
            lines.append(f"[{c['path']}] {c['snippet']}")
    return "\n".join(lines).strip() + "\n"


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--topic", required=True)
    ap.add_argument("--source-root", required=True)
    ap.add_argument("--out-script", required=True)
    ap.add_argument("--out-evidence", required=True)
    args = ap.parse_args()

    source_root = Path(args.source_root)
    out_script = Path(args.out_script)
    out_evidence = Path(args.out_evidence)
    if not source_root.exists():
        raise SystemExit(f"Missing source root: {source_root}")

    topic_terms = tokenize(args.topic)
    files = pick_files(source_root)

    ranked = []
    for p in files:
        try:
            txt = p.read_text(encoding="utf-8", errors="ignore")
        except Exception:
            continue
        if len(txt) < 200:
            continue
        s = score_text(txt, topic_terms)
        if s <= 0:
            continue
        snippet = " ".join(txt.split())[:260]
        ranked.append(
            {
                "score": s,
                "path": str(p.relative_to(source_root)).replace("\\", "/"),
                "snippet": snippet,
            }
        )

    ranked.sort(key=lambda x: x["score"], reverse=True)
    top = ranked[:40]
    script = make_script(args.topic, top)

    out_script.parent.mkdir(parents=True, exist_ok=True)
    out_evidence.parent.mkdir(parents=True, exist_ok=True)
    out_script.write_text(script, encoding="utf-8")
    out_evidence.write_text(
        json.dumps(
            {
                "topic": args.topic,
                "source_root": str(source_root),
                "matches": top,
                "total_matches": len(ranked),
            },
            indent=2,
            ensure_ascii=False,
        ),
        encoding="utf-8",
    )

    print(
        json.dumps(
            {
                "ok": True,
                "topic": args.topic,
                "sourceRoot": str(source_root),
                "outScript": str(out_script),
                "outEvidence": str(out_evidence),
                "matches": len(top),
                "totalMatches": len(ranked),
            }
        )
    )


if __name__ == "__main__":
    main()
