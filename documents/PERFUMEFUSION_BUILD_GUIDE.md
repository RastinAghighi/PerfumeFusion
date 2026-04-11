# PerfumeFusion — Step-by-Step Implementation Guide

---

## PHASE 1: Project Setup & Data Layer

---

### Step 1 — Initialize Godot Project Structure

```claude code prompt
Create a Godot 4.x project in the current directory (PerfumeFusion). Create the project.godot file with the following settings:
- Display resolution: 1080x1920 (portrait)
- Stretch mode: canvas_items
- Stretch aspect: keep_width
- Project name: PerfumeFusion

Create this folder structure with placeholder .gdignore or empty files so git tracks them:

PerfumeFusion/
├── scenes/
│   ├── main/
│   ├── grid/
│   ├── ui/
│   └── effects/
├── scripts/
│   ├── data/
│   ├── grid/
│   ├── ui/
│   └── managers/
├── assets/
│   ├── art/
│   ├── audio/
│   └── fonts/
├── data/
│   └── perfumes.json        (already exists)
└── project.godot

Do NOT create any scenes or scripts yet, just the folder structure and project.godot.
```

**Verify:**
```powershell
ls -Recurse -Directory | Select-Object FullName
cat project.godot
```

**Push:**
```powershell
git add .
git commit -m "Step 1: Initialize Godot project structure"
git push
```

---

### Step 2 — DataManager Singleton

```claude code prompt
Read documents/IMPLEMENTATION_GUIDE.md for full context.

Create scripts/data/DataManager.gd — a GDScript file that will be registered as an Autoload singleton.

Requirements:
- On _ready(), load data/perfumes.json and parse it with JSON.parse_string()
- Pre-sort all 24,063 perfumes into a Dictionary called tier_brackets, keyed by tier number (1–20)
- Tier mapping:
  - Tier 1: rating 1.00–1.49
  - Tier 2: rating 1.50–1.79
  - Tier 3: rating 1.80–2.09
  - Tier 4: rating 2.10–2.39
  - Tier 5: rating 2.40–2.59
  - Tier 6: rating 2.60–2.79
  - Tier 7: rating 2.80–2.99
  - Tier 8: rating 3.00–3.14
  - Tier 9: rating 3.15–3.29
  - Tier 10: rating 3.30–3.44
  - Tier 11: rating 3.45–3.59
  - Tier 12: rating 3.60–3.74
  - Tier 13: rating 3.75–3.89
  - Tier 14: rating 3.90–4.04
  - Tier 15: rating 4.05–4.19
  - Tier 16: rating 4.20–4.34
  - Tier 17: rating 4.35–4.49
  - Tier 18: rating 4.50–4.64
  - Tier 19: rating 4.65–4.79
  - Tier 20: rating 4.80–5.00

- Expose these functions:
  - get_random_perfume(tier: int) -> Dictionary — returns a random perfume from that tier bracket
  - get_tier_for_rating(rating: float) -> int — returns the tier number for a given rating
  - get_tier_color(tier: int) -> Color — returns a color based on the most common accord in that tier. Use these defaults:
    - floral → Color("#E91E63")
    - woody → Color("#795548")
    - citrus → Color("#FFC107")
    - musky → Color("#9E9E9E")
    - sweet/vanilla → Color("#FFE0B2")
    - fresh/aquatic → Color("#03A9F4")
    - spicy → Color("#F44336")
    - amber → Color("#FF9800")
    - fruity → Color("#9C27B0")
    - default → Color("#FFFFFF")
  - get_tier_count(tier: int) -> int — returns how many perfumes are in that tier bracket

- On _ready(), print a summary like:
  "DataManager loaded. Tier 1: 234 perfumes, Tier 2: 512 perfumes, ... Tier 20: 89 perfumes. Total: 24063"

- Also register this script as an Autoload in project.godot under [autoload] section with name "DataManager"

This is GDScript for Godot 4.x. Use proper Godot 4 syntax.
```

**Verify:**
```powershell
# Open Godot and check the console output for the tier distribution print
# Or verify the file exists and has the right structure:
cat scripts/data/DataManager.gd
Select-String "autoload" project.godot
```

**Push:**
```powershell
git add .
git commit -m "Step 2: DataManager singleton — loads perfumes.json into 20 tier brackets"
git push
```

---

### Step 3 — SaveManager Singleton

```claude code prompt
Read documents/IMPLEMENTATION_GUIDE.md for full context.

Create scripts/managers/SaveManager.gd — a GDScript Autoload singleton.

Requirements:
- Save/load to "user://save_data.json"
- Data structure to persist (Dictionary):
  - grid_state: Array of 25 entries (one per grid slot), each is either null or a Dictionary with {tier, perfume_name, perfume_brand}
  - unlocked_perfumes: Array of Strings (perfume URLs or unique identifiers for the encyclopedia)
  - essence: int (soft currency, default 0)
  - upgrades: Dictionary with keys:
    - spawn_speed_level: int (default 0, max 3)
    - offline_rate_level: int (default 0, max 3)
    - offline_cap_level: int (default 0, max 2)
    - lucky_merge_level: int (default 0, max 2)
    - extra_grid: bool (default false)
  - last_logout_time: int (Unix timestamp)
  - stats: Dictionary with:
    - total_merges: int
    - highest_tier: int
    - total_perfumes_discovered: int

- Functions:
  - save_game() — writes current data to file
  - load_game() — reads from file, returns the data Dictionary, or returns default data if no save exists
  - get_default_data() -> Dictionary — returns a fresh save state with all defaults
  - set_logout_time() — called when game is about to close, saves current Unix time

- Auto-save: expose a save_game() function that other scripts will call after merges. Do NOT implement a timer-based auto-save yet.

- Register as Autoload in project.godot with name "SaveManager"
```

**Verify:**
```powershell
cat scripts/managers/SaveManager.gd
Select-String "SaveManager" project.godot
```

