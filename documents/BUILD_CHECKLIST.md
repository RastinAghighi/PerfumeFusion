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

## Poki

- [ ] Custom shell template (`export/web/custom_shell.html`) selected in
      export settings (Export → Web → Options → HTML → Custom HTML Shell)
- [ ] Poki SDK `<script>` tag present in the exported `index.html`
- [ ] `PokiSDK.init()` called on load (see `AdManager.init_poki()` wired
      from `GameScene._ready()` behind `OS.has_feature("web")`)
- [ ] `PokiSDK.gameLoadingFinished()` fires after engine start (confirm in
      browser devtools network/console)
- [ ] Rewarded ads tested end-to-end on Poki's test environment —
      double-offline and frenzy-mode rewards actually trigger
- [ ] `show_commercial_break()` called between major screen transitions,
      but not more than once every 3 minutes
- [ ] Game submitted at developers.poki.com

## Final

- [ ] Tab title and favicon set to something other than "Godot Engine"
- [ ] Loading screen / splash isn't a black void for 10 seconds
