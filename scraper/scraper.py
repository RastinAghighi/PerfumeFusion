"""
Fragrantica perfume scraper.

Collects perfume data (name, brand, rating, votes, gender, notes, image, url)
and writes it to data/perfumes.json. Saves incrementally so a crash at
perfume 300 doesn't lose perfumes 1-299.

Run:
    cd scraper
    py scraper.py
"""

import json
import random
import re
import sys
import time
from typing import Optional
from urllib.parse import urljoin

from playwright.sync_api import (
    Page,
    TimeoutError as PlaywrightTimeoutError,
    sync_playwright,
)

import config


# ---------- persistence ----------

def load_existing() -> tuple[list[dict], set[str]]:
    """Load previously scraped perfumes so we can resume."""
    config.DATA_DIR.mkdir(parents=True, exist_ok=True)
    if not config.OUTPUT_FILE.exists():
        return [], set()
    try:
        with config.OUTPUT_FILE.open("r", encoding="utf-8") as f:
            data = json.load(f)
        seen = {p["url"] for p in data if p.get("url")}
        print(f"[resume] loaded {len(data)} existing perfumes")
        return data, seen
    except (json.JSONDecodeError, OSError) as e:
        print(f"[resume] could not read existing file ({e}); starting fresh")
        return [], set()


def save(perfumes: list[dict]) -> None:
    """Atomically write perfumes to the output JSON file."""
    tmp = config.OUTPUT_FILE.with_suffix(".json.tmp")
    with tmp.open("w", encoding="utf-8") as f:
        json.dump(perfumes, f, indent=2, ensure_ascii=False)
    tmp.replace(config.OUTPUT_FILE)


def log_failure(url: str, reason: str) -> None:
    config.DATA_DIR.mkdir(parents=True, exist_ok=True)
    with config.FAILED_URLS_FILE.open("a", encoding="utf-8") as f:
        f.write(f"{url}\t{reason}\n")


# ---------- helpers ----------

def polite_sleep() -> None:
    time.sleep(random.uniform(config.MIN_DELAY_SEC, config.MAX_DELAY_SEC))


def looks_blocked(page: Page) -> bool:
    """Detect CAPTCHA / Cloudflare / generic block pages."""
    try:
        title = (page.title() or "").lower()
    except Exception:
        title = ""
    if any(k in title for k in ("just a moment", "attention required", "captcha")):
        return True
    try:
        body_text = page.locator("body").inner_text(timeout=2000).lower()
    except Exception:
        return False
    markers = ("verify you are human", "cloudflare", "checking your browser", "captcha")
    return any(m in body_text for m in markers)


def goto(page: Page, url: str) -> bool:
    """Navigate with block-detection and exponential backoff."""
    for attempt in range(config.MAX_RETRIES + 1):
        try:
            page.goto(url, timeout=config.PAGE_TIMEOUT_MS, wait_until="domcontentloaded")
        except PlaywrightTimeoutError:
            print(f"  [timeout] {url} (attempt {attempt + 1})")
            time.sleep(10)
            continue
        except Exception as e:
            print(f"  [nav error] {url}: {e}")
            time.sleep(10)
            continue

        if looks_blocked(page):
            wait = config.BLOCK_BACKOFF_SEC * (attempt + 1)
            print(f"  [blocked] backing off {wait}s before retry")
            time.sleep(wait)
            continue
        return True
    return False


# ---------- listing page -> perfume URLs ----------

