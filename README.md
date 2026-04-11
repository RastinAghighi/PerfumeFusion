# PerfumeFusion — Scraper

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
