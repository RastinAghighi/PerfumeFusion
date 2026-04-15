# RULES

## Read Order

1. `AGENT_QUICKSTART.md`
2. `PROJECT_CONTEXT.md`
3. `RULES.md`

## 1. Purpose

- This file defines strict engineering rules for code generation in this project.
- If a proposed change violates these rules, do not generate it.
- When uncertain, preserve existing ownership boundaries and avoid adding new coupling.

## 2. High-Level Architecture Rules

- Preferred dependency direction: `Scenes/UI -> Managers -> Data/Persistence/Platform`.
- Managers are the primary gameplay boundaries.
- Scenes and UI may compose systems and render state, but must not become authoritative gameplay state owners.
- Data/catalog managers are read-only at runtime.
- Persistence logic must stay centralized.
- Use signals for cross-system reactions whenever possible.
- Do not add new direct manager-to-manager dependencies unless the manager truly owns that behavior.

## 3. Manager Rules

### DataManager

Allowed:

- Load runtime perfume catalog from `data/perfumes_filtered.json`
- Compute tier buckets and tier lookup rules
- Return random perfume data by tier
- Provide accord/tier color helpers
- Resolve perfume identity lookup for restore paths

Must never:

- Modify save data
- Award currency
- Apply battle damage
- Own UI behavior
- Write runtime content files
- Become a source of gameplay progression state

### OpponentManager

Allowed:

- Load opponent catalog from `data/opponents.json`
- Expose selected opponent id
- Return opponent data and unlocked-opponent views

Must never:

- Award battle rewards
- Save progression directly
- Start or end battles
- Own combat math
- Own UI flow

### SaveManager

Allowed:

- Own the persistent save schema
- Load and save `user://save_data.json`
- Merge defaults into older save data
- Store progression state, grid state, audio prefs, unlocks, upgrades, and battle stats
- Snapshot board state for free-play persistence

Must never:

- Decide gameplay outcomes
- Award or spend essence as business logic
- Calculate battle damage
- Own spawn rules
- Own merge rules
- Show UI
- Become a generic service for arbitrary side effects

Strict notes:

- Any save schema change is high risk.
- Backward compatibility is required unless a migration path is implemented.
- Do not add new reverse dependencies from `SaveManager` into gameplay systems.

### EconomyManager

Allowed:

- Own current essence amount
- Add and spend essence
- Compute merge rewards and offline earnings
- Emit economy state change signals
- Persist economy state through `SaveManager`

Must never:

- Decide whether a merge is valid
- Own grid state
- Apply battle damage
- Unlock perfumes or opponents as primary business logic
- Start UI flows
- Mutate battle session state

Strict notes:

- `EconomyManager` is the only authoritative owner of current essence in runtime.
- UI must not become a second source of truth for currency.

### SpawnManager

Allowed:

- Own spawn intervals, costs, cooldowns, frenzy, and spawn pacing
- Hold the active `grid_reference`
- Spawn items onto the active grid
- Request perfume data from `DataManager`
- Coordinate with `EconomyManager` for spawn-related costs

Must never:

- Own unlock lists
- Own save schema
- Own battle HP or combo logic
- Reimplement merge logic
- Depend on UI state to determine spawn validity
- Spawn onto a null or inactive grid

Strict notes:

- `SpawnManager` is the owner of spawn rules.
- UI must call spawn APIs, not recreate spawn rules locally.

### RareDropManager

Allowed:

- Schedule rare-drop availability windows
- Gate reward acquisition through ads
- Request a bonus spawn from `SpawnManager`

Must never:

- Own HUD state
- Award essence directly
- Mutate save schema
- Duplicate spawn rule logic
- Become a second progression manager

Strict notes:

- Existing UI coupling is legacy. Do not add more.
- Prefer signals over direct UI reach-in.

### BattleManager

Allowed:

- Own battle session state
- Own combo state
- Own damage calculation
- Apply weakness/resistance modifiers
- Emit battle-related signals

Must never:

- Award essence
- Save progression directly
- Own battle result UI
- Mutate collection/unlock state
- Touch free-play board persistence
- Depend on scene presentation state for combat rules

Strict notes:

- `BattleManager` owns battle math and state, not battle rewards.
- Battle results should be consumed by higher-level flow, not decided by UI.

### MergeManager

Allowed:

- Validate merges
- Choose next-tier perfume outcome
- Animate merge resolution
- Update merge-related unlocks and stats
- Route successful merge output to:
  - `EconomyManager` in free-play
  - `BattleManager` in battle

Must never:

- Own save file schema
- Own spawn timing
- Own battle result flow
- Reimplement economy ownership
- Depend on UI state to determine merge validity
- Mix unrelated progression systems into merge rules

Strict notes:

- `MergeManager` is the central gameplay orchestrator and is therefore high risk.
- Do not expand its responsibilities casually.

### AudioManager

