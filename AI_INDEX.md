# AI_INDEX

## Read Order

1. `AGENT_QUICKSTART.md`
2. `PROJECT_CONTEXT.md`
3. `RULES.md`
4. `COMMON_TASKS.md`

## Core Agent Docs

- `AGENT_QUICKSTART.md`
  - Fast onboarding, read order, first files to inspect, core invariants, and safest starting points

- `PROJECT_CONTEXT.md`
  - Structured project-wide context: gameplay loops, managers, data flow, invariants, dependencies, risks, and extension guidance

- `RULES.md`
  - Strict engineering guardrails: manager ownership, forbidden behaviors, side-effect boundaries, merge rules, and spawn rules

- `COMMON_TASKS.md`
  - Step-by-step playbooks for common coding tasks in this repo

## Deep Reference Docs

- `documents/system/system-design.md`
  - Full system map with modules, dependency shape, data flow, schemas, and architectural traits

- `documents/system/codebase-understanding.md`
  - Deep explanation of the game loop, key managers, critical dependencies, and fragile areas

- `documents/system/mental-model.md`
  - Simplified onboarding model for understanding the system quickly

- `documents/system/dependency-map.md`
  - Explicit dependency direction, coupling hotspots, and forbidden dependency guidance

## Recommended Code Read Order

1. `project.godot`
2. `scripts/main/GameScene.gd`
3. `scripts/main/BattleScene.gd`
4. `scripts/grid/MergeManager.gd`
5. `scripts/managers/SaveManager.gd`
6. `scripts/managers/SpawnManager.gd`
7. `scripts/managers/EconomyManager.gd`
8. `scripts/managers/BattleManager.gd`
9. `scripts/data/DataManager.gd`
10. `scripts/ui/HUD.gd`

## Start Here If You Want To Code

- UI/menu feature: start with `AGENT_QUICKSTART.md`, then inspect `scripts/ui/*`
- Board/merge feature: start with `RULES.md`, then inspect `scripts/grid/MergeManager.gd`
- Progression/economy feature: start with `PROJECT_CONTEXT.md`, then inspect `scripts/managers/EconomyManager.gd` and `scripts/managers/SaveManager.gd`
- Battle feature: start with `PROJECT_CONTEXT.md`, then inspect `scripts/managers/BattleManager.gd` and `scripts/main/BattleScene.gd`
- Content feature: start with `COMMON_TASKS.md`, then inspect `data/perfumes_filtered.json` or `data/opponents.json`