**Push:**
```powershell
git add .
git commit -m "Step 3: SaveManager singleton — save/load game state to user://save_data.json"
git push
```

---

## PHASE 2: Core Grid & Merge Mechanics

---

### Step 4 — Grid Scene (5x5 Empty Slots)

```claude code prompt
Read documents/IMPLEMENTATION_GUIDE.md for full context.

Create two scenes:

1. scenes/grid/GridSlot.tscn
   - Root node: Panel (or PanelContainer)
   - Custom minimum size: 190x190 pixels
   - Background: semi-transparent dark color (Color(0.15, 0.15, 0.2, 0.8)) with rounded corners (use a StyleBoxFlat)
   - Has a child CenterContainer for centering the PerfumeItem when one is placed
   - Attach script: scripts/grid/GridSlot.gd
   - GridSlot.gd should:
     - Have a variable: occupied_item (reference to a PerfumeItem node or null)
     - Have functions: is_empty() -> bool, place_item(item), remove_item() -> item
     - Store its grid index (0–24) as a variable set on initialization

2. scenes/main/GameScene.tscn
   - Root node: Control (full rect)
   - Background: a solid dark gradient or color (Color(0.08, 0.06, 0.12))
   - Child: MarginContainer (margins ~20px all sides)
     - Child: VBoxContainer
       - Child: a placeholder Control for the top HUD bar (height ~100px, we'll fill this later)
       - Child: GridContainer named "Grid"
         - Columns: 5
         - Add separation: 10px horizontal, 10px vertical
         - Instance 25 GridSlot.tscn scenes as children
       - Child: a placeholder Control for the bottom bar (height ~80px, for later)
   - Attach script: scripts/grid/Grid.gd
   - Grid.gd should:
     - On _ready(), get references to all 25 GridSlot children
     - Store them in an Array called slots
     - Initialize each slot with its index (0–24)
     - Have functions:
       - get_empty_slots() -> Array of GridSlot references that are empty
       - get_slot(index: int) -> GridSlot
       - is_full() -> bool

- Set GameScene.tscn as the main scene in project.godot under run/main_scene

When you open the project in Godot and run it, you should see a 5x5 grid of dark rounded squares centered on screen with a dark background.
```

**Verify:**
```powershell
ls scenes/grid/GridSlot.tscn
ls scenes/main/GameScene.tscn
cat scripts/grid/GridSlot.gd
cat scripts/grid/Grid.gd
Select-String "main_scene" project.godot
```

**Push:**
```powershell
git add .
git commit -m "Step 4: Grid scene — 5x5 grid of empty slots rendering on screen"
git push
```

---

### Step 5 — PerfumeItem Scene

```claude code prompt
Read documents/IMPLEMENTATION_GUIDE.md for full context.

Create scenes/grid/PerfumeItem.tscn with script scripts/grid/PerfumeItem.gd

PerfumeItem.tscn:
- Root node: Control (custom minimum size 170x170)
  - Child: ColorRect named "BottleShape" (represents the perfume bottle, size ~120x150, centered)
    - Use rounded corners via a StyleBoxFlat with corner_radius 12
  - Child: Label named "TierLabel" (top-left corner of the bottle, bold, font size 24)
    - Shows the tier number like "T5"
  - Child: Label named "NameLabel" (bottom of the item, centered, font size 12, truncated if too long)
    - Shows the perfume name
  - Child: Label named "BrandLabel" (below NameLabel, centered, font size 10, lighter color)
    - Shows the brand name

PerfumeItem.gd:
- Variables:
  - tier: int
  - perfume_data: Dictionary (the full perfume entry from DataManager)
- Function: setup(p_tier: int, p_data: Dictionary):
  - Sets tier and perfume_data
  - Updates TierLabel text to "T" + str(tier)
  - Updates NameLabel text to perfume_data.name (capitalize first letters)
  - Updates BrandLabel text to perfume_data.brand (capitalize first letters)
  - Sets BottleShape color to DataManager.get_tier_color(tier)

Now modify Grid.gd to add a test function:
- In _ready(), after initializing slots, call a test function that:
  - Gets a random Tier 1 perfume from DataManager
  - Instances PerfumeItem.tscn
  - Calls setup() on it with the tier and data
  - Places it in grid slot 0
  - Repeats for Tier 5 in slot 1 and Tier 10 in slot 2
  - This is just for visual testing — we'll remove it later

When you run the game, you should see 3 colored perfume bottles in the first 3 grid slots with their tier numbers, names, and brands visible.
```

**Verify:**
```powershell
cat scripts/grid/PerfumeItem.gd
ls scenes/grid/PerfumeItem.tscn
```

**Push:**
```powershell
git add .
git commit -m "Step 5: PerfumeItem scene — colored bottles with tier, name, brand labels"
git push
```

---

### Step 6 — Drag & Drop System

```claude code prompt
Read documents/IMPLEMENTATION_GUIDE.md for full context.

Implement drag and drop for PerfumeItem nodes on the grid.

Modify PerfumeItem.gd:
- Add input handling via _gui_input(event) on the root Control:
  - On InputEventMouseButton (pressed, left click) OR InputEventScreenTouch (pressed):
    - Start dragging: store the original parent slot, reparent the item to the root viewport (so it renders on top), set a flag is_dragging = true
  - On _process(delta) while is_dragging:
    - Move the item position to follow the mouse/touch position (centered on the item)
  - On InputEventMouseButton (released) OR InputEventScreenTouch (released):
    - Stop dragging
    - Determine which grid slot is under the current position (use get_global_rect() of each slot, or raycast)
    - Call Grid.attempt_drop(self, target_slot_index)

Modify Grid.gd:
- Add function: attempt_drop(item: PerfumeItem, target_slot: GridSlot):
  - If target_slot is null (dropped outside grid): return item to original slot
  - If target_slot is empty: move item to target slot
  - If target_slot has a perfume of the SAME tier as the dragged item: call merge (we'll implement merge logic in Step 7, for now just print "MERGE! Tier X + Tier X")
  - If target_slot has a perfume of a DIFFERENT tier: return item to original slot
- Add function: get_slot_at_position(global_pos: Vector2) -> GridSlot — loops through all slots and checks which one contains the position

- Remove the test items from Step 5's _ready(). Instead, spawn 5 random Tier 1 perfumes on slots 0–4 for testing drag and drop.

The drag should work with both mouse and touch input. The item should visually follow the cursor/finger while being dragged and snap into grid slots on release.
```