Allowed:

- Own audio preferences
- Register and control BGM players
- Play SFX and BGM-related feedback
- Persist audio prefs through `SaveManager`

Must never:

- Own gameplay rules
- Gate rewards
- Change progression state beyond audio prefs
- Become a signaling hub for gameplay decisions

### AdManager

Allowed:

- Detect platform ad environment
- Initialize ad SDKs
- Show rewarded ads and commercial breaks
- Return success/failure through callbacks or signals

Must never:

- Decide reward amounts
- Unlock content directly
- Own progression state
- Own battle or economy rules
- Write save data except through a higher-level caller that owns the reward

## 4. Data Ownership Rules

- `DataManager` owns runtime perfume catalog access.
- `OpponentManager` owns runtime opponent catalog access.
- `SaveManager` owns persisted save schema and stored progression data.
- `EconomyManager` owns current essence at runtime.
- `BattleManager` owns active battle state, HP, combo, and battle damage logic.
- `SpawnManager` owns spawn timing, costs, cooldowns, frenzy, and active grid reference.
- `MergeManager` owns merge validation and merge outcome routing.
- `AudioManager` owns audio prefs and playback.
- `AdManager` owns ad platform integration state.

Rules:

- Do not create duplicate sources of truth for the same domain.
- UI may display state but must not become the owner of that state.
- Save-backed fields must have one authoritative runtime owner.
- If a field belongs to a manager, other systems should ask that manager, not shadow it locally.

## 5. Side-Effect Rules

### SaveManager Side Effects

- Allowed side effects:
  - file IO for save/load
  - updating `SaveManager.data`
  - schema defaulting and compatibility merging
- Forbidden side effects:
  - awarding gameplay outcomes
  - initiating UI
  - calculating combat or economy rules

### BattleManager Side Effects

- Allowed side effects:
  - mutating battle session state
  - mutating combo state
  - emitting battle signals
- Forbidden side effects:
  - writing save files
  - awarding currency
  - mutating collection/unlock state
  - controlling battle UI directly

### EconomyManager Side Effects

- Allowed side effects:
  - mutating essence
  - emitting economy change signals
  - persisting economy values through `SaveManager`
  - playing economy-related audio feedback if already part of owned flow
- Forbidden side effects:
  - mutating battle state
  - mutating grid structure
  - deciding merge validity
  - driving UI flow as the primary owner

## 6. Merge Logic Constraints

- Only same-tier items may merge.
- Failed merges must leave the board in a valid state.
- A successful merge must consume exactly two valid source items and create exactly one valid result item.
- Result tier must be derived from merge rules only.
- Result tier must never exceed the max supported tier.
- Result perfume data must come from `DataManager`.
- Merge logic must not depend on presentation state.
- UI effects must not determine gameplay outcome.
- Merge success/failure must be deterministic with respect to the actual game rules and allowed randomness.
- Free-play successful merge must route to economy reward.
- Battle successful merge must route to battle damage.
- Do not pay both battle damage and free-play economy reward for the same merge unless intentionally specified by design.
- Merge-related unlock/stat updates must occur once per successful merge.

## 7. Spawn Logic Constraints

- Spawning requires a valid active grid reference.
- Do not spawn if there is no empty slot.
- Spawned perfume data must come from `DataManager`.
- Normal spawn flow should produce tier-1 items unless a specific mechanic explicitly overrides it.
- `SpawnManager` owns spawn cost, interval, cooldown, and frenzy rules.
- UI must not reimplement spawn rules.
- Special spawn systems must route through `SpawnManager`, not create parallel spawn ownership.
- Spawn logic must not mutate battle state directly.
- Spawn logic must not become the owner of unlock or collection rules.

## 8. Modules That Must Not Directly Depend On Each Other

- `SaveManager` must not gain new direct dependencies on gameplay managers.
- `HUD` must not become a gameplay rules engine.
- `HUD` must not directly own save mutations for core gameplay domains.
- `MergeManager` should not gain more direct dependencies outside its current core path.
- `RareDropManager` must not gain new direct UI dependencies.
- `BattleResult` should not become the owner of core battle/economy rule calculation.
- `OpponentManager` should not become a progression owner.

## 9. Legacy Exceptions To Avoid Copying

- `SaveManager` currently reaches into live grid state via other systems. Do not expand that pattern.
- `HUD` currently contains some spawn-related business behavior. Do not copy that pattern into new features.
- `RareDropManager` currently reaches toward HUD behavior. Treat that as legacy, not a design template.
- Some runtime systems still rely on `url` from perfume data. Do not remove or ignore that dependency without auditing restore and unlock paths.

## 10. Enforcement Priorities

When generating code, protect these first:

1. Save compatibility
2. Free-play vs battle merge behavior
3. Single-owner state boundaries
4. Valid grid/item ownership
5. Spawn rule centralization
6. Avoiding new manager coupling