def collect_perfume_urls(page: Page, listing_url: str) -> list[str]:
    """
    Pull perfume-detail URLs from a listing page. Fragrantica lazy-loads
    results, so we scroll repeatedly until the page stops growing.
    """
    if not goto(page, listing_url):
        print(f"[listing] failed: {listing_url}")
        return []

    prev_count = -1
    stable_rounds = 0
    for _ in range(60):
        page.mouse.wheel(0, 15000)
        time.sleep(1.2)
        count = page.locator('a[href*="/perfume/"]').count()
        if count == prev_count:
            stable_rounds += 1
            if stable_rounds >= 3:
                break
        else:
            stable_rounds = 0
            prev_count = count

    hrefs = page.eval_on_selector_all(
        'a[href*="/perfume/"]',
        "els => els.map(e => e.getAttribute('href'))",
    )
    urls: list[str] = []
    seen: set[str] = set()
    for h in hrefs:
        if not h:
            continue
        full = urljoin(config.BASE_URL, h)
        # Only keep individual perfume pages, not listing/category pages.
        if not re.search(r"/perfume/[^/]+/[^/]+-\d+\.html$", full):
            continue
        if full in seen:
            continue
        seen.add(full)
        urls.append(full)
    print(f"[listing] {listing_url} -> {len(urls)} perfume urls")
    return urls


# ---------- perfume detail page ----------

def _text(page: Page, selector: str) -> Optional[str]:
    try:
        loc = page.locator(selector).first
        if loc.count() == 0:
            return None
        return (loc.inner_text(timeout=2000) or "").strip()
    except Exception:
        return None


def _parse_float(s: Optional[str]) -> Optional[float]:
    if not s:
        return None
    m = re.search(r"(\d+(?:\.\d+)?)", s.replace(",", "."))
    return float(m.group(1)) if m else None


def _parse_int(s: Optional[str]) -> Optional[int]:
    if not s:
        return None
    m = re.search(r"(\d[\d,\.]*)", s)
    return int(m.group(1).replace(",", "").replace(".", "")) if m else None


def _guess_gender_from_url(url: str, page: Page) -> str:
    # Fragrantica encodes gender in header text like "for men", "for women".
    try:
        h1_parent = page.locator("h1").first
        text = h1_parent.inner_text(timeout=2000).lower() if h1_parent.count() else ""
    except Exception:
        text = ""
    if "for women and men" in text or "unisex" in text:
        return "unisex"
    if "for men" in text:
        return "men"
    if "for women" in text:
        return "women"
    return "unisex"


def _extract_notes(page: Page) -> tuple[list[str], list[str], list[str]]:
    """
    Fragrantica's pyramid has three bands labeled Top / Middle / Base Notes.
    The exact DOM varies, so grab any pyramid <h4> headers and the note names
    that follow them.
    """
    top, mid, base = [], [], []
    try:
        js = """
        () => {
          const result = {top: [], middle: [], base: []};
          const headers = Array.from(document.querySelectorAll('h3, h4'));
          const targets = [
            {key: 'top', rx: /top notes/i},
            {key: 'middle', rx: /(middle|heart) notes/i},
            {key: 'base', rx: /base notes/i},
          ];
          for (const h of headers) {
            const t = (h.innerText || '').trim();
            for (const {key, rx} of targets) {
              if (rx.test(t)) {
                // Notes sit in the next sibling pyramid block.
                let sib = h.nextElementSibling;
                let tries = 0;
                while (sib && tries < 3) {
                  const names = Array.from(sib.querySelectorAll('a, div'))
                    .map(e => (e.innerText || '').trim())
                    .filter(x => x && x.length < 40 && !/note/i.test(x));
                  if (names.length) {
                    result[key] = Array.from(new Set(names));
                    break;
                  }
                  sib = sib.nextElementSibling;
                  tries++;
                }
              }
            }
          }
          // Fallback: if pyramid wasn't split, grab the first notes block.
          if (!result.top.length && !result.middle.length && !result.base.length) {
            const block = document.querySelector('#pyramid, .notes-box, pyramid');
            if (block) {
              const names = Array.from(block.querySelectorAll('a'))
                .map(e => (e.innerText || '').trim()).filter(Boolean);
              result.top = Array.from(new Set(names));
            }
          }
          return result;
        }
        """
        data = page.evaluate(js) or {}
        top = [n for n in (data.get("top") or []) if n]
        mid = [n for n in (data.get("middle") or []) if n]
        base = [n for n in (data.get("base") or []) if n]
    except Exception as e:
        print(f"  [notes] extract error: {e}")
    return top, mid, base


