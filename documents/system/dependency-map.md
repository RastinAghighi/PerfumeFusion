# Dependency Map

## Dependency Direction

The intended runtime shape is mostly Scenes/UI -> Managers -> Data/Persistence/Platform.

The actual code also has several sideways manager-to-manager dependencies and a few reverse dependencies where persistence and utility systems reach back into live gameplay state.

## Content And Data Dependencies

scraper/scraper.py -> scraper/config.py -> data/perfumes.json

scripts/data/optimize_data.py -> data/perfumes.json -> data/perfumes_slim.json

DataManager.gd <- data/perfumes_filtered.json

OpponentManager.gd <- data/opponents.json

SaveManager.gd <-> user://save_data.json

## Runtime Module Map

GameScene.gd -> SaveManager, SpawnManager, EconomyManager, AudioManager, AdManager, DataManager, Grid, HUD, Tutorial, WelcomeBack

BattleScene.gd -> OpponentManager, SaveManager, SpawnManager, EconomyManager, AudioManager, BattleManager, MergeManager, DataManager, HUD, OpponentIntro, BattleResult

MainMenu.gd -> AudioManager, GameScene, BattleSelect, Encyclopedia, Settings

BattleSelect.gd -> OpponentManager, SaveManager, EconomyManager, AudioManager, BattleScene

HUD.gd -> SpawnManager, EconomyManager, RareDropManager, AdManager, SaveManager, AudioManager, Shop, InfoCard

Encyclopedia.gd -> DataManager, SaveManager, EconomyManager, AudioManager, InfoCard

Shop.gd -> EconomyManager, SaveManager

Settings.gd -> AudioManager, SaveManager

WelcomeBack.gd -> EconomyManager, AdManager

BattleResult.gd -> SaveManager, EconomyManager

Grid.gd -> MergeManager, EconomyManager, SaveManager, SellZone

PerfumeItem.gd -> Grid, AudioManager, DataManager, InfoCard

MergeManager.gd -> DataManager, SaveManager, EconomyManager, BattleManager, SpawnManager, AudioManager, InfoCard, PerfumeItem, MergeParticles

SpawnManager.gd -> DataManager, SaveManager, EconomyManager, AudioManager, BattleManager, Grid

EconomyManager.gd -> SaveManager, AudioManager

BattleManager.gd -> opponent data, perfume accord data

RareDropManager.gd -> SpawnManager, AdManager, AudioManager, HUD group

AudioManager.gd -> SaveManager

AdManager.gd -> OS, JavaScriptBridge, platform SDKs

OpponentManager.gd -> SaveManager

SaveManager.gd -> SpawnManager, BattleManager

## Highest Tight-Coupling Areas

MergeManager is the tightest hub. It touches gameplay rules, FX, unlocks, saves, economy, battle, spawning, and UI.

SaveManager is tightly coupled to live runtime systems because it reads battle mode state and pulls grid state through SpawnManager.

HUD is more than presentation. It performs spawn-cost logic, unlock writes, ad-triggered features, and cooldown behavior.

BattleScene is a large composition root with direct dependencies on most combat-related systems.

RareDropManager is coupled back to UI through a HUD group lookup instead of pure signals.

## Modules That Should Not Directly Depend On Each Other

SaveManager should not directly depend on SpawnManager or BattleManager.

HUD should not directly mutate SaveManager gameplay state or call spawn internals.

MergeManager should not directly depend on both EconomyManager and BattleManager; mode outcome routing should sit above it.

RareDropManager should not directly know about the HUD.

BattleResult should ideally not directly award economy and update progression; that belongs in a battle/progression service.

OpponentManager should ideally not depend on SaveManager for unlock logic; unlock state is progression, not catalog data.

## Practical Reading Of The Architecture

The cleanest boundary is content files -> data managers -> gameplay managers -> scenes/UI.

The weakest boundary is between gameplay managers, persistence, and UI; that is where most future architectural friction will come from.

If you change MergeManager, SaveManager, or HUD, expect broad impact across the whole game.