**Verify:**
```powershell
cat scripts/grid/PerfumeItem.gd
cat scripts/grid/Grid.gd
# Then run the game in Godot and test dragging items between slots
```

**Push:**
```powershell
git add .
git commit -m "Step 6: Drag and drop system — move perfumes between grid slots"
git push
```

---

### Step 7 — Merge Logic

```claude code prompt
Read documents/IMPLEMENTATION_GUIDE.md for full context.

Create scripts/grid/MergeManager.gd as an Autoload singleton (register in project.godot).

MergeManager.gd:
- signal merge_completed(new_item: PerfumeItem, tier: int)
- signal new_perfume_discovered(perfume_data: Dictionary)

- Function: execute_merge(item_a: PerfumeItem, item_b: PerfumeItem, target_slot: GridSlot, grid: Grid):
  1. Verify both items have the same tier. If not, return false.
  2. Calculate new_tier = item_a.tier + 1
  3. If new_tier > 20: print "MAX TIER REACHED!" and return false (we'll add a celebration later)
  4. Get a random perfume from the new tier: var new_data = DataManager.get_random_perfume(new_tier)
  5. Remove item_a from its slot (call slot.remove_item() and queue_free() on item_a)
  6. Remove item_b from its slot (call slot.remove_item() and queue_free() on item_b)
  7. Instance a new PerfumeItem, call setup(new_tier, new_data)
  8. Place the new item in target_slot
  9. Check if this perfume URL is in SaveManager's unlocked list:
     - If NOT: add it, emit new_perfume_discovered signal
     - If YES: do nothing (already discovered)
  10. Update SaveManager stats: increment total_merges, update highest_tier if new_tier > current
  11. Add merge essence reward: 10 * new_tier (we'll wire this to EconomyManager later, for now just print "Earned X essence")
  12. Call SaveManager.save_game()
  13. Emit merge_completed signal
  14. Return true

Now update Grid.gd attempt_drop():
- When same-tier items are detected, call MergeManager.execute_merge() instead of printing
- Pass the dragged item, the target slot's item, the target slot, and self (grid reference)

Spawn 10 random Tier 1 perfumes across the grid for testing. You should be able to drag one Tier 1 onto another Tier 1 and get a Tier 2 perfume.
```

**Verify:**
```powershell
cat scripts/grid/MergeManager.gd
Select-String "MergeManager" project.godot
# Run the game, merge two Tier 1 items, check console for "Earned X essence" print
```

**Push:**
```powershell
git add .
git commit -m "Step 7: Merge logic — combine same-tier perfumes to get next tier"
git push
```

---

### Step 8 — Merge Animation

```claude code prompt
Read documents/IMPLEMENTATION_GUIDE.md for full context.

Add merge animation to the merge process in MergeManager.gd.

Modify MergeManager.execute_merge():
- Instead of immediately removing both items and creating the new one, animate:
  1. Tween both item_a and item_b:
     - Scale from Vector2(1, 1) to Vector2(0, 0) over 0.15 seconds, ease in
     - Move both toward the target_slot's center position over 0.15 seconds
  2. After the tween finishes (use tween.finished signal or await):
     - queue_free() both old items
     - Instance the new PerfumeItem
     - Set its scale to Vector2(0, 0)
     - Place it in the target slot
     - Tween it from Vector2(0, 0) to Vector2(1.15, 1.15) over 0.15s, then to Vector2(1, 1) over 0.1s (bounce effect)
  3. Add a CPUParticles2D burst at the merge point:
     - Create scenes/effects/MergeParticles.tscn
     - CPUParticles2D node, one_shot = true, emitting = false
     - Amount: 12 particles
     - Spread: 180 degrees
     - Initial velocity: 150
     - Gravity: Vector2(0, 200)
     - Scale: starts at 3, ends at 0
     - Color: match the new tier's color
     - Lifetime: 0.4 seconds
     - In MergeManager, instance MergeParticles at the merge position, set emitting = true
     - Auto-free after particles finish (use lifetime timer + queue_free)

The merge should now feel snappy and satisfying: items shrink toward each other, particles pop, new item bounces in.
```

**Verify:**
```powershell
ls scenes/effects/MergeParticles.tscn
cat scripts/grid/MergeManager.gd
# Run the game, merge two items, visually confirm the animation plays
```

**Push:**
```powershell
git add .
git commit -m "Step 8: Merge animation — shrink, particle burst, bounce-in effect"
git push
```

---

## PHASE 3: Idle & Economy Systems

---

### Step 9 — Auto-Spawn System

