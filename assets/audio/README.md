# Audio

Sounds are currently generated procedurally at runtime in
`scripts/managers/AudioManager.gd` (simple synth tones). They work as
placeholders but should be replaced with real recordings for polish.

To swap in real files:

1. Drop `.wav` / `.ogg` files into this folder, e.g.
   - `merge.wav` — satisfying pop/bubble
   - `pickup.wav` — soft click
   - `drop.wav` — soft thud
   - `unlock.wav` — magical chime (first discovery)
   - `button.wav` — UI click
   - `essence.wav` — coin clink
   - `rare_drop.wav` — whoosh
   - `frenzy.wav` — power-up
2. In `AudioManager._ready()`, replace the `_make_*()` calls with
   `preload("res://assets/audio/<file>")` assignments into `_streams`.

Good free sources: freesound.org, zapsplat.com, kenney.nl/assets (CC0).
