# System Design

## System Map

This repo is a Godot 4 game with a separate Python content pipeline.

At runtime, the app starts at [project.godot](C:\Users\moham\OneDrive\Documents\Intro to Greatness\PerfumeFusion\project.godot), launches [MainMenu.tscn](C:\Users\moham\OneDrive\Documents\Intro to Greatness\PerfumeFusion\scenes\ui\MainMenu.tscn), and relies heavily on autoload singletons for data, save state, spawning, economy, battle state, ads, audio, and opponent metadata. The content source is a perfume dataset in [data/perfumes_filtered.json](C:\Users\moham\OneDrive\Documents\Intro to Greatness\PerfumeFusion\data\perfumes_filtered.json) plus opponent definitions in [data/opponents.json](C:\Users\moham\OneDrive\Documents\Intro to Greatness\PerfumeFusion\data\opponents.json).

## Main Modules

### Content/Data

[DataManager.gd](C:\Users\moham\OneDrive\Documents\Intro to Greatness\PerfumeFusion\scripts\data\DataManager.gd): loads perfume JSON, buckets perfumes into 20 rating tiers, exposes random selection, tier lookup, and accord-color lookup.

[OpponentManager.gd](C:\Users\moham\OneDrive\Documents\Intro to Greatness\PerfumeFusion\scripts\data\OpponentManager.gd): loads opponent JSON, tracks currently selected opponent, computes unlocks from beaten count.

### Persistence

[SaveManager.gd](C:\Users\moham\OneDrive\Documents\Intro to Greatness\PerfumeFusion\scripts\managers\SaveManager.gd): owns user://save_data.json, default schema, grid snapshotting, battle stats, beaten opponents, audio prefs, unlocks, upgrades.

### Economy/Progression

[EconomyManager.gd](C:\Users\moham\OneDrive\Documents\Intro to Greatness\PerfumeFusion\scripts\managers\EconomyManager.gd): current essence balance, merge rewards, offline earnings, spend/add APIs.

[SpawnManager.gd](C:\Users\moham\OneDrive\Documents\Intro to Greatness\PerfumeFusion\scripts\managers\SpawnManager.gd): spawns tier-1 or rare-tier perfumes into the grid, manages manual cooldown, auto/frenzy spawn timing, spawn cost scaling.

[RareDropManager.gd](C:\Users\moham\OneDrive\Documents\Intro to Greatness\PerfumeFusion\scripts\managers\RareDropManager.gd): timed rare-drop offer, rewarded-ad gate, calculates bonus spawn tier from current board average.

### Battle

[BattleManager.gd](C:\Users\moham\OneDrive\Documents\Intro to Greatness\PerfumeFusion\scripts\managers\BattleManager.gd): battle state machine, combo tracking, accord weakness/resistance damage math, emits battle signals.

[BattleScene.gd](C:\Users\moham\OneDrive\Documents\Intro to Greatness\PerfumeFusion\scripts\main\BattleScene.gd): battle UI, timer/HP visuals, intro/result flow, subscribes to BattleManager and MergeManager.

### Grid/Core Gameplay

[Grid.gd](C:\Users\moham\OneDrive\Documents\Intro to Greatness\PerfumeFusion\scripts\grid\Grid.gd): owns slots, drop routing, merge-vs-sell-vs-return decisions.

[GridSlot.gd](C:\Users\moham\OneDrive\Documents\Intro to Greatness\PerfumeFusion\scripts\grid\GridSlot.gd): one cell, stores occupied item.

[PerfumeItem.gd](C:\Users\moham\OneDrive\Documents\Intro to Greatness\PerfumeFusion\scripts\grid\PerfumeItem.gd): draggable perfume card, drag/drop input, double-click info popup.

[MergeManager.gd](C:\Users\moham\OneDrive\Documents\Intro to Greatness\PerfumeFusion\scripts\grid\MergeManager.gd): validates merges, chooses next-tier perfume, animates merge, updates unlock/stats, routes output to battle damage or economy reward.

