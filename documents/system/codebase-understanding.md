# Codebase Understanding

## 1. Full Game Loop

Free-play starts in [MainMenu.tscn](C:\Users\moham\OneDrive\Documents\Intro to Greatness\PerfumeFusion\scenes\ui\MainMenu.tscn), then enters [GameScene.gd](C:\Users\moham\OneDrive\Documents\Intro to Greatness\PerfumeFusion\scripts\main\GameScene.gd). The scene wires the grid into SpawnManager, restores saved bottles from SaveManager, adds the HUD, optionally shows tutorial/offline earnings, and then hands control to the player. From there the loop is: spawn tier-1 perfumes, drag them around the grid, either merge equal tiers or sell them, gain essence, buy upgrades, unlock more perfumes, and save progress on key transitions or exit.

The real core loop is merge-driven. HUD/SpawnManager create bottles using DataManager's tier-1 pool. PerfumeItem handles drag input, Grid decides whether a drop is a place/sell/merge action, and MergeManager resolves the outcome. A successful merge creates the next-tier item, updates unlock/discovery stats, then branches: in free-play it pays essence through EconomyManager; in battle it converts the merge into damage through BattleManager. That makes "spawn -> arrange -> merge -> reward -> stronger board -> faster progression" the central loop.

Battle starts in [BattleSelect.gd](C:\Users\moham\OneDrive\Documents\Intro to Greatness\PerfumeFusion\scripts\ui\BattleSelect.gd), which chooses an opponent from OpponentManager and opens [BattleScene.gd](C:\Users\moham\OneDrive\Documents\Intro to Greatness\PerfumeFusion\scripts\main\BattleScene.gd). The battle scene bootstraps a fresh grid, shows the opponent intro, starts BattleManager, and seeds a few starting perfumes. From that point the player is racing the timer: merge as fast as possible, build combos, exploit accord weaknesses, burn down HP, then receive a victory/defeat result. Victory pays essence, marks the opponent beaten, unlocks the next one, and writes battle stats back through SaveManager.

## 2. Most Important Managers And Why

SaveManager in [SaveManager.gd](C:\Users\moham\OneDrive\Documents\Intro to Greatness\PerfumeFusion\scripts\managers\SaveManager.gd): this is the source of truth for persistence. It owns essence, upgrades, unlocked perfumes, grid state, tutorial state, audio prefs, beaten opponents, and battle stats. If it breaks, progression breaks.

MergeManager in [MergeManager.gd](C:\Users\moham\OneDrive\Documents\Intro to Greatness\PerfumeFusion\scripts\grid\MergeManager.gd): this is the gameplay pivot. It decides whether a merge is valid, what the new item becomes, what gets unlocked, whether the result turns into damage or money, and what feedback the player sees.

SpawnManager in [SpawnManager.gd](C:\Users\moham\OneDrive\Documents\Intro to Greatness\PerfumeFusion\scripts\managers\SpawnManager.gd): this controls board pressure and pacing. Spawn costs, cooldowns, frenzy, auto-spawn speed, and rare spawns all route through it.

DataManager in [DataManager.gd](C:\Users\moham\OneDrive\Documents\Intro to Greatness\PerfumeFusion\scripts\data\DataManager.gd): this is the runtime content catalog. Tier distribution, random perfume selection, tier lookup, collection display, bottle color, and some battle semantics all depend on its data model.

BattleManager in [BattleManager.gd](C:\Users\moham\OneDrive\Documents\Intro to Greatness\PerfumeFusion\scripts\managers\BattleManager.gd): battle mode is thin without it. It owns HP, combo state, weakness/resistance math, and the event stream that BattleScene renders.

## 3. How Data Flows Through The System

Offline content starts in [scraper.py](C:\Users\moham\OneDrive\Documents\Intro to Greatness\PerfumeFusion\scraper\scraper.py), which produces perfume JSON; runtime then loads curated game data from [perfumes_filtered.json](C:\Users\moham\OneDrive\Documents\Intro to Greatness\PerfumeFusion\data\perfumes_filtered.json), while opponents come from [opponents.json](C:\Users\moham\OneDrive\Documents\Intro to Greatness\PerfumeFusion\data\opponents.json).

On startup, autoloads read content and save state first. Scenes then compose around those singletons rather than owning their own state.

During play, player input flows PerfumeItem -> Grid -> MergeManager/SellZone. Rewards and progression flow MergeManager/SellZone -> EconomyManager/SaveManager.

In battle, merge output flows MergeManager -> BattleManager -> BattleScene UI -> BattleResult -> SaveManager.

On save/load, the grid is serialized into a lightweight slot array by SaveManager, then reconstructed in GameScene by matching saved name/brand/url back against DataManager.

## 4. Top 3 Most Critical Dependencies

DataManager <-> perfumes_filtered.json. The game assumes stable fields like rating, accords, gender, notes_*, and often url. Spawning, collection, colors, restore logic, and some battle effects all depend on that schema staying consistent.

SaveManager <-> live grid state. SaveManager snapshots the current board through SpawnManager.grid_reference, and GameScene restores it by asking DataManager.find_perfume(...). That persistence path is critical because it bridges runtime nodes, saved JSON, and catalog data.

MergeManager <-> mode-specific outcomes. MergeManager is coupled to both EconomyManager and BattleManager, so every merge touches the free-play economy and the battle system. It is the single most important junction in the design.

## 5. Fragile Or Risky Areas

Heavy autoload coupling. Most systems reach directly into globals, so lifecycle/order issues are easy to introduce and hard to isolate.

MergeManager is doing too much. It owns merge validation, animation, unlocks, stats, persistence triggers, battle routing, economy routing, and UI popups. That makes regressions likely.

Save/load relies on soft identity. The saved grid stores tier, name, brand, and url, then tries to re-find the perfume later. If the dataset changes, entries are renamed, or url disappears, restore quality drops.

There is visible data-contract drift. The README talks about perfumes_slim.json, but runtime loads perfumes_filtered.json; several systems still rely on url, even though the optimizer is designed to strip it.

UI bypasses manager boundaries in places. HUD calls spawn internals directly instead of treating SpawnManager as the single spawn API, which increases the chance that spawn rules diverge over time.

Grid/save assumptions are rigid. Save state is hardcoded around 25 slots, while upgrades already hint at board expansion. That is a likely future fault line.

Async ad/reward flows are cross-cutting. Rare drops, frenzy, offline doubling, and rewarded callbacks all depend on scene state still being valid when the callback resolves.
