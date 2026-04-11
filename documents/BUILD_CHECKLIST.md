# Web build checklist

Run through this before publishing a web build to Poki / CrazyGames / itch.io.

## Pre-export

- [ ] `AdManager.is_test_mode = false` in `scripts/managers/AdManager.gd`
- [ ] Real ad-network bridge wired up (Phase 7 TODOs in `AdManager.gd`)
- [ ] `data/perfumes_slim.json` exists and is up to date
      (`py scripts/data/optimize_data.py`)
- [ ] `DataManager.PERFUMES_PATH` points at `perfumes_slim.json`
- [ ] No `print()` spam left in hot paths
- [ ] Version string bumped (if you track one)

## Export

- [ ] **Project → Export → Web → Export Project** to `export/web/index.html`
- [ ] Total build size under 15 MB (`index.wasm` + `index.pck` + shell)
- [ ] `index.pck` does not contain `data/perfumes.json` (raw file) or `scraper/`

## Browser smoke test

- [ ] Loads in **Chrome** (desktop) without console errors
- [ ] Loads in **Firefox** (desktop) without console errors
- [ ] Loads on a **mobile browser** (Chrome Android or Safari iOS); touch
      input works for drag/merge
- [ ] Audio plays after first user interaction (browsers block autoplay)
- [ ] Volume sliders + mute toggle persist across reload

## Save / load

- [ ] Earn coins, merge a few tiles, reload the page → progress restored
      (`user://` is backed by IndexedDB, scoped per origin)
- [ ] Reset progress button clears the save and starts fresh
- [ ] Offline earnings credit on next load
- [ ] Rewarded-ad rewards (double offline, frenzy mode) actually trigger
      from a real ad, not the test-mode timer

## Final

- [ ] Tab title and favicon set to something other than "Godot Engine"
- [ ] Loading screen / splash isn't a black void for 10 seconds