```claude code prompt
Read documents/IMPLEMENTATION_GUIDE.md for full context.

Create scripts/managers/SpawnManager.gd as an Autoload singleton (register in project.godot).

SpawnManager.gd:
- Variable: spawn_interval — base 3.0 seconds
- Variable: spawn_timer — internal countdown
- Variable: grid_reference — set via a function or on _ready() by finding the Grid node

- Spawn speed levels (based on SaveManager upgrade):
  - Level 0: 3.0s
  - Level 1: 2.5s
  - Level 2: 2.0s
  - Level 3: 1.5s

- Function: get_current_spawn_interval() -> float:
  - Read SaveManager's spawn_speed_level and return the corresponding interval

- In _process(delta):
  - Decrement spawn_timer by delta
  - When spawn_timer <= 0:
    - Reset spawn_timer to get_current_spawn_interval()
    - Get empty slots from Grid
    - If no empty slots: do nothing (grid is full)
    - If empty slots exist: pick a random empty slot, instance a Tier 1 PerfumeItem, place it in that slot with a fade-in animation (modulate alpha 0 to 1 over 0.3s)

- Function: set_grid(grid: Node) — called by GameScene to pass the grid reference
- Function: start_frenzy(duration: float) — temporarily sets spawn interval to 0.5s for the given duration, then reverts (for ad reward later)

Modify GameScene.gd (or the script on GameScene.tscn):
- On _ready(), call SpawnManager.set_grid($Grid) or however the grid node is referenced

Remove any test spawn code from Grid.gd _ready(). The SpawnManager now handles all spawning.

When you run the game, Tier 1 perfumes should appear one by one every 3 seconds in random empty slots.
```

**Verify:**
```powershell
cat scripts/managers/SpawnManager.gd
Select-String "SpawnManager" project.godot
# Run the game, watch Tier 1 items auto-spawn every 3 seconds
```

**Push:**
```powershell
git add .
git commit -m "Step 9: Auto-spawn system — Tier 1 perfumes spawn every 3 seconds"
git push
```

---

### Step 10 — Essence (Soft Currency) System

```claude code prompt
Read documents/IMPLEMENTATION_GUIDE.md for full context.

Create scripts/managers/EconomyManager.gd as an Autoload singleton (register in project.godot).

EconomyManager.gd:
- signal essence_changed(new_amount: int)

- Variable: essence — int, loaded from SaveManager on _ready()

- Function: add_essence(amount: int):
  - essence += amount
  - Emit essence_changed signal
  - Update SaveManager's essence value

- Function: spend_essence(amount: int) -> bool:
  - If essence >= amount: subtract, emit signal, update SaveManager, return true
  - Else: return false

- Function: get_essence() -> int: return essence

- Function: get_merge_reward(tier: int) -> int:
  - Returns 10 * tier (so Tier 5 merge gives 50 Essence)

- Function: get_manual_buy_cost(tier: int) -> int:
  - Tier 1: 10
  - Tier 2: 50
  - Tier 3: 200
  - Tier 4: 800
  - Tier 5+: 800 * (3 ^ (tier - 4)) — exponential, gets very expensive

Now wire up the merge reward:
- In MergeManager.execute_merge(), replace the "Earned X essence" print with:
  EconomyManager.add_essence(EconomyManager.get_merge_reward(new_tier))

The essence value is now tracked. We'll display it on the HUD in Step 12.
```

**Verify:**
```powershell
cat scripts/managers/EconomyManager.gd
Select-String "EconomyManager" project.godot
# Run the game, merge items, check console for essence_changed signals
```

**Push:**
```powershell
git add .
git commit -m "Step 10: Essence economy — earn currency from merges, spend on manual buys"
git push
```

---

### Step 11 — Offline Earnings

```claude code prompt
Read documents/IMPLEMENTATION_GUIDE.md for full context.

Add offline earnings calculation to EconomyManager.gd and SaveManager.gd.

Modify SaveManager.gd:
- In set_logout_time(): save current Unix time via Time.get_unix_time_from_system()
- Add a notification handler: func _notification(what):
  - If what == NOTIFICATION_WM_CLOSE_REQUEST or NOTIFICATION_WM_GO_BACK_REQUEST:
    - Call set_logout_time() and save_game()
- Make sure project.godot has: config/auto_accept_quit=false (if needed for the notification to work)

Modify EconomyManager.gd:
- Function: calculate_offline_earnings() -> Dictionary:
  - Get last_logout_time from SaveManager
  - If no logout time (first play): return {essence = 0, seconds = 0}
  - Calculate seconds_away = current_unix_time - last_logout_time
  - Offline rate levels:
    - Level 0: 1 Essence/sec
    - Level 1: 2 Essence/sec
    - Level 2: 4 Essence/sec
    - Level 3: 8 Essence/sec
  - Offline cap levels:
    - Level 0: 28800 seconds (8 hours)
    - Level 1: 43200 seconds (12 hours)
    - Level 2: 86400 seconds (24 hours)
  - Cap seconds_away at the offline cap
  - Calculate total = seconds_away * rate
  - Return {essence = total, seconds = seconds_away, can_double = true}

- Function: collect_offline_earnings(double: bool):
  - If double: add essence * 2
  - Else: add essence * 1
  - Reset the last_logout_time

We'll create the "Welcome Back" popup UI in Step 12 (HUD). For now, just print the offline earnings on startup.

Modify GameScene.gd _ready():
- Call var offline = EconomyManager.calculate_offline_earnings()
- If offline.essence > 0: print("Welcome back! You earned %d essence in %d seconds" % [offline.essence, offline.seconds])
```

**Verify:**
```powershell
cat scripts/managers/EconomyManager.gd
cat scripts/managers/SaveManager.gd
# Run game, close it, wait 10 seconds, reopen — check console for offline earnings print
```

**Push:**
```powershell
git add .
git commit -m "Step 11: Offline earnings — accumulate essence while away, capped by upgrade level"
git push
```

---

## PHASE 4: UI Screens

---

### Step 12 — Main HUD

