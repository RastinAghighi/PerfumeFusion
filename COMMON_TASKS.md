# COMMON_TASKS

## 1. Adding a New Feature

### Goal

Add a feature without breaking manager ownership, save compatibility, or mode behavior.

### Steps

1. Read:
   - `AGENT_QUICKSTART.md`
   - `PROJECT_CONTEXT.md`
   - `RULES.md`
2. Identify the feature owner:
   - UI feature -> scene/UI script
   - gameplay rule -> manager
   - content-only feature -> data file + catalog consumer
3. Find the existing flow the feature belongs to:
   - free-play
   - battle
   - economy
   - spawn
   - collection
4. Reuse existing manager APIs before creating new ones.
5. Add the minimum new dependency surface possible.
6. Prefer signals for cross-system communication.
7. Verify both free-play and battle if the feature touches shared systems.

### Files To Touch

- Depends on feature area, but usually start with:
  - `PROJECT_CONTEXT.md`
  - `RULES.md`
  - one owner manager
  - one scene or UI file

### Managers Involved

- Usually one owner manager plus one scene/UI consumer
- Avoid involving `MergeManager`, `SaveManager`, and `HUD` unless required

### Check After Changes

- No duplicate source of truth was introduced
- No new unsafe manager-to-manager dependency was added
- UI is not owning gameplay state
- Save/load still works if persistent state changed
- Feature behaves correctly in both modes if it touches shared systems

## 2. Modifying Merge Logic

### Goal

Change merge behavior without breaking board validity, progression, economy routing, or battle routing.

### Steps

1. Read:
   - `scripts/grid/MergeManager.gd`
   - `scripts/grid/Grid.gd`
   - `scripts/grid/PerfumeItem.gd`
   - `scripts/managers/BattleManager.gd`
   - `scripts/managers/EconomyManager.gd`
   - `scripts/managers/SaveManager.gd`
2. Confirm whether the change affects:
   - merge validity
   - merge result tier
   - rewards
   - unlocks/stats
   - battle damage routing
3. Keep merge ownership inside `MergeManager`.
4. Preserve the rule that only valid merges produce a result item.
5. Preserve mode split:
   - free-play merge -> economy reward
   - battle merge -> battle damage
6. Preserve board consistency before and after merge animation/resolution.

### Files To Touch

- `scripts/grid/MergeManager.gd`
- Possibly:
  - `scripts/grid/Grid.gd`
  - `scripts/managers/BattleManager.gd`
  - `scripts/managers/EconomyManager.gd`
  - `scripts/managers/SaveManager.gd`
  - related UI feedback scenes/scripts if presentation changes

### Managers Involved

- `MergeManager`
- `BattleManager`
- `EconomyManager`
- `SaveManager`
- `AudioManager`
- `SpawnManager` only if merge progression affects spawn pacing

### Check After Changes

- Same-tier merge rule still behaves correctly unless intentionally changed
- Exactly two inputs are consumed and one valid output is produced
- Failed merges do not corrupt the board
- Free-play still awards economy only
- Battle still applies damage only
- Unlocks/stats update once per successful merge
- Max tier constraints still hold

## 3. Adding New Perfume Data

### Goal

Add or update perfume content without breaking runtime schema assumptions.

### Steps

1. Read:
   - `scripts/data/DataManager.gd`
   - `scripts/ui/Encyclopedia.gd`
   - `scripts/ui/InfoCard.gd`
   - `scripts/managers/BattleManager.gd`
   - `PROJECT_CONTEXT.md`
2. Decide whether the change is:
   - runtime dataset update
   - scraper update
   - filtered/curated content update
3. Keep runtime schema compatible with existing consumers.
4. Ensure new records fit tier bucketing and collection flow.
5. If changing generation pipeline, verify runtime still uses the correct output file.

### Files To Touch

- Usually:
  - `data/perfumes_filtered.json`
- If pipeline changes:
  - `scraper/scraper.py`
  - `scraper/config.py`
  - `scripts/data/optimize_data.py`

### Managers Involved

- `DataManager`
- `BattleManager`
- `Encyclopedia` / `InfoCard` consumers
- `SaveManager` indirectly through restore/unlock identity logic

### Check After Changes

- Required fields still exist:
  - `name`
  - `brand`
  - `gender`
  - `rating`
  - `votes`
  - `accords`
  - `notes_top`
  - `notes_middle`
  - `notes_base`
  - often `url`
- Tier bucketing still works
- Collection UI still renders correctly
- Battle accord matching still works
- Save restore and unlock lookup still work for existing and new items

