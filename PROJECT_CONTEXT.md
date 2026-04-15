# PROJECT_CONTEXT

## 1. Project Overview

- Project type: Godot 4 perfume merge game with a separate Python content pipeline.
- Runtime entry: [project.godot](C:\Users\moham\OneDrive\Documents\Intro to Greatness\PerfumeFusion\project.godot) -> [MainMenu.tscn](C:\Users\moham\OneDrive\Documents\Intro to Greatness\PerfumeFusion\scenes\ui\MainMenu.tscn).
- Primary runtime style: autoload singleton architecture.
- Main content sources:
  - [data/perfumes_filtered.json](C:\Users\moham\OneDrive\Documents\Intro to Greatness\PerfumeFusion\data\perfumes_filtered.json)
  - [data/opponents.json](C:\Users\moham\OneDrive\Documents\Intro to Greatness\PerfumeFusion\data\opponents.json)
- Offline content pipeline:
  - [scraper/scraper.py](C:\Users\moham\OneDrive\Documents\Intro to Greatness\PerfumeFusion\scraper\scraper.py)
  - [scripts/data/optimize_data.py](C:\Users\moham\OneDrive\Documents\Intro to Greatness\PerfumeFusion\scripts\data\optimize_data.py)

## 2. Core Gameplay Loops

### Free-play

- Enter via [GameScene.gd](C:\Users\moham\OneDrive\Documents\Intro to Greatness\PerfumeFusion\scripts\main\GameScene.gd).
- `SpawnManager` creates tier-1 perfumes using `DataManager`.
- Player drags items on the grid.
- `Grid` resolves drop outcome:
  - place in empty slot
  - merge via `MergeManager`
  - sell via `SellZone` -> `EconomyManager`
- Successful merge:
  - creates next-tier item
  - updates unlocks and stats
  - grants essence in free-play
  - saves progression
- Loop: `spawn -> place/drag -> merge or sell -> reward -> stronger board -> progression`

### Battle

- Enter via [BattleSelect.gd](C:\Users\moham\OneDrive\Documents\Intro to Greatness\PerfumeFusion\scripts\ui\BattleSelect.gd) -> [BattleScene.gd](C:\Users\moham\OneDrive\Documents\Intro to Greatness\PerfumeFusion\scripts\main\BattleScene.gd).
- `OpponentManager.selected_opponent_id` selects the target opponent.
- `BattleScene` initializes timer, HP, intro UI, and starter perfumes.
- Merges still drive the gameplay, but output changes:
  - `MergeManager` routes result to `BattleManager.deal_damage()`
  - `BattleManager` applies tier damage, weakness/resistance modifiers, and combo multiplier
- `BattleScene` listens to battle signals and updates combat UI.
- Victory/defeat resolves in `BattleResult`, then progression is saved.

## 3. Architecture Rules

### Very Important

- Treat autoload managers as the primary system boundaries.
- Prefer `Scenes/UI -> Managers -> Data/Persistence/Platform`.
- Keep gameplay rules in managers, not scattered through scene scripts.
- Do not add new cross-dependencies casually between managers.
- Do not make UI the source of truth for gameplay state.
- Do not bypass manager APIs when a manager already owns a behavior.
- Do not move persistence logic into presentation code.
- Preserve the distinction between:
  - authoritative state: `SaveManager`, `BattleManager`, `EconomyManager`, `SpawnManager`
  - read-only content: `DataManager`, `OpponentManager`
  - presentation: scenes, popups, HUD, FX
- Prefer signals for cross-system reactions over direct reach-ins.
- Any change touching `MergeManager`, `SaveManager`, or `HUD` should be treated as high-risk.

## 4. Key Managers and Responsibilities

### Data / Catalog

- [DataManager.gd](C:\Users\moham\OneDrive\Documents\Intro to Greatness\PerfumeFusion\scripts\data\DataManager.gd)
  - Loads perfume catalog
  - Buckets perfumes into 20 tiers
  - Supplies random perfume by tier
  - Resolves tier lookups and accord colors

- [OpponentManager.gd](C:\Users\moham\OneDrive\Documents\Intro to Greatness\PerfumeFusion\scripts\data\OpponentManager.gd)
  - Loads opponents
  - Tracks selected opponent
  - Computes unlocked opponents from beaten count

### Persistence / Progression

- [SaveManager.gd](C:\Users\moham\OneDrive\Documents\Intro to Greatness\PerfumeFusion\scripts\managers\SaveManager.gd)
  - Owns persistent save blob
  - Stores grid, unlocks, upgrades, stats, audio prefs, battle history
  - Restores progression across sessions

- [EconomyManager.gd](C:\Users\moham\OneDrive\Documents\Intro to Greatness\PerfumeFusion\scripts\managers\EconomyManager.gd)
  - Owns current essence balance
  - Handles rewards, spending, offline earnings

- [SpawnManager.gd](C:\Users\moham\OneDrive\Documents\Intro to Greatness\PerfumeFusion\scripts\managers\SpawnManager.gd)
  - Controls spawn pacing
  - Handles manual spawn, auto spawn, frenzy, cooldowns, spawn costs

- [RareDropManager.gd](C:\Users\moham\OneDrive\Documents\Intro to Greatness\PerfumeFusion\scripts\managers\RareDropManager.gd)
  - Controls timed rare-drop offers
  - Gates reward through ads
  - Calculates bonus spawn tier from current board state

### Battle

- [BattleManager.gd](C:\Users\moham\OneDrive\Documents\Intro to Greatness\PerfumeFusion\scripts\managers\BattleManager.gd)
  - Owns battle state
  - Calculates damage and combo behavior
  - Emits combat signals

