"""Configuration for the Fragrantica scraper."""

from pathlib import Path

# --- Paths ---
PROJECT_ROOT = Path(__file__).resolve().parent.parent
DATA_DIR = PROJECT_ROOT / "data"
OUTPUT_FILE = DATA_DIR / "perfumes.json"
FAILED_URLS_FILE = DATA_DIR / "failed_urls.txt"

# --- Target ---
BASE_URL = "https://www.fragrantica.com"

# Seed listing pages. Fragrantica caps search results, so we browse by gender
# and by designer index to widen coverage. These pages list perfumes we can
# then visit individually.
SEED_LISTING_URLS = [
    "https://www.fragrantica.com/search/?gender=men",
    "https://www.fragrantica.com/search/?gender=women",
    "https://www.fragrantica.com/search/?gender=unisex",
]

# --- Scraping behavior ---
TARGET_COUNT = 1000            # stop once we have this many perfumes
SAVE_EVERY = 50                # flush JSON every N successful scrapes
MIN_DELAY_SEC = 3.0            # random delay between page loads
MAX_DELAY_SEC = 8.0
BLOCK_BACKOFF_SEC = 120        # sleep this long if we hit a CAPTCHA/block
MAX_RETRIES = 2                # per perfume page
PAGE_TIMEOUT_MS = 45_000

# --- Browser ---
# Run headed while developing so you can solve any CAPTCHA manually.
# Flip to True once the scrape is stable.
HEADLESS = False

USER_AGENT = (
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) "
    "AppleWebKit/537.36 (KHTML, like Gecko) "
    "Chrome/122.0.0.0 Safari/537.36"
)

VIEWPORT = {"width": 1366, "height": 900}
