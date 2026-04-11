# PerfumeFusion

A Godot 4.6 perfume merge/fusion game, plus the Python scraper that produces
its content.

## Web export (Godot)

The game is built for the web (HTML5). Before exporting:

1. Regenerate the slim data file if `data/perfumes.json` has changed:

   ```powershell
   py scripts/data/optimize_data.py
   ```

   This strips the `url` field (only used by the scraper) and writes
   `data/perfumes_slim.json`, which is what the game loads at runtime.
   Saves ~6.5 MB off the build.

2. In Godot: **Project → Export → Web → Export Project**, target
   `export/web/index.html`. The `Web` preset is already defined in
   `export_presets.cfg` and excludes the scraper, raw `perfumes.json`,
   and other non-runtime files.

3. If the Web export template is missing, install it via
   **Editor → Manage Export Templates**.

**Build size target: under 15 MB total** (`index.wasm` + `index.pck` + html shell).
If you blow past that, check `index.pck` first — it's almost certainly the
data file or unstripped assets.

### Test the build locally

```powershell
cd export/web
py -m http.server 8000
```

Then open <http://localhost:8000>. Godot 4 web exports require
cross-origin isolation headers (COOP/COEP) for threading; `python -m http.server`
doesn't send them, so threads will be disabled in the local test. That's fine
for smoke-testing — for a proper production-equivalent test, host on a server
that sets `Cross-Origin-Opener-Policy: same-origin` and
`Cross-Origin-Embedder-Policy: require-corp`.

Browser save data (`user://`) maps to IndexedDB, scoped per origin.

## Scraper

Python scraper that pulls perfume data from Fragrantica.com and writes it to
`data/perfumes.json`. The output is game content for a perfume merge/fusion game.

## Setup (Windows PowerShell)

```powershell
py -m pip install -r requirements.txt
py -m playwright install chromium
```

## Run

```powershell
cd scraper
py scraper.py
```

Output is written incrementally to `data/perfumes.json` every 50 perfumes,
so a crash mid-scrape won't lose previous progress — rerun and it resumes
from where it left off (URLs already in the JSON are skipped).

Failed pages are logged to `data/failed_urls.txt` for later retry.

## Configuration

Edit `scraper/config.py` to change:

- `TARGET_COUNT` — how many perfumes to collect (default 1000)
- `SAVE_EVERY` — flush-to-disk interval (default 50)
- `MIN_DELAY_SEC` / `MAX_DELAY_SEC` — random per-request delay (default 3–8s)
- `HEADLESS` — set to `True` for production, `False` while testing / solving
  any CAPTCHA manually
- `SEED_LISTING_URLS` — the browse pages the scraper starts from

## Output schema

Each entry in `data/perfumes.json`:

```json
{
  "name": "Sauvage",
  "brand": "Dior",
  "rating": 4.21,
  "votes": 28450,
  "gender": "men",
  "notes_top": ["pepper", "bergamot"],
  "notes_middle": ["lavender", "geranium"],
  "notes_base": ["ambroxan", "cedar", "labdanum"],
  "image_url": "https://...",
  "url": "https://www.fragrantica.com/perfume/Dior/Sauvage-31861.html"
}
```

## Notes on anti-bot

Fragrantica uses Cloudflare and will sometimes show a CAPTCHA. The scraper:

- Uses a realistic desktop Chrome user-agent
- Waits 3–8 seconds (random) between requests
- Detects common block pages and backs off for 2+ minutes before retrying
- Runs headed by default so you can solve a CAPTCHA by hand the first time

If you get blocked repeatedly, slow the delays down and rerun — progress
resumes from the existing JSON file.
