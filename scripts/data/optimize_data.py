"""Strip fields not needed at runtime from perfumes.json.

Reads data/perfumes.json, removes the "url" field from each entry, and writes
the result to data/perfumes_slim.json. The url is only used by the scraper for
dedup; the game itself never reads it, and dropping it saves ~1MB in the web
build.

Run from the repo root:
    py scripts/data/optimize_data.py
"""

from __future__ import annotations

import json
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
SRC = REPO_ROOT / "data" / "perfumes.json"
DST = REPO_ROOT / "data" / "perfumes_slim.json"

STRIP_FIELDS = ("url",)


def main() -> None:
    with SRC.open("r", encoding="utf-8") as f:
        perfumes = json.load(f)

    if not isinstance(perfumes, list):
        raise SystemExit(f"{SRC} did not parse to a list")

    for entry in perfumes:
        if not isinstance(entry, dict):
            continue
        for field in STRIP_FIELDS:
            entry.pop(field, None)

    with DST.open("w", encoding="utf-8") as f:
        json.dump(perfumes, f, ensure_ascii=False, separators=(",", ":"))

    src_kb = SRC.stat().st_size / 1024
    dst_kb = DST.stat().st_size / 1024
    print(f"Wrote {DST.name}: {len(perfumes)} entries, {dst_kb:.1f} KB "
          f"(was {src_kb:.1f} KB, saved {src_kb - dst_kb:.1f} KB)")


if __name__ == "__main__":
    main()