[SellZone.gd](C:\Users\moham\OneDrive\Documents\Intro to Greatness\PerfumeFusion\scripts\grid\SellZone.gd): sell values and sell feedback UI.

### Top-level Scenes/UI

[GameScene.gd](C:\Users\moham\OneDrive\Documents\Intro to Greatness\PerfumeFusion\scripts\main\GameScene.gd): free-play scene bootstrap, grid restore, tutorial/offline popup handling.

[HUD.gd](C:\Users\moham\OneDrive\Documents\Intro to Greatness\PerfumeFusion\scripts\ui\HUD.gd): main in-game controls for manual spawn, shop, rare drop, frenzy, menu, cooldown display.

[MainMenu.gd](C:\Users\moham\OneDrive\Documents\Intro to Greatness\PerfumeFusion\scripts\ui\MainMenu.gd): scene navigation.

[BattleSelect.gd](C:\Users\moham\OneDrive\Documents\Intro to Greatness\PerfumeFusion\scripts\ui\BattleSelect.gd): opponent browser and battle entry.

[Encyclopedia.gd](C:\Users\moham\OneDrive\Documents\Intro to Greatness\PerfumeFusion\scripts\ui\Encyclopedia.gd): collection browser over all perfumes, filtered by tier/gender, locked/unlocked display.

[InfoCard.gd](C:\Users\moham\OneDrive\Documents\Intro to Greatness\PerfumeFusion\scripts\ui\InfoCard.gd): perfume detail modal.

[BattleResult.gd](C:\Users\moham\OneDrive\Documents\Intro to Greatness\PerfumeFusion\scripts\ui\BattleResult.gd): reward/stat summary after battle.

[Tutorial.gd](C:\Users\moham\OneDrive\Documents\Intro to Greatness\PerfumeFusion\scripts\ui\Tutorial.gd), [WelcomeBack.gd](C:\Users\moham\OneDrive\Documents\Intro to Greatness\PerfumeFusion\scripts\ui\WelcomeBack.gd), [Shop.gd](C:\Users\moham\OneDrive\Documents\Intro to Greatness\PerfumeFusion\scripts\ui\Shop.gd), [Settings.gd](C:\Users\moham\OneDrive\Documents\Intro to Greatness\PerfumeFusion\scripts\ui\Settings.gd): supporting overlays.

### Platform Services

[AdManager.gd](C:\Users\moham\OneDrive\Documents\Intro to Greatness\PerfumeFusion\scripts\managers\AdManager.gd): Poki/CrazyGames/AdMob routing, rewarded ads, commercial breaks.

[AudioManager.gd](C:\Users\moham\OneDrive\Documents\Intro to Greatness\PerfumeFusion\scripts\managers\AudioManager.gd): procedural SFX, BGM volume/mute prefs.

## Dependency Shape

GameScene and BattleScene are the main composition roots.

Both scenes wire Grid into SpawnManager.

Grid delegates merges to MergeManager and sales to EconomyManager.

MergeManager depends on DataManager, SaveManager, AudioManager, SpawnManager, BattleManager, and EconomyManager.

HUD depends on SpawnManager, EconomyManager, RareDropManager, AdManager, SaveManager, and AudioManager.

BattleScene depends on OpponentManager, BattleManager, MergeManager, SpawnManager, AudioManager, SaveManager.

Encyclopedia and InfoCard read directly from DataManager plus unlock state in SaveManager.

A compact dependency graph looks like this:

```text
scraper.py -> data/perfumes.json
optimize/curation -> data/perfumes_filtered.json
data/perfumes_filtered.json -> DataManager
data/opponents.json -> OpponentManager

MainMenu -> GameScene | BattleSelect | Encyclopedia | Settings

GameScene -> Grid + HUD + Tutorial/WelcomeBack
BattleSelect -> OpponentManager.selected_opponent_id -> BattleScene

Grid/PerfumeItem -> MergeManager | SellZone
MergeManager -> DataManager + SaveManager + AudioManager + SpawnManager
MergeManager -> BattleManager (battle mode)
MergeManager -> EconomyManager (free play)

HUD -> SpawnManager + EconomyManager + RareDropManager + AdManager
SaveManager <-> most managers/scenes
AudioManager <- UI/gameplay events
```