```claude code prompt
Read documents/IMPLEMENTATION_GUIDE.md for full context.

Create scenes/ui/HUD.tscn and attach scripts/ui/HUD.gd.

HUD.tscn — a CanvasLayer (layer 1) so it renders above the grid:
- Top Bar (HBoxContainer, anchored to top, height ~80px, with margin):
  - Left side: Essence icon (a simple colored circle or placeholder sprite) + Label showing essence amount
    - The Label should animate when essence changes (brief scale up then back)
  - Right side: Settings gear icon button (placeholder, just a Button with "⚙" text for now)

- Bottom Bar (HBoxContainer, anchored to bottom, height ~70px, with margin):
  - Button: "📖 Collection" — opens Encyclopedia (placeholder, just print "open encyclopedia" for now)
  - Button: "🛒 Shop" — opens Shop (placeholder, just print "open shop" for now)
  - Button: "➕" — manual buy, costs 10 Essence, spawns a Tier 1 perfume on a random empty slot
    - On press: call EconomyManager.spend_essence(10), if success call SpawnManager to spawn a Tier 1
    - If grid is full: show brief "Grid is full!" text

- Floating element (for later): placeholder position for the Rare Drop ad trigger button

- Welcome Back Popup (scenes/ui/WelcomeBack.tscn):
  - A centered Panel popup
  - Label: "Welcome Back!"
  - Label: "You earned X Essence while away!"
  - Button: "Collect" — calls EconomyManager.collect_offline_earnings(false), closes popup
  - Button: "Watch Ad to Double" — placeholder for now, just calls collect_offline_earnings(true), closes popup
  - Only shown when offline earnings > 0

Wire up:
- HUD.gd connects to EconomyManager.essence_changed signal to update the essence display
- GameScene.gd instances HUD.tscn and adds it
- GameScene.gd checks offline earnings on _ready() and shows WelcomeBack popup if needed

Style the buttons and panels with dark theme matching the grid (dark backgrounds, white/light text, rounded corners).
```

**Verify:**
```powershell
ls scenes/ui/HUD.tscn
ls scenes/ui/WelcomeBack.tscn
cat scripts/ui/HUD.gd
# Run game: essence counter should appear at top, buttons at bottom, manual buy should work
```

**Push:**
```powershell
git add .
git commit -m "Step 12: Main HUD — essence counter, manual buy, collection/shop buttons, welcome back popup"
git push
```

---

### Step 13 — First-Time Info Card

```claude code prompt
Read documents/IMPLEMENTATION_GUIDE.md for full context.

Create scenes/ui/InfoCard.tscn and scripts/ui/InfoCard.gd.

InfoCard.tscn — a CanvasLayer popup:
- Dark semi-transparent background overlay (ColorRect, full screen, Color(0, 0, 0, 0.6))
- Centered PanelContainer (width ~900px, height ~auto, max ~1200px):
  - VBoxContainer with padding ~30px:
    - Label: Perfume name (font size 32, bold, centered)
    - Label: Brand name (font size 20, lighter color, centered)
    - HSeparator
    - HBoxContainer: Rating display — Label "★ 4.21" (font size 24) + Label "(28,450 votes)" (font size 14)
    - HBoxContainer: Gender badge — Label with background color (e.g., "♂ Men" / "♀ Women" / "⚤ Unisex")
    - HSeparator
    - Label: "Top Notes" (font size 16, bold)
    - Label: comma-separated list of top notes (font size 14, wrapping)
    - Label: "Heart Notes" (font size 16, bold)
    - Label: comma-separated list of middle notes (font size 14, wrapping)
    - Label: "Base Notes" (font size 16, bold)
    - Label: comma-separated list of base notes (font size 14, wrapping)
    - HSeparator
    - HBoxContainer: Accord tags — for each accord in perfume_data.accords, create a small Label with a colored background (using get_tier_color logic for the accord name), rounded corners, padding
    - Spacer
    - Button: "Nice!" (centered, large, accent color) — closes the popup

InfoCard.gd:
- Function: show_perfume(perfume_data: Dictionary, tier: int):
  - Populates all the labels with the perfume data
  - Animates the panel sliding up from the bottom (tween position or modulate)
- Function: _on_nice_pressed(): closes/hides the popup with a slide-down animation, then queue_free()

Wire up:
- MergeManager: when new_perfume_discovered signal is emitted, instance InfoCard and call show_perfume()
- Add the InfoCard to the scene tree as a child of the root or a UI layer so it renders on top of everything
```

**Verify:**
```powershell
ls scenes/ui/InfoCard.tscn
cat scripts/ui/InfoCard.gd
# Run game, merge two Tier 1 items — the first time should show the InfoCard popup
# Merge the same perfume again — should NOT show the popup
```

**Push:**
```powershell
git add .
git commit -m "Step 13: Info card popup — shows perfume details on first discovery"
git push
```

---

### Step 14 — Encyclopedia Screen

```claude code prompt
Read documents/IMPLEMENTATION_GUIDE.md for full context.

Create scenes/ui/Encyclopedia.tscn and scripts/ui/Encyclopedia.gd.

Encyclopedia.tscn — full screen overlay (CanvasLayer):
- Dark background (full rect, Color(0.08, 0.06, 0.12, 0.95))
- VBoxContainer (full screen with margins):
  - Top bar (HBoxContainer):
    - Button: "← Back" (returns to game)
    - Label: "Fragrance Encyclopedia" (centered, font size 28)
    - Label: "127 / 24,063" (right-aligned, shows discovered/total count)
  - Filter bar (HBoxContainer):
    - Button group (toggle buttons): "All", "T1-5", "T6-10", "T11-15", "T16-20"
    - Button group (toggle): "All", "Men", "Women", "Unisex"
  - ScrollContainer (fills remaining space):
    - GridContainer (columns: 4, for portrait layout):
      - Each cell is a small perfume card:
        - If unlocked: colored bottle (tier color), name below, tappable to open InfoCard
        - If locked: greyed-out silhouette with "???" text

Encyclopedia.gd:
- On open: read SaveManager.unlocked_perfumes list
- Build the grid by iterating through DataManager tier brackets
- Implement filtering by tier range and gender
- On perfume card tap (if unlocked): instance and show InfoCard with that perfume's data
- DO NOT load all 24,063 at once. Use lazy loading / virtual scrolling:
  - Only create UI nodes for perfumes currently visible on screen
  - As the player scrolls, create new nodes and free old ones
  - Or simpler: paginate — show 50 at a time with "Load More" button

Wire up:
- HUD's "Collection" button: instances Encyclopedia and adds to scene tree
- Encyclopedia "Back" button: closes/frees the encyclopedia
```

