# AGENT_QUICKSTART

## Read First

1. `PROJECT_CONTEXT.md`
2. `documents/system/system-design.md`
3. `documents/system/codebase-understanding.md`
4. `documents/system/mental-model.md`
5. `documents/system/dependency-map.md`

## Project Shape

- Godot 4 game with a Python content pipeline.
- Runtime entry: `project.godot` -> `scenes/ui/MainMenu.tscn`
- Main gameplay is merge-driven on a 5x5 grid.
- Two modes share the same board mechanic:
  - free-play -> merge for economy/progression
  - battle -> merge for damage/combat progress

## Read These Files First

### Composition roots

- `project.godot`
- `scripts/main/GameScene.gd`
- `scripts/main/BattleScene.gd`

### Core gameplay

- `scripts/grid/MergeManager.gd`
- `scripts/grid/Grid.gd`
- `scripts/grid/PerfumeItem.gd`
- `scripts/managers/SpawnManager.gd`
- `scripts/managers/EconomyManager.gd`
- `scripts/managers/BattleManager.gd`

### Persistence and data

- `scripts/managers/SaveManager.gd`
- `scripts/data/DataManager.gd`
- `scripts/data/OpponentManager.gd`
- `data/perfumes_filtered.json`
- `data/opponents.json`

### UI/control layer

- `scripts/ui/HUD.gd`
- `scripts/ui/BattleSelect.gd`
- `scripts/ui/BattleResult.gd`
- `scripts/ui/Encyclopedia.gd`

## Core Mental Model

- `SpawnManager` creates items from `DataManager`.
- `PerfumeItem` + `Grid` handle board interaction.
- `MergeManager` is the gameplay hub.
- In free-play, merge output goes to `EconomyManager`.
- In battle, merge output goes to `BattleManager`.
- `SaveManager` persists almost everything important.

## High-Risk Files

- `scripts/grid/MergeManager.gd`
- `scripts/managers/SaveManager.gd`
- `scripts/ui/HUD.gd`
- `scripts/managers/SpawnManager.gd`

Changes here can affect both modes, persistence, progression, and UI flow.

## Rules To Respect

- Do not bypass manager ownership boundaries unless necessary.
- Keep gameplay logic in managers, not scattered in scene scripts.
- Treat save schema changes as high risk.
- Preserve the free-play vs battle merge split.
- Verify both modes when touching merge, spawn, save, or reward logic.
- Assume autoload coupling is real and broad.

## Critical Invariants

- `SpawnManager.grid_reference` must point to the active grid.
- `DataManager` must load valid perfume data before spawn/tier logic runs.
- `OpponentManager` must load valid opponent data before battle flow runs.
- Free-play merge must reward economy.
- Battle merge must deal damage.
- Save/load must preserve board state compatibility.
- Runtime currently depends on `data/perfumes_filtered.json`, not `perfumes_slim.json`.

## Safe Places To Start

- New isolated UI scenes or overlays
- Read-only collection/info features
- New opponents or data tuning within current schema
- New signal-driven visual/audio feedback
- New upgrades owned cleanly by one manager

## Watch For

- Direct manager-to-manager coupling
- UI mutating gameplay state directly
- Save/load identity issues around perfume matching
- Async ad callback behavior
- Hardcoded assumptions around a 25-slot board
