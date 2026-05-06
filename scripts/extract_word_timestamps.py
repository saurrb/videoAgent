from __future__ import annotations

import argparse
import json
from pathlib import Path

from faster_whisper import WhisperModel


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Extract word-level timestamps from narration audio.")
    parser.add_argument("--audio", required=True, help="Absolute path to narration audio file (mp3/wav/m4a).")
    parser.add_argument("--out", required=True, help="Absolute path to output JSON file.")
    parser.add_argument("--model", default="small.en", help="faster-whisper model name. Default: small.en")
    parser.add_argument("--language", default="en", help="Language code. Default: en")
    return parser


def main() -> None:
    args = build_parser().parse_args()
    audio = Path(args.audio)
    out_json = Path(args.out)
    out_json.parent.mkdir(parents=True, exist_ok=True)

    model = WhisperModel(args.model, device="cpu", compute_type="int8")
    segments, _ = model.transcribe(
        str(audio),
        language=args.language,
        word_timestamps=True,
        vad_filter=True,
        beam_size=5,
    )

    words = []
    for seg in segments:
        for w in seg.words or []:
            if w.word is None:
                continue
            words.append({"word": w.word.strip(), "start": float(w.start or 0.0), "end": float(w.end or 0.0)})

    out_json.write_text(json.dumps(words, ensure_ascii=True, indent=2), encoding="utf-8")
    print(str(out_json))


if __name__ == "__main__":
    main()