**Verify:**
```powershell
ls scenes/ui/Encyclopedia.tscn
cat scripts/ui/Encyclopedia.gd
# Run game, merge some items, tap Collection button, verify discovered perfumes show up
```

**Push:**
```powershell
git add .
git commit -m "Step 14: Encyclopedia screen — browse discovered perfumes with tier/gender filters"
git push
```

---

### Step 15 — Shop Screen

```claude code prompt
Read documents/IMPLEMENTATION_GUIDE.md for full context.

Create scenes/ui/Shop.tscn and scripts/ui/Shop.gd.

Shop.tscn — full screen overlay (CanvasLayer):
- Dark background (same as Encyclopedia)
- VBoxContainer with margins:
  - Top bar:
    - Button: "← Back"
    - Label: "Perfumery Shop" (centered, font size 28)
    - Essence counter (mirrored from HUD so player sees their balance)
  - ScrollContainer:
    - VBoxContainer of upgrade cards. Each upgrade card is a PanelContainer:
      - HBoxContainer:
        - Left: VBoxContainer with upgrade name (bold, size 20) and description (size 14, lighter)
        - Right: VBoxContainer with current level indicator ("Lv. 2/3") and Buy button showing cost

Upgrades list:

1. "Faster Spawns" — reduces auto-spawn timer
   - Description: "Perfumes appear more frequently"
   - Levels: 0→1: 500 Essence, 1→2: 2000, 2→3: 8000
   - Effect label: "3.0s → 2.5s → 2.0s → 1.5s"

2. "Offline Earnings" — increases essence per second while away
   - Description: "Earn more while you're away"
   - Levels: 0→1: 300, 1→2: 1200, 2→3: 5000
   - Effect label: "1/s → 2/s → 4/s → 8/s"

3. "Offline Storage" — increases max offline accumulation time
   - Description: "Store more offline earnings"
   - Levels: 0→1: 1000, 1→2: 5000
   - Effect label: "8h → 12h → 24h"

4. "Lucky Merges" — chance to skip a tier on merge
   - Description: "Chance to jump 2 tiers on merge"
   - Levels: 0→1: 2000, 1→2: 8000
   - Effect label: "0% → 10% → 20%"

5. "Extra Columns" — adds a 6th column to the grid (5x6 = 30 slots)
   - Description: "More room to merge"
   - One-time purchase: 50000 Essence
   - Effect label: "25 slots → 30 slots"

Shop.gd:
- On open: read current upgrade levels from SaveManager
- On buy button press:
  - Call EconomyManager.spend_essence(cost)
  - If success: increment the upgrade level in SaveManager, save, refresh the UI
  - If fail: briefly flash the button red or show "Not enough Essence!"
- If upgrade is maxed: show "MAX" instead of buy button, greyed out

Wire up:
- HUD's "Shop" button: instances Shop and adds to scene tree
- Shop "Back" button: closes/frees the shop

Now also wire up the Lucky Merge upgrade:
- In MergeManager.execute_merge(): after calculating new_tier, check SaveManager lucky_merge_level
  - Level 1: 10% chance new_tier += 1 (extra tier skip)
  - Level 2: 20% chance
  - If triggered: show a brief "LUCKY!" text flash on screen
```

**Verify:**
```powershell
ls scenes/ui/Shop.tscn
cat scripts/ui/Shop.gd
# Run game, earn some essence from merges, open shop, buy an upgrade, verify it takes effect
```

**Push:**
```powershell
git add .
git commit -m "Step 15: Shop screen — 5 upgrades with escalating costs and instant effects"
git push
```

---

## PHASE 5: Monetization

---

### Step 16 — Ad Manager (Placeholder)

```claude code prompt
Read documents/IMPLEMENTATION_GUIDE.md for full context.

Create scripts/managers/AdManager.gd as an Autoload singleton (register in project.godot).

AdManager.gd:
- Variable: is_test_mode = true (we'll set false for production)
- Variable: ad_ready = true (simulated, always ready in test mode)

- signal ad_completed(success: bool)
- signal ad_started

- Function: show_rewarded_ad(callback: Callable):
  - If is_test_mode:
    - Print "TEST MODE: Simulating rewarded ad..."
    - Wait 1 second (use a Timer or await get_tree().create_timer(1.0).timeout)
    - Print "TEST MODE: Ad completed successfully"
    - Call callback with true
  - Else (production — we'll fill this in for Poki/CrazyGames later):
    - Call JavaScript bridge to show rewarded video
    - On success: call callback with true
    - On fail/skip: call callback with false

- Function: is_ad_available() -> bool:
  - In test mode: always return true
  - In production: check with ad network

This is a skeleton. The actual Poki/AdMob integration happens in Phase 7 before export. For now all ads are simulated with a 1-second delay.
```

**Verify:**
```powershell
cat scripts/managers/AdManager.gd
Select-String "AdManager" project.godot
```

**Push:**
```powershell
git add .
git commit -m "Step 16: Ad manager placeholder — simulated rewarded ads for testing"
git push
```

---

### Step 17 — Ad Trigger Points