## Data Flow

### Content pipeline

[scraper/scraper.py](C:\Users\moham\OneDrive\Documents\Intro to Greatness\PerfumeFusion\scraper\scraper.py) scrapes Fragrantica into data/perfumes.json.

[scripts/data/optimize_data.py](C:\Users\moham\OneDrive\Documents\Intro to Greatness\PerfumeFusion\scripts\data\optimize_data.py) strips fields for lighter runtime output.

Runtime currently loads data/perfumes_filtered.json, which appears to be a curated/filtered dataset rather than the optimizer's perfumes_slim.json.

### Startup

SaveManager loads persisted state.

DataManager loads all perfumes and precomputes tier buckets.

OpponentManager loads battle roster.

Top scene sets the active grid in SpawnManager.

### Free-play loop

HUD/manual spawn or timed spawn asks SpawnManager for a tier-1 item.

SpawnManager pulls random perfume data from DataManager and instantiates PerfumeItem.

Player drags item; Grid routes drop.

Sell path: Grid -> SellZone.get_sell_value() -> EconomyManager.add_essence() -> SaveManager.save_game().

Merge path: Grid -> MergeManager.execute_merge().

MergeManager picks next-tier perfume from DataManager, animates replacement, updates unlocks/stats in SaveManager.

In free play, merge reward goes to EconomyManager; in battle, result goes to BattleManager.deal_damage().

### Battle loop

BattleSelect writes OpponentManager.selected_opponent_id.

BattleScene loads that opponent, shows intro, starts BattleManager.

Merges trigger BattleManager.deal_damage() via MergeManager.

BattleManager applies tier base damage, accord weakness/resistance modifiers, and combo multiplier.

BattleScene listens to battle signals and updates HP/timer/result UI.

BattleResult pays essence, marks beaten opponents, and persists battle stats.

### Persistence

SaveManager stores grid state as tier + name + brand + url.

On free-play load, GameScene reconstructs items by asking DataManager.find_perfume(...).

Audio preferences, upgrades, unlocks, essence, stats, and beaten opponents all live in the same save blob.

## Saved / Loaded Schemas

SaveManager.data contains:

- grid_state
- unlocked_perfumes
- essence
- total_spawns
- upgrades
- last_logout_time
- stats
- audio
- tutorial_completed
- beaten_opponents
- battle_stats

perfumes_filtered.json entries contain fields like:

- name, brand, gender, rating, votes, accords, notes_top, notes_middle, notes_base, country, year

opponents.json entries contain:

- id, name, title, description, hp, time_limit, weakness, resistance, reward_essence, unlock_requirement

## Responsibilities by Area

### Authoritative state

SaveManager for persistence

BattleManager for combat state

EconomyManager for currency

SpawnManager for spawn timing/rules

### Read-only catalog

DataManager and OpponentManager

### User interaction

PerfumeItem, Grid, HUD, scene scripts

### Presentation/effects

BattleScene, InfoCard, ScreenShake, AudioManager

### External/platform

AdManager

### Offline content generation

Python scraper and optimizer scripts

## Notable Architectural Traits

The project is strongly singleton-driven; most scripts reach directly into autoloads instead of using injected dependencies.

Scenes are fairly thin composition layers; gameplay rules mostly live in managers.

MergeManager is the most central gameplay orchestrator because it touches unlocks, stats, economy, spawning progression, battle damage, audio, and info popups.

There's a small mismatch between docs and runtime: the README talks about perfumes_slim.json, but DataManager actually loads perfumes_filtered.json.
