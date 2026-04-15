# Mental Model

The game has one shared board mechanic and two outputs.

In both modes, the player spawns low-tier perfumes, drags them on a 5x5 grid, merges matching tiers, and manages space. The difference is what a merge means:

- In free-play, merges turn into Essence, unlock discoveries, and feed long-term progression.
- In battle, merges turn into damage, combo pressure, and timed opponent clears.

A simple way to think about it is:

```text
spawn -> place/drag -> merge or sell -> reward -> save progress
```

In free-play, the reward is economy. In battle, the reward is combat progress.

## Key Modules

[GameScene.gd](C:\Users\moham\OneDrive\Documents\Intro to Greatness\PerfumeFusion\scripts\main\GameScene.gd): boots free-play, restores the board, shows tutorial/offline rewards.

[BattleScene.gd](C:\Users\moham\OneDrive\Documents\Intro to Greatness\PerfumeFusion\scripts\main\BattleScene.gd): boots battle mode, shows the opponent, runs timer/HP UI.

[Grid.gd](C:\Users\moham\OneDrive\Documents\Intro to Greatness\PerfumeFusion\scripts\grid\Grid.gd), [PerfumeItem.gd](C:\Users\moham\OneDrive\Documents\Intro to Greatness\PerfumeFusion\scripts\grid\PerfumeItem.gd), [SellZone.gd](C:\Users\moham\OneDrive\Documents\Intro to Greatness\PerfumeFusion\scripts\grid\SellZone.gd): the physical board and player interactions.

[MergeManager.gd](C:\Users\moham\OneDrive\Documents\Intro to Greatness\PerfumeFusion\scripts\grid\MergeManager.gd): the gameplay heart. Decides merge results, animations, unlocks, stats, and whether output goes to economy or battle.

[SpawnManager.gd](C:\Users\moham\OneDrive\Documents\Intro to Greatness\PerfumeFusion\scripts\managers\SpawnManager.gd): pacing layer for spawning, cooldowns, frenzy, and spawn costs.

[EconomyManager.gd](C:\Users\moham\OneDrive\Documents\Intro to Greatness\PerfumeFusion\scripts\managers\EconomyManager.gd): Essence, offline earnings, spending/rewards.

[BattleManager.gd](C:\Users\moham\OneDrive\Documents\Intro to Greatness\PerfumeFusion\scripts\managers\BattleManager.gd): opponent HP, combo state, weakness/resistance math.

[SaveManager.gd](C:\Users\moham\OneDrive\Documents\Intro to Greatness\PerfumeFusion\scripts\managers\SaveManager.gd): persistent progression and board state.

[DataManager.gd](C:\Users\moham\OneDrive\Documents\Intro to Greatness\PerfumeFusion\scripts\data\DataManager.gd) and [OpponentManager.gd](C:\Users\moham\OneDrive\Documents\Intro to Greatness\PerfumeFusion\scripts\data\OpponentManager.gd): read-only content catalogs.

## How Managers Interact

At a high level:

DataManager provides perfume content.

SpawnManager asks DataManager for a perfume and places it on the grid.

PerfumeItem and Grid collect player input and route actions.

Grid sends merge attempts to MergeManager and sell actions to EconomyManager.

MergeManager updates SaveManager, plays audio, and then branches:

- free-play -> EconomyManager
- battle -> BattleManager

BattleScene listens to BattleManager signals and renders the fight.

HUD sits on top, calling into spawn/economy/rare-drop systems.

SaveManager is the persistence backbone almost every major system touches.

## Where Bugs Are Most Likely

In MergeManager, because it mixes rules, progression, persistence, battle, economy, and UI effects.

In save/load paths, because grid state is reconstructed by matching saved perfume identity back to catalog data.

In cross-manager behavior, because the architecture relies heavily on autoload singletons and implicit global state.

In mode branching, because the same merge action behaves differently in free-play vs battle.

In spawn logic, because some flow lives in SpawnManager while HUD also does parts of spawning/cost handling directly.

In async reward flows, especially ads and reward callbacks, where scene state may have changed by the time the callback fires.

## Safest Places To Add New Features

New UI overlays or menus, as separate scenes/scripts that consume existing manager APIs.

New opponents or content tuning in data files, when the schema stays the same.

New visual/audio feedback hooked to existing signals like merge completion, damage dealt, or rare drop availability.

New shop upgrades, if they stay isolated to one clear owner like SpawnManager or EconomyManager.

New collection/browsing features in encyclopedia/info-card style UI, because they are mostly read-only over DataManager and SaveManager.

The least safe places to start are MergeManager, SaveManager, and any feature that changes board shape, save schema, or core spawn/merge rules.