```claude code prompt
Read documents/IMPLEMENTATION_GUIDE.md for full context.

Implement the 3 ad trigger points using AdManager.

1. Rare Drop (scripts/managers/RareDropManager.gd — new Autoload singleton):
   - Every 60–90 seconds (random interval), show a floating button on the HUD
   - The button says "🎁 Free Rare Perfume!" with a glow/pulse animation
   - It auto-disappears after 10 seconds if not tapped
   - On tap:
     - Calculate rare_tier = average tier of items on grid + 2 (min Tier 3, max Tier 20)
     - Call AdManager.show_rewarded_ad() with a callback that:
       - On success: spawn a perfume of rare_tier on a random empty slot. If grid full, show "Make room first!"
       - On fail: do nothing
   - Register as Autoload in project.godot

2. Double Offline Earnings:
   - Modify WelcomeBack.tscn:
     - The "Watch Ad to Double" button now calls AdManager.show_rewarded_ad()
     - Callback on success: EconomyManager.collect_offline_earnings(true)
     - Callback on fail: do nothing, keep popup open

3. Frenzy Mode:
   - Add a button to the HUD: "⚡ Frenzy" (with a cooldown timer display)
   - Available every 5 minutes (300 seconds). Show countdown when on cooldown.
   - On tap: call AdManager.show_rewarded_ad() with callback:
     - On success: call SpawnManager.start_frenzy(30.0) — spawns every 0.5s for 30 seconds
     - Add a golden border glow effect to the screen during frenzy (a ColorRect frame with animated alpha)
     - Show countdown "FRENZY: 28s... 27s... 26s..." on screen
     - On fail: do nothing
```

**Verify:**
```powershell
cat scripts/managers/RareDropManager.gd
Select-String "RareDropManager" project.godot
# Run game, wait 60-90 seconds for rare drop button, tap it, verify simulated ad and item spawn
# Test frenzy button, verify rapid spawning for 30 seconds
```

**Push:**
```powershell
git add .
git commit -m "Step 17: Ad triggers — rare drop, double offline, frenzy mode with simulated ads"
git push
```

---

## PHASE 6: Polish & Audio

---

### Step 18 — Sound Effects

```claude code prompt
Read documents/IMPLEMENTATION_GUIDE.md for full context.

Create scripts/managers/AudioManager.gd as an Autoload singleton (register in project.godot).

AudioManager.gd:
- Preload all sound effects from assets/audio/
- Functions for each sound:
  - play_merge() — satisfying pop/bubble sound
  - play_pickup() — soft click
  - play_drop() — soft thud
  - play_unlock() — magical chime for first discovery
  - play_button() — UI click
  - play_essence() — coin clink
  - play_rare_drop() — whoosh
  - play_frenzy() — power-up sound
- Each function creates an AudioStreamPlayer, plays the sound, then queue_frees after
- Volume controlled by a master_volume variable (0.0 to 1.0)
- Mute toggle

For now, we don't have actual audio files. Create placeholder .tres or .wav files (silent or use Godot's built-in tone generator to create simple synth sounds):
- Use AudioStreamGenerator or create minimal procedural sounds in code
- OR create a note in the README that audio files need to be added manually from freesound.org

Wire up the sounds:
- MergeManager: play_merge() on successful merge, play_unlock() on new discovery
- PerfumeItem: play_pickup() on drag start, play_drop() on drag end
- HUD buttons: play_button() on any button press
- EconomyManager: play_essence() on essence earned
- RareDropManager: play_rare_drop() on rare drop appearance
- SpawnManager: play_frenzy() on frenzy activation
```

**Verify:**
```powershell
cat scripts/managers/AudioManager.gd
Select-String "AudioManager" project.godot
# Note: actual audio will need real .wav/.ogg files added to assets/audio/
```

**Push:**
```powershell
git add .
git commit -m "Step 18: Audio manager — sound effect hooks for all game events (placeholder audio)"
git push
```

---

### Step 19 — Background Music & Settings Screen

```claude code prompt
Read documents/IMPLEMENTATION_GUIDE.md for full context.

Two tasks in this step:

TASK A — Background Music:
- Add an AudioStreamPlayer node to GameScene.tscn named "BGM"
- Set it to autoplay and loop
- For now, leave the stream empty (we'll add a royalty-free track later)
- AudioManager.gd: add functions set_music_volume(vol: float) and set_sfx_volume(vol: float)
- BGM volume controlled separately from SFX

TASK B — Settings Screen:
Create scenes/ui/Settings.tscn and scripts/ui/Settings.gd

Settings.tscn — popup overlay (CanvasLayer):
- Dark semi-transparent background
- Centered Panel (width ~800px):
  - VBoxContainer with padding:
    - Label: "Settings" (font size 28, centered)
    - HSeparator
    - HBoxContainer: Label "Music" + HSlider (0 to 100, default 80)
    - HBoxContainer: Label "Sound Effects" + HSlider (0 to 100, default 100)
    - HBoxContainer: Label "Mute All" + CheckButton
    - HSeparator
    - Button: "Reset Progress" (red/warning color)
      - On press: show a confirmation dialog "Are you sure? This will delete all progress!"
      - On confirm: call SaveManager.get_default_data(), save, restart the scene
    - HSeparator
    - Label: "PerfumeFusion v1.0" (small, centered, grey)
    - Label: "Data from Fragrantica.com" (small, centered, grey)
    - Spacer
    - Button: "Close" — closes settings

Settings.gd:
- On slider change: call AudioManager.set_music_volume() / set_sfx_volume()
- On mute toggle: call AudioManager.set_mute()
- Save audio preferences in SaveManager (add music_volume, sfx_volume, muted fields)

Wire up:
- HUD gear button: instances Settings and shows it
```

**Verify:**
```powershell
ls scenes/ui/Settings.tscn
cat scripts/ui/Settings.gd
# Run game, open settings, move sliders, close, reopen — values should persist
```

**Push:**
```powershell
git add .
git commit -m "Step 19: Settings screen — volume sliders, mute toggle, reset progress"
git push
```

---

## PHASE 7: Export & Distribution

---

### Step 20 — HTML5 Export & Optimization