def scrape_perfume(page: Page, url: str) -> Optional[dict]:
    if not goto(page, url):
        return None

    # Give the rating widget a moment to hydrate.
    try:
        page.wait_for_selector("h1", timeout=10_000)
    except PlaywrightTimeoutError:
        pass
    time.sleep(1.0)

    # --- name + brand ---
    name = _text(page, "h1")
    if name:
        # H1 often looks like "Sauvage Dior for men"; split off the trailing parts.
        name = re.sub(r"\s+for (men|women|women and men).*$", "", name, flags=re.I).strip()
    brand = _text(page, 'h1 a, [itemprop="brand"]') or _text(page, ".brand")

    if brand and name and name.endswith(brand):
        name = name[: -len(brand)].strip()

    # --- rating / votes ---
    rating_str = _text(page, '[itemprop="ratingValue"]') or _text(page, ".ratingValue")
    votes_str = _text(page, '[itemprop="ratingCount"]') or _text(page, ".voteCount")
    rating = _parse_float(rating_str)
    votes = _parse_int(votes_str)

    # --- image ---
    image_url = None
    try:
        img = page.locator('img[itemprop="image"], #mainpicbox img, .perfume-image img').first
        if img.count():
            image_url = img.get_attribute("src")
            if image_url:
                image_url = urljoin(config.BASE_URL, image_url)
    except Exception:
        pass

    # --- notes ---
    top, middle, base = _extract_notes(page)

    # --- gender ---
    gender = _guess_gender_from_url(url, page)

    if not name or not brand:
        return None

    return {
        "name": name,
        "brand": brand,
        "rating": rating,
        "votes": votes,
        "gender": gender,
        "notes_top": top,
        "notes_middle": middle,
        "notes_base": base,
        "image_url": image_url,
        "url": url,
    }


# ---------- main loop ----------

def main() -> int:
    perfumes, seen_urls = load_existing()

    with sync_playwright() as p:
        browser = p.chromium.launch(headless=config.HEADLESS)
        context = browser.new_context(
            user_agent=config.USER_AGENT,
            viewport=config.VIEWPORT,
            locale="en-US",
        )
        page = context.new_page()

        # 1) Gather candidate perfume URLs from all seed listings.
        candidate_urls: list[str] = []
        candidate_seen: set[str] = set()
        for listing in config.SEED_LISTING_URLS:
            for u in collect_perfume_urls(page, listing):
                if u not in candidate_seen and u not in seen_urls:
                    candidate_seen.add(u)
                    candidate_urls.append(u)
            polite_sleep()

        print(f"[plan] {len(candidate_urls)} new candidate urls; "
              f"target total = {config.TARGET_COUNT}")

        if not candidate_urls and len(perfumes) < config.TARGET_COUNT:
            print("[plan] no new URLs found. Fragrantica may have blocked the "
                  "listing pages — try running headed and solving any CAPTCHA.")

        # 2) Scrape each one.
        scraped_since_save = 0
        for url in candidate_urls:
            if len(perfumes) >= config.TARGET_COUNT:
                break

            try:
                data = scrape_perfume(page, url)
            except Exception as e:
                print(f"  [error] {url}: {e}")
                log_failure(url, f"exception: {e}")
                polite_sleep()
                continue

            if not data:
                log_failure(url, "no data")
            else:
                perfumes.append(data)
                seen_urls.add(url)
                scraped_since_save += 1
                print(f"Scraped {len(perfumes)}/{config.TARGET_COUNT}... "
                      f"{data['brand']} - {data['name']}")

                if scraped_since_save >= config.SAVE_EVERY:
                    save(perfumes)
                    scraped_since_save = 0
                    print(f"  [save] flushed {len(perfumes)} perfumes to disk")

            polite_sleep()

        save(perfumes)
        print(f"[done] total perfumes: {len(perfumes)}")
        browser.close()
    return 0


if __name__ == "__main__":
    sys.exit(main())