### Core Gameplay

- [MergeManager.gd](C:\Users\moham\OneDrive\Documents\Intro to Greatness\PerfumeFusion\scripts\grid\MergeManager.gd)
  - Validates merges
  - Chooses next-tier perfume
  - Updates unlocks and stats
  - Routes merge output to economy or battle
  - Central gameplay orchestrator

## 5. Data Flow

### Content Pipeline

- `scraper.py` produces raw perfume data.
- `optimize_data.py` creates a slimmed variant.
- Runtime currently uses `perfumes_filtered.json`, not `perfumes_slim.json`.

### Startup

- `SaveManager` loads save data.
- `DataManager` loads perfumes and computes tier buckets.
- `OpponentManager` loads battle roster.
- Active scene wires the `Grid` into `SpawnManager`.

### Free-play Runtime Flow

- `HUD` / `SpawnManager` request a spawn.
- `SpawnManager` gets perfume data from `DataManager`.
- `PerfumeItem` enters the grid.
- Player input flows `PerfumeItem -> Grid`.
- `Grid` routes to:
  - `MergeManager`
  - `SellZone` -> `EconomyManager`
- `MergeManager` updates unlocks/stats in `SaveManager`.
- Free-play merge rewards flow to `EconomyManager`.

### Battle Runtime Flow

- `BattleSelect` writes selected opponent id.
- `BattleScene` loads opponent and starts battle.
- Merge result flows `MergeManager -> BattleManager`.
- `BattleManager` emits damage/combo events.
- `BattleScene` renders HP/timer feedback.
- `BattleResult` applies rewards and progression updates.

### Persistence Flow

- `SaveManager` serializes grid state as lightweight item records.
- `GameScene` reconstructs the board by matching saved identity back into `DataManager`.
- Save blob also stores upgrades, unlocks, stats, audio prefs, and battle progress.

## 6. Critical Invariants

- `DataManager` must successfully load perfume data before gameplay systems depend on tier lookup or random selection.
- `OpponentManager` must load opponent data before battle selection and battle boot.
- `SpawnManager.grid_reference` must point at the active grid before spawning or grid snapshotting.
- Grid interactions must preserve exactly one valid ownership path for an item:
  - in a slot
  - being dragged
  - destroyed/consumed
- Merge results must remain mode-correct:
  - free-play merge -> economy reward
  - battle merge -> damage output
- `SaveManager.data` schema must remain backward-compatible unless save migration is handled.
- Free-play save/restore must preserve item identity well enough for `DataManager.find_perfume(...)` to rebuild the board.
- Battle and free-play must not corrupt each other's state.
- The board is currently assumed to be 25 slots in persistence-sensitive logic.
- `perfumes_filtered.json` must continue to provide fields relied on at runtime:
  - `rating`
  - `accords`
  - `gender`
  - `notes_top`
  - `notes_middle`
  - `notes_base`
  - often `url`

## 7. Dependencies Overview

### High-Level Direction

- Intended: `Scenes/UI -> Managers -> Data/Persistence/Platform`
- Actual: also includes manager-to-manager coupling and some reverse dependencies

### Core Runtime Dependencies

- `GameScene` and `BattleScene` are the main composition roots.
- Both scenes wire `Grid` into `SpawnManager`.
- `Grid` depends on `MergeManager` and `EconomyManager`.
- `MergeManager` depends on:
  - `DataManager`
  - `SaveManager`
  - `AudioManager`
  - `SpawnManager`
  - `BattleManager`
  - `EconomyManager`
- `HUD` depends on:
  - `SpawnManager`
  - `EconomyManager`
  - `RareDropManager`
  - `AdManager`
  - `SaveManager`
  - `AudioManager`
- `BattleScene` depends on:
  - `OpponentManager`
  - `BattleManager`
  - `MergeManager`
  - `SpawnManager`
  - `AudioManager`
  - `SaveManager`

### Critical Dependency Pairs

- `DataManager <-> perfumes_filtered.json`
- `SaveManager <-> live grid state`
- `MergeManager <-> EconomyManager / BattleManager`

## 8. Known Risks / Fragile Areas

- Heavy autoload coupling across the codebase.
- `MergeManager` has too many responsibilities.
- Save/load relies on soft identity matching of perfumes.
- Data-contract drift exists between docs and runtime:
  - docs mention `perfumes_slim.json`
  - runtime uses `perfumes_filtered.json`
- Some systems still rely on `url`, even though the optimizer strips it.
- `HUD` bypasses clean manager boundaries in parts of spawn flow.
- Save logic assumes a 25-slot board.
- Async ad/reward callbacks can outlive scene assumptions.
- Persistence code reaches into live gameplay state through manager references.

## 9. Extension Guidelines

### Safer Areas For New Features

- New UI overlays or menus as separate scenes/scripts
- Read-only collection or info views using `DataManager` + `SaveManager`
- New opponents or data tuning within existing schema
- New FX/audio reactions wired from existing signals
- New upgrades isolated to a single owner manager such as `SpawnManager` or `EconomyManager`

### Higher-Risk Areas

- `MergeManager`
- `SaveManager`
- `HUD`
- board shape changes
- save schema changes
- spawn/merge rule changes

### Safe Change Strategy

- Prefer extending existing manager APIs instead of bypassing them.
- Keep new gameplay rules in one owner manager.
- Use signals to notify UI instead of having systems reach into UI directly.
- If changing persistence, verify load compatibility and restore paths.
- If changing data schema, audit all runtime consumers before updating content.
- If changing mode behavior, verify both free-play and battle loops.