```claude code prompt
Read documents/IMPLEMENTATION_GUIDE.md for full context.

Prepare the project for HTML5 export:

1. Create an export preset in project.godot for HTML5/Web:
   - Or document the manual steps: Project → Export → Add Preset → Web
   - Set the export path to export/web/index.html

2. Create a data optimization script: scripts/data/optimize_data.gd (or a standalone Python script)
   - Read perfumes.json
   - Remove the "url" field from each entry (not needed in game, saves ~1MB)
   - Write to data/perfumes_slim.json
   - Update DataManager to load perfumes_slim.json instead

3. Create export/web/ folder
4. Add to .gitignore: export/

5. Document in README.md:
   - How to export: Project → Export → Web → Export Project
   - Expected build size target: under 15MB
   - How to test locally: python -m http.server in the export/web/ folder

6. Also create a build checklist in documents/:
   - [ ] Set AdManager.is_test_mode = false
   - [ ] Verify perfumes_slim.json is used
   - [ ] Test in Chrome and Firefox
   - [ ] Test on mobile browser
   - [ ] Verify save/load works in browser (user:// maps to IndexedDB)
```

**Verify:**
```powershell
ls export/
cat README.md
# Try exporting in Godot: Project → Export → Web
```

**Push:**
```powershell
git add .
git commit -m "Step 20: HTML5 export setup — data optimization, build checklist, README"
git push
```

---

### Step 21 — Poki SDK Integration

```claude code prompt
Read documents/IMPLEMENTATION_GUIDE.md for full context.

Integrate the Poki SDK for web deployment.

1. Create a custom HTML shell template: export/web/custom_shell.html
   - Based on Godot's default HTML5 shell
   - Add the Poki SDK script tag: <script src="https://game-cdn.poki.com/scripts/v2/poki-sdk.js"></script>

2. Modify AdManager.gd for Poki integration:
   - In production mode (is_test_mode = false):
   - On game load: call via JavaScriptBridge:
     - PokiSDK.init() then PokiSDK.gameLoadingFinished()
   - show_rewarded_ad():
     - Call PokiSDK.rewardedBreak() via JavaScriptBridge
     - Handle the promise resolution (success/fail) and call the callback
   - Add a function: show_commercial_break():
     - Call PokiSDK.commercialBreak() — use this between screen transitions (e.g., opening Encyclopedia)
     - Don't overuse — max once every 3 minutes

3. Modify GameScene.gd:
   - On _ready(): if running in web (OS.has_feature("web")):
     - Call AdManager.init_poki()

4. Update the build checklist with Poki-specific items:
   - [ ] Custom shell template selected in export settings
   - [ ] PokiSDK.init() called on load
   - [ ] Rewarded ads tested and working
   - [ ] Game submitted at developers.poki.com
```

**Verify:**
```powershell
cat export/web/custom_shell.html
cat scripts/managers/AdManager.gd
# Full verification requires exporting and testing in browser
```

**Push:**
```powershell
git add .
git commit -m "Step 21: Poki SDK integration — rewarded and commercial ad breaks"
git push
```

---

### Step 22 — CrazyGames SDK Integration

```claude code prompt
Read documents/IMPLEMENTATION_GUIDE.md for full context.

Add CrazyGames as a secondary web distribution platform.

1. Modify the custom HTML shell (or create a separate one for CrazyGames):
   - Add: <script src="https://sdk.crazygames.com/crazygames-sdk-v3.js"></script>

2. Modify AdManager.gd:
   - Add detection: check if PokiSDK or CrazyGamesSdk is available in the JavaScript context
   - Function: detect_platform() -> String — returns "poki", "crazygames", or "none"
   - Route ad calls to the correct SDK based on detected platform
   - CrazyGames rewarded ad:
     - Call window.CrazyGames.SDK.ad.requestAd("rewarded") via JavaScriptBridge
     - Handle callbacks for adStarted, adFinished, adError

3. Update README with CrazyGames submission instructions:
   - Submit at https://developer.crazygames.com/
   - Upload the HTML5 export zip
   - CrazyGames reviews within 1-2 weeks
```

**Verify:**
```powershell
cat scripts/managers/AdManager.gd
# Full verification requires testing on CrazyGames dev environment
```

**Push:**
```powershell
git add .
git commit -m "Step 22: CrazyGames SDK integration — dual platform ad support"
git push
```

---

### Step 23 — Android Export (Post-Web Validation)

```claude code prompt
Read documents/IMPLEMENTATION_GUIDE.md for full context.

Prepare Android export (to be done AFTER web version is validated and earning revenue).

1. Document Android setup steps in documents/ANDROID_EXPORT.md:
   - Install Android Studio and SDK
   - Configure Godot: Editor → Editor Settings → Export → Android
   - Set SDK path, JDK path
   - Generate a debug keystore and a release keystore
   - Create export preset for Android in project.godot

2. AdMob Integration plan (document, don't implement yet):
   - Use godot-admob-plugin (open source)
   - Replace AdManager's web SDK calls with AdMob calls when OS.has_feature("android")
   - Rewarded video ad unit ID (to be created in AdMob console)
   - Interstitial ad unit ID
   - Test device ID for development

3. Google Play listing checklist:
   - [ ] $25 developer account fee paid
   - [ ] App icon (512x512)
   - [ ] Feature graphic (1024x500)
   - [ ] Screenshots (phone + tablet)
   - [ ] Privacy policy URL
   - [ ] Content rating questionnaire
   - [ ] Target audience and content
   - [ ] App description and keywords for ASO

4. Modify AdManager.gd:
   - Add platform routing: if OS.has_feature("web") → web SDK, if OS.has_feature("android") → AdMob
   - Skeleton functions for AdMob (to be filled when ready)

This step is documentation and planning only. Actual Android build happens after web launch.
```

**Verify:**
```powershell
cat documents/ANDROID_EXPORT.md
```

**Push:**
```powershell
git add .
git commit -m "Step 23: Android export documentation and AdMob integration plan"
git push
```

---

## 🏁 DONE

After Step 23, you have a complete, shippable perfume merge game. The priority order for launch:
1. Export HTML5 and test locally
2. Submit to Poki
3. Submit to CrazyGames
4. Post gameplay clips on TikTok/YouTube Shorts
5. File W-8BEN when first payout is pending
6. Port to Android once web revenue is validated