## 4. Adding a New Opponent

### Goal

Add a battle opponent without breaking unlock flow or battle result progression.

### Steps

1. Read:
   - `data/opponents.json`
   - `scripts/data/OpponentManager.gd`
   - `scripts/ui/BattleSelect.gd`
   - `scripts/main/BattleScene.gd`
   - `scripts/ui/BattleResult.gd`
2. Add the opponent entry using the existing schema.
3. Set unlock progression carefully.
4. Choose HP, timer, weakness, resistance, and reward values consistent with current curve.
5. Verify the opponent appears in battle select and unlocks at the intended time.

### Files To Touch

- `data/opponents.json`
- Possibly:
  - `scripts/data/OpponentManager.gd`
  - `scripts/ui/BattleSelect.gd`
  - `scripts/ui/BattleResult.gd`
  - `scripts/main/BattleScene.gd` if presentation depends on special-case behavior

### Managers Involved

- `OpponentManager`
- `BattleManager`
- `SaveManager`

### Check After Changes

- Opponent entry includes:
  - `id`
  - `name`
  - `title`
  - `description`
  - `hp`
  - `time_limit`
  - `weakness`
  - `resistance`
  - `reward_essence`
  - `unlock_requirement`
- Unlock order is correct
- Battle select renders correctly
- Battle scene loads the opponent correctly
- Victory marks the opponent beaten and rewards correctly

## 5. Changing Economy Logic

### Goal

Change rewards, costs, or offline earnings without breaking ownership boundaries.

### Steps

1. Read:
   - `scripts/managers/EconomyManager.gd`
   - `scripts/managers/SaveManager.gd`
   - `scripts/managers/SpawnManager.gd`
   - `scripts/ui/HUD.gd`
   - `scripts/ui/Shop.gd`
   - `scripts/ui/WelcomeBack.gd`
2. Decide whether the change affects:
   - current essence state
   - merge rewards
   - spawn costs
   - shop costs
   - offline earnings
   - battle rewards
3. Keep `EconomyManager` as the authoritative owner of current essence.
4. Do not move economy ownership into UI.
5. If costs are spawn-related, keep the spawn rules owned by `SpawnManager`.

### Files To Touch

- `scripts/managers/EconomyManager.gd`
- Possibly:
  - `scripts/managers/SpawnManager.gd`
  - `scripts/ui/HUD.gd`
  - `scripts/ui/Shop.gd`
  - `scripts/ui/WelcomeBack.gd`
  - `scripts/ui/BattleResult.gd`
  - `scripts/managers/SaveManager.gd` only if persistence fields change

### Managers Involved

- `EconomyManager`
- `SpawnManager`
- `SaveManager`
- `BattleResult` flow consumer

### Check After Changes

- `EconomyManager` remains the sole owner of current essence
- Spawn costs and economy rewards are still separated by responsibility
- Offline earnings still persist correctly
- Shop purchases still deduct correctly
- Battle rewards still apply correctly
- UI labels update correctly from signals/state

## 6. Modifying Battle Mechanics

### Goal

Change combat behavior without leaking battle rules into UI or free-play systems.

### Steps

1. Read:
   - `scripts/managers/BattleManager.gd`
   - `scripts/main/BattleScene.gd`
   - `scripts/grid/MergeManager.gd`
   - `scripts/ui/BattleResult.gd`
   - `scripts/data/OpponentManager.gd`
2. Decide whether the change affects:
   - damage calculation
   - combo behavior
   - weakness/resistance logic
   - victory/defeat conditions
   - battle rewards
3. Keep combat math and active battle state inside `BattleManager`.
4. Keep `BattleScene` focused on presentation and orchestration.
5. Preserve the merge-to-damage pipeline from `MergeManager` into `BattleManager`.

### Files To Touch

- `scripts/managers/BattleManager.gd`
- Possibly:
  - `scripts/main/BattleScene.gd`
  - `scripts/grid/MergeManager.gd`
  - `scripts/ui/BattleResult.gd`
  - `data/opponents.json`

### Managers Involved

- `BattleManager`
- `MergeManager`
- `OpponentManager`
- `SaveManager`
- `EconomyManager` only if rewards change

### Check After Changes

- Battle state remains owned by `BattleManager`
- Damage math still uses valid perfume/opponent data
- Weakness/resistance logic still behaves predictably
- Combo logic resets and updates correctly
- Victory/defeat flow still transitions correctly
- Free-play behavior is unchanged unless intentionally shared
