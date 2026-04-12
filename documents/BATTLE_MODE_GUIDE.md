# PerfumeFusion — Battle Mode & Main Menu Implementation Guide

---

## PHASE 1: Restructure — Main Menu & Mode Selection

---

### Step B1 — Main Menu Screen

/clear before running this prompt.

```
Create a main menu screen for PerfumeFusion.

Create scenes/ui/MainMenu.tscn with script scripts/ui/MainMenu.gd.

MainMenu.tscn — a full-screen Control node:
- Dark background matching the game's existing dark theme
- Centered VBoxContainer with spacing 30px:
  - Label: "PerfumeFusion" as the game title, font size 48, bold, centered
  - Label: A tagline underneath, font size 16, lighter color: "Discover. Fuse. Conquer." centered
  - Spacer (height 60px)
  - Button: "Free Play" — large, accent colored, min height 70px
  - Button: "Battle" — large, different accent color, min height 70px
  - Button: "Collection" — medium, min height 55px
  - Button: "Settings" — medium, min height 55px
  - Button: "About" — small, subtle, min height 45px

MainMenu.gd:
- On "Free Play" pressed: change scene to the existing GameScene.tscn
- On "Battle" pressed: change scene to a new BattleSelect scene (we'll create it in Step B3, for now just print "Battle mode coming soon")
- On "Collection" pressed: instance the existing Encyclopedia.tscn as an overlay
- On "Settings" pressed: instance the existing Settings.tscn as an overlay
- On "About" pressed: show a simple popup panel with:
  - "PerfumeFusion v1.0"
  - "A merge game about real fragrances"
  - "Data sourced from Fragrantica.com"
  - "Close" button

Set MainMenu.tscn as the main scene in project.godot instead of GameScene.tscn.

Modify GameScene.tscn: add a "Back to Menu" button in the top-left corner of the HUD that returns to MainMenu.tscn using get_tree().change_scene_to_file().

Remove the Collection and Settings buttons from the in-game HUD bottom bar since they now live in the main menu. Keep the spawn button and essence counter in the HUD.

Don't change anything else about the existing game logic.
```

**Verify:** Run the game. Main menu should appear first. "Free Play" enters the merge grid. "Back to Menu" returns to menu. Collection and Settings open as overlays from the menu.

```powershell
Remove-Item "$env:APPDATA\Godot\app_userdata\PerfumeFusion\save_data.json" -Force
```

```powershell
git add .
git commit -m "Add main menu with mode selection"
git push
```

---

### Step B2 — Opponent Data System

/clear before running this prompt.

```
Create the opponent/character data system for battle mode.

Create data/opponents.json with 20 opponents. Each opponent is a dictionary:

[
  {
    "id": 1,
    "name": "Gym Bro Gary",
    "title": "The Muscle",
    "description": "All brawn, no nose. Thinks cologne is a personality trait.",
    "hp": 100,
    "time_limit": 120,
    "weakness": ["floral", "sweet"],
    "resistance": ["woody", "musky"],
    "reward_essence": 200,
    "unlock_requirement": 0
  },
  {
    "id": 2,
    "name": "Sniffy Steve",
    "title": "The Street Sampler",
    "description": "Sprays testers on strangers without asking.",
    "hp": 150,
    "time_limit": 120,
    "weakness": ["citrus", "fresh"],
    "resistance": ["amber"],
    "reward_essence": 350,
    "unlock_requirement": 1
  },
  {
    "id": 3,
    "name": "Aunt Rosemary",
    "title": "The Powder Queen",
    "description": "Her perfume arrives 10 minutes before she does.",
    "hp": 200,
    "time_limit": 110,
    "weakness": ["woody", "spicy"],
    "resistance": ["floral", "powdery"],
    "reward_essence": 500,
    "unlock_requirement": 2
  },
  {
    "id": 4,
    "name": "Chad Cologne",
    "title": "The Oversprayer",
    "description": "12 sprays minimum. Elevator evacuations are his legacy.",
    "hp": 280,
    "time_limit": 110,
    "weakness": ["fresh", "aquatic"],
    "resistance": ["spicy", "amber"],
    "reward_essence": 700,
    "unlock_requirement": 3
  },
  {
    "id": 5,
    "name": "Vanilla Vicky",
    "title": "The Basic Sniffer",
    "description": "Only buys perfumes that smell like dessert.",
    "hp": 380,
    "time_limit": 100,
    "weakness": ["woody", "citrus"],
    "resistance": ["sweet", "vanilla"],
    "reward_essence": 1000,
    "unlock_requirement": 4
  },
  {
    "id": 6,
    "name": "Professor Patchouli",
    "title": "The Vintage Snob",
    "description": "Nothing made after 1985 deserves to be called perfume.",
    "hp": 500,
    "time_limit": 100,
    "weakness": ["fruity", "sweet"],
    "resistance": ["woody", "earthy"],
    "reward_essence": 1400,
    "unlock_requirement": 5
  },
  {
    "id": 7,
    "name": "Instagram Iris",
    "title": "The Aesthetic Collector",
    "description": "Buys perfumes based on bottle design, never opens them.",
    "hp": 650,
    "time_limit": 90,
    "weakness": ["musky", "amber"],
    "resistance": ["floral", "fresh"],
    "reward_essence": 1900,
    "unlock_requirement": 6
  },
  {
    "id": 8,
    "name": "Discount Dave",
    "title": "The Clone King",
    "description": "Why pay $300 when you can smell almost the same for $12?",
    "hp": 820,
    "time_limit": 90,
    "weakness": ["floral", "amber"],
    "resistance": ["citrus"],
    "reward_essence": 2500,
    "unlock_requirement": 7
  },
  {
    "id": 9,
    "name": "Niche Nancy",
    "title": "The Exclusive Nose",
    "description": "If you've heard of it, she's already over it.",
    "hp": 1000,
    "time_limit": 85,
    "weakness": ["citrus", "fresh"],
    "resistance": ["amber", "musky"],
    "reward_essence": 3200,
    "unlock_requirement": 8
  },
  {
    "id": 10,
    "name": "Mall Mike",
    "title": "The Department Store Boss",
    "description": "Has been wearing the same cologne since 2003. It works.",
    "hp": 1250,
    "time_limit": 85,
    "weakness": ["spicy", "woody"],
    "resistance": ["sweet", "fruity"],
    "reward_essence": 4000,
    "unlock_requirement": 9
  },
  {
    "id": 11,
    "name": "Layering Lisa",
    "title": "The Cocktail Mixer",
    "description": "Wears 4 perfumes at once and calls it 'bespoke.'",
    "hp": 1550,
    "time_limit": 80,
    "weakness": ["amber", "vanilla"],
    "resistance": ["floral", "citrus"],
    "reward_essence": 5000,
    "unlock_requirement": 10
  },
  {
    "id": 12,
    "name": "YouTube Yusuf",
    "title": "The Reviewer",
    "description": "Has 47 backup bottles of discontinued fragrances.",
    "hp": 1900,
    "time_limit": 80,
    "weakness": ["fresh", "floral"],
    "resistance": ["woody", "spicy"],
    "reward_essence": 6200,
    "unlock_requirement": 11
  },
  {
    "id": 13,
    "name": "Decant Debbie",
    "title": "The Sample Hoarder",
    "description": "Owns 500 samples. Has finished exactly zero of them.",
    "hp": 2300,
    "time_limit": 75,
    "weakness": ["woody", "musky"],
    "resistance": ["sweet", "fruity"],
    "reward_essence": 7500,
    "unlock_requirement": 12
  },
  {
    "id": 14,
    "name": "Batch Code Brad",
    "title": "The Obsessive",
    "description": "Rejects bottles if the batch code doesn't match the golden era.",
    "hp": 2800,
    "time_limit": 75,
    "weakness": ["sweet", "fruity"],
    "resistance": ["amber", "musky"],
    "reward_essence": 9000,
    "unlock_requirement": 13
  },
  {
    "id": 15,
    "name": "Projection Pete",
    "title": "The Beast Mode Chaser",
    "description": "Measures sillage in city blocks. Subtlety is weakness.",
    "hp": 3400,
    "time_limit": 70,
    "weakness": ["floral", "citrus"],
    "resistance": ["spicy", "woody"],
    "reward_essence": 11000,
    "unlock_requirement": 14
  },
  {
    "id": 16,
    "name": "Oud Overlord Omar",
    "title": "The Middle Eastern King",
    "description": "If it doesn't have oud, is it even a fragrance?",
    "hp": 4100,
    "time_limit": 70,
    "weakness": ["citrus", "aquatic"],
    "resistance": ["woody", "amber"],
    "reward_essence": 13500,
    "unlock_requirement": 15
  },
  {
    "id": 17,
    "name": "Blind Buy Betty",
    "title": "The Risk Taker",
    "description": "Drops $400 on perfumes she's never smelled. No regrets. Some regrets.",
    "hp": 5000,
    "time_limit": 65,
    "weakness": ["musky", "spicy"],
    "resistance": ["floral", "sweet"],
    "reward_essence": 16500,
    "unlock_requirement": 16
  },
  {
    "id": 18,
    "name": "Parfum Patriarch Pierre",
    "title": "The French Master",
    "description": "Trained his nose in Grasse. Looks down on everything else.",
    "hp": 6000,
    "time_limit": 65,
    "weakness": ["fruity", "sweet"],
    "resistance": ["floral", "amber"],
    "reward_essence": 20000,
    "unlock_requirement": 17
  },
  {
    "id": 19,
    "name": "Collection Complete Carla",
    "title": "The Vault Keeper",
    "description": "Has a climate-controlled room just for her collection. It has insurance.",
    "hp": 7500,
    "time_limit": 60,
    "weakness": ["spicy", "amber"],
    "resistance": ["citrus", "fresh"],
    "reward_essence": 25000,
    "unlock_requirement": 18
  },
  {
    "id": 20,
    "name": "The Grandmaster",
    "title": "The Living Legend",
    "description": "Nobody knows their real name. They smell like the concept of perfection.",
    "hp": 10000,
    "time_limit": 55,
    "weakness": [],
    "resistance": [],
    "reward_essence": 50000,
    "unlock_requirement": 19
  }
]

Now create scripts/data/OpponentManager.gd as an Autoload singleton (register in project.godot):

- On _ready(), load data/opponents.json and parse it into an Array
- Store in a variable: opponents
- Functions:
  - get_opponent(id: int) -> Dictionary — returns opponent data by id
  - get_all_opponents() -> Array — returns all 20
  - get_unlocked_opponents() -> Array — returns opponents where unlock_requirement <= number of opponents the player has already beaten (stored in SaveManager)
  - is_opponent_beaten(id: int) -> bool — checks SaveManager's beaten_opponents list
- Add to SaveManager's default data: beaten_opponents: [] (Array of opponent IDs the player has defeated)

Print "OpponentManager loaded. X opponents." on startup.

Don't change anything else.
```

**Verify:** Run the game, check Output for "OpponentManager loaded. 20 opponents."

```powershell
git add .
git commit -m "Add opponent data system with 20 characters"
git push
```

---

### Step B3 — Battle Select Screen

/clear before running this prompt.

```
Create the battle select screen where players choose an opponent.

Create scenes/ui/BattleSelect.tscn with script scripts/ui/BattleSelect.gd.

BattleSelect.tscn — a full-screen Control:
- Dark background matching the game theme
- VBoxContainer with margins:
  - Top bar (HBoxContainer):
    - Button: "← Back" — returns to MainMenu
    - Label: "Choose Your Opponent" centered, font size 28
    - Essence counter on the right (show current essence)
  - ScrollContainer (fills remaining space):
    - VBoxContainer with spacing 15px — holds opponent cards

Each opponent card is a PanelContainer with:
  - HBoxContainer:
    - Left section (width ~80px): a large Label showing the opponent number "#1", "#2" etc. with a colored circle background. If beaten, show a green checkmark instead.
    - Middle section (VBoxContainer, expanding):
      - Label: opponent name, font size 20, bold (e.g. "Gym Bro Gary")
      - Label: opponent title, font size 14, lighter color (e.g. "The Muscle")
      - HBoxContainer for weakness icons: small colored labels for each weakness accord (e.g. green "floral" tag, pink "sweet" tag)
      - HBoxContainer for resistance icons: small red-tinted labels for each resistance accord
    - Right section (VBoxContainer, width ~120px):
      - Label: HP value (e.g. "HP: 100")
      - Label: Time limit (e.g. "2:00")
      - Label: Reward (e.g. "200 Essence")

  - If the opponent is locked (unlock_requirement not met): grey out the entire card, show a lock icon, and text "Defeat opponent #X to unlock"
  - If the opponent is unlocked: full color, tappable
  - If the opponent is beaten: show a subtle green border or checkmark

BattleSelect.gd:
- On _ready(): get unlocked opponents from OpponentManager, build the card list
- On opponent card pressed (if unlocked): store the selected opponent ID, change scene to BattleScene.tscn (we'll create it next step, for now just print "Starting battle against: " + opponent.name)
- Back button: return to MainMenu via get_tree().change_scene_to_file()

Wire up MainMenu's "Battle" button to change scene to BattleSelect.tscn instead of printing.

Don't change anything else.
```

**Verify:** Run the game, go to Main Menu, tap Battle, see the opponent list. First opponent should be unlocked, rest locked. Back button returns to menu.

```powershell
git add .
git commit -m "Add battle select screen with opponent cards"
git push
```

---

## PHASE 2: Battle Gameplay

---

### Step B4 — Battle Scene Layout

/clear before running this prompt.

```
Create the battle scene — this is a modified version of the existing GameScene but with battle HUD elements.

Create scenes/main/BattleScene.tscn with script scripts/main/BattleScene.gd.

BattleScene should contain:
- The same 5x5 grid from GameScene (reuse the Grid.tscn and GridSlot.tscn scenes)
- The same spawn button with cooldown
- The same sell zone
- The essence counter

But REPLACE the top section of the HUD with a Battle HUD:

Battle HUD (at the top of the screen, above the grid):
  - Opponent section (HBoxContainer):
    - Left side — Player info:
      - Label: "YOU" font size 14
      - A small colored bar or icon representing the player
    - Center — VS indicator:
      - Label: "VS" font size 20, bold
    - Right side — Opponent info:
      - Label: opponent name, font size 16, bold
      - Label: opponent title, font size 12, lighter
  - Health bar section:
    - A horizontal ProgressBar (or TextureProgressBar) showing opponent HP
    - Label overlay on the bar: "850 / 1000 HP"
    - The bar should be red/orange colored
    - Bar decreases when player deals damage
  - Timer section:
    - Label showing countdown: "1:45" in large font size 32
    - Color changes: white when > 30s, yellow when 10-30s, red and pulsing when < 10s
  - Weakness/Resistance info:
    - Small HBoxContainer below the health bar
    - Green labels for weaknesses: "Weak: floral, sweet"
    - Red labels for resistances: "Resists: woody, musky"

BattleScene.gd:
- Variable: current_opponent (Dictionary — loaded from OpponentManager)
- Variable: opponent_hp (float — starts at opponent's max HP)
- Variable: time_remaining (float — starts at opponent's time_limit)
- Variable: battle_active (bool — true while battle is running)

- On _ready():
  - Load the selected opponent (pass the opponent ID via a global variable or Autoload, e.g. store it in OpponentManager.selected_opponent_id)
  - Set up the grid (same as GameScene)
  - Initialize opponent_hp and time_remaining
  - Start the countdown timer
  - Spawn 3 free Tier 1 perfumes to start the battle

- In _process(delta):
  - If battle_active: decrement time_remaining by delta
  - Update the timer display
  - If time_remaining <= 0: call _battle_lost()
  - If opponent_hp <= 0: call _battle_won()

- Functions _battle_won() and _battle_lost() are empty for now — we'll implement them in Step B6.

- The grid, drag-drop, merge, spawn, and sell all work exactly the same as in Free Play mode. The only difference is that merges also deal damage (we'll add that in Step B5).

Don't change anything else in the existing GameScene or its scripts.
```

**Verify:** Run the game, go to Battle, select opponent 1. Battle scene should load with the grid, health bar, timer counting down, and opponent info at the top.

```powershell
git add .
git commit -m "Add battle scene with health bar, timer, and opponent info"
git push
```

---

### Step B5 — Damage System

/clear before running this prompt.

```
Implement the damage system for battle mode. Every merge deals damage to the opponent.

Create scripts/managers/BattleManager.gd as an Autoload singleton (register in project.godot):

- Variables:
  - is_battle_active: bool = false
  - current_opponent: Dictionary = {}
  - opponent_hp: float = 0.0
  - opponent_max_hp: float = 0.0

- signal damage_dealt(amount: float, is_super_effective: bool)
- signal opponent_defeated
- signal battle_timeout

- Function: start_battle(opponent: Dictionary):
  - Set current_opponent, opponent_hp, opponent_max_hp from opponent data
  - is_battle_active = true

- Function: end_battle():
  - is_battle_active = false

- Function: calculate_damage(tier: int, perfume_data: Dictionary) -> Dictionary:
  This is the core damage formula. Returns {damage: float, is_super_effective: bool, is_resisted: bool}

  Base damage calculation:
  - Tier 1-5: damage = tier * 3
  - Tier 6-10: damage = 15 + (tier - 5) * 5
  - Tier 11-15: damage = 40 + (tier - 10) * 10
  - Tier 16-20: damage = 90 + (tier - 15) * 25

  Accord multiplier:
  - Get the perfume's accords list from perfume_data
  - Check each accord against current_opponent.weakness and current_opponent.resistance
  - If ANY accord matches a weakness: damage *= 2.0 and is_super_effective = true
  - If ANY accord matches a resistance: damage *= 0.5 and is_resisted = true
  - If both match (unlikely but possible): they cancel out, damage stays normal
  - The final boss (id 20) has no weaknesses or resistances — damage is always base

  Return the dictionary with final damage, is_super_effective, and is_resisted.

- Function: deal_damage(tier: int, perfume_data: Dictionary) -> void:
  - If not is_battle_active: return
  - Calculate damage using calculate_damage()
  - Subtract from opponent_hp
  - Clamp opponent_hp to minimum 0
  - Emit damage_dealt signal
  - Print "Dealt X damage! (super effective)" or "Dealt X damage (resisted)" or "Dealt X damage"
  - If opponent_hp <= 0: emit opponent_defeated

Now wire it into MergeManager.gd:
- At the end of execute_merge(), after the merge is complete, check if BattleManager.is_battle_active
- If yes: call BattleManager.deal_damage(new_tier, new_perfume_data)
- This way merges in Free Play mode don't trigger damage, only battle mode

Now wire it into BattleScene.gd:
- Connect to BattleManager.damage_dealt signal: update the HP bar and show damage number
- Connect to BattleManager.opponent_defeated signal: call _battle_won()

Damage number display:
- When damage is dealt, show a floating number at the top of the screen near the health bar
- The number should float upward and fade out over 0.8 seconds
- Color: white for normal, green for super effective, grey for resisted
- If super effective, also briefly show "SUPER EFFECTIVE!" text
- If resisted, show "RESISTED..." text

Don't change anything else.
```

**Verify:** Run a battle. Merge two perfumes. Check Output panel for damage prints. Health bar should decrease. Try to identify if weaknesses and resistances trigger correctly based on the first opponent's data.

```powershell
git add .
git commit -m "Implement battle damage system with accord weaknesses and resistances"
git push
```

---

### Step B6 — Victory & Defeat Screens

/clear before running this prompt.

```
Implement victory and defeat screens for battle mode.

Create scenes/ui/BattleResult.tscn with script scripts/ui/BattleResult.gd.

BattleResult.tscn — a CanvasLayer overlay:
- Dark semi-transparent background (Color(0, 0, 0, 0.7))
- Centered PanelContainer (width ~800px):
  - VBoxContainer with padding 40px and spacing 20px:
    - Label for result: "VICTORY!" or "DEFEAT" — font size 40, bold, centered
      - Victory: gold color
      - Defeat: red color
    - Label for opponent: "You defeated Gym Bro Gary!" or "Gym Bro Gary wins..." — font size 18, centered
    - HSeparator
    - Stats section (VBoxContainer):
      - Label: "Time: X:XX" (time taken for victory, or "Time's up!" for defeat)
      - Label: "Merges: X" (total merges during the battle)
      - Label: "Highest Tier: X" (highest tier reached during battle)
      - Label: "Damage Dealt: X / Y HP" (total damage / opponent max HP)
    - HSeparator
    - Rewards section (only shown on victory):
      - Label: "Rewards:" font size 20, bold
      - Label: "+X Essence" with essence icon
      - If this is the first time beating this opponent: Label: "NEW! Next opponent unlocked!"
    - Spacer
    - Buttons (HBoxContainer, centered):
      - Victory: "Continue" (returns to BattleSelect) and "Replay" (restart same battle)
      - Defeat: "Try Again" (restart same battle) and "Back" (returns to BattleSelect)

BattleResult.gd:
- Function: show_victory(opponent: Dictionary, stats: Dictionary):
  - Display victory text and stats
  - Award essence via EconomyManager.add_essence(opponent.reward_essence)
  - If opponent not in SaveManager.data.beaten_opponents: add it and save
  - Wire up buttons

- Function: show_defeat(opponent: Dictionary, stats: Dictionary):
  - Display defeat text and stats
  - No rewards
  - Wire up buttons

- "Continue" / "Back" button: get_tree().change_scene_to_file("res://scenes/ui/BattleSelect.tscn")
- "Replay" / "Try Again" button: get_tree().change_scene_to_file("res://scenes/main/BattleScene.tscn") (opponent ID stays in OpponentManager.selected_opponent_id)

Now wire into BattleScene.gd:
- _battle_won():
  - BattleManager.end_battle()
  - Calculate stats dictionary: {time_taken, total_merges, highest_tier, damage_dealt, max_hp}
  - Instance BattleResult, add to scene tree, call show_victory()

- _battle_lost():
  - BattleManager.end_battle()
  - Calculate stats dictionary
  - Instance BattleResult, add to scene tree, call show_defeat()

- Track battle stats during the battle:
  - total_merges: increment on each merge
  - highest_tier: update when a merge produces a higher tier than current
  - damage_dealt: sum of all damage
  - time_taken: opponent.time_limit - time_remaining at moment of victory

Don't change anything else.
```

**Verify:** Run a battle against opponent 1 (HP: 100, should be beatable). Win and check victory screen shows stats and rewards. Lose (let timer run out) and check defeat screen. Return to BattleSelect and verify opponent 2 is now unlocked after winning.

```powershell
git add .
git commit -m "Add victory and defeat screens with stats and rewards"
git push
```

---

### Step B7 — Battle Economy Separation

/clear before running this prompt.

```
The battle mode and free play mode need separate economies for the grid.

Right now if the player has items on the grid in Free Play and starts a battle, those items carry over, which is wrong. Each battle should start with a fresh grid.

Fix:

1. In BattleScene.gd _ready():
   - Do NOT load grid state from SaveManager
   - Start with a completely empty grid
   - Give the player 3 free Tier 1 spawns to start (separate from the Free Play free_spawns counter)
   - Set a battle-specific essence pool: the player keeps their global essence but spawning in battle uses a separate free spawn counter

2. When a battle ends (win or lose):
   - Do NOT save the battle grid state to SaveManager
   - The grid is discarded
   - Only save: beaten_opponents list, essence earned from victory reward

3. In Free Play (GameScene):
   - Continue to save/load grid state normally
   - This mode is unchanged

4. In the spawn button logic, check if we're in battle mode or free play:
   - Battle mode: spawns are free (unlimited, only gated by cooldown timer). This makes battles about speed and strategy, not about having enough essence.
   - Free Play: spawns cost essence as currently implemented.

5. Merges in battle mode should NOT award essence (they deal damage instead). Remove or skip the EconomyManager.add_essence() call in MergeManager when BattleManager.is_battle_active is true.

Don't change anything else.
```

**Verify:** Start Free Play, place some items, go back to menu. Start a battle — grid should be empty with 3 free items. Finish battle, go to Free Play — original items should still be there.

```powershell
git add .
git commit -m "Separate battle and free play grid states"
git push
```

---

## PHASE 3: Battle Polish

---

### Step B8 — Battle Combo System

/clear before running this prompt.

```
Add a combo system to make battles more exciting. Consecutive merges within a short time window deal increasing damage.

Add to BattleManager.gd:
- Variable: combo_count: int = 0
- Variable: combo_timer: float = 0.0
- Constant: COMBO_WINDOW: float = 3.0 (seconds between merges to maintain combo)

- In _process(delta):
  - If is_battle_active and combo_count > 0:
    - Decrement combo_timer by delta
    - If combo_timer <= 0: reset combo_count to 0 (combo dropped)

- Modify deal_damage():
  - Increment combo_count
  - Reset combo_timer to COMBO_WINDOW
  - Apply combo multiplier to damage:
    - Combo 1 (first merge): 1.0x
    - Combo 2: 1.2x
    - Combo 3: 1.5x
    - Combo 4: 1.8x
    - Combo 5+: 2.0x
  - Emit a new signal: combo_updated(combo_count: int, time_remaining: float)
  - Print "Combo x3! Damage: X (x1.5 multiplier)"

- In BattleScene.gd:
  - Connect to combo_updated signal
  - Show combo counter on screen: large "x3 COMBO!" text near the center
  - The text should pulse/scale briefly on each combo increment
  - Show a small timer bar under the combo text that drains over the COMBO_WINDOW duration
  - When combo resets to 0, the text fades out

Don't change anything else.
```

**Verify:** Run a battle. Merge quickly in succession. Combo counter should appear and increase. Wait 3 seconds without merging — combo should reset.

```powershell
git add .
git commit -m "Add combo system for consecutive merges in battle"
git push
```

---

### Step B9 — Opponent Intro Screen

/clear before running this prompt.

```
Add a brief opponent introduction screen before each battle starts.

Create scenes/ui/OpponentIntro.tscn with script scripts/ui/OpponentIntro.gd.

OpponentIntro.tscn — full screen overlay:
- Dark background
- Centered VBoxContainer with spacing 25px:
  - Label: "CHALLENGER APPROACHING" font size 16, uppercase, letter-spaced, lighter color, centered
  - Spacer (20px)
  - A large placeholder square (200x200) for the opponent portrait (we'll add art later — for now use a ColorRect with the text of their initials in large font)
  - Label: opponent name, font size 32, bold, centered
  - Label: opponent title in quotes, font size 18, italic, centered (e.g. '"The Muscle"')
  - Label: opponent description, font size 14, centered, max width 600px, word wrap
  - HSeparator
  - HBoxContainer centered:
    - VBoxContainer: Label "HP" small + Label with HP value, bold
    - Spacer (40px)
    - VBoxContainer: Label "TIME" small + Label with formatted time like "2:00", bold
  - HBoxContainer centered with spacing 10px:
    - For each weakness: a green tag label with the accord name
    - Label: "← weak" in small green text
  - HBoxContainer centered with spacing 10px:
    - For each resistance: a red tag label with the accord name
    - Label: "← resists" in small red text
  - Spacer (30px)
  - Button: "FIGHT!" — large, accent color, bold, min height 60px

OpponentIntro.gd:
- Function: setup(opponent: Dictionary):
  - Populate all labels with opponent data
  - Format time_limit into "M:SS" format
- On "FIGHT!" button pressed:
  - Animate the screen out (fade or slide up, 0.3s)
  - Then queue_free() and emit a signal or call a function on BattleScene to actually start the timer and gameplay

Modify BattleScene.gd:
- On _ready(): instead of starting immediately, instance OpponentIntro, show it, and wait for it to finish before starting the battle timer
- The grid should be visible behind the intro (the intro has a semi-transparent dark background)
- Battle timer does NOT start until the player presses "FIGHT!"

Don't change anything else.
```

**Verify:** Start a battle. Intro screen should appear with opponent info. Timer should not be counting. Press FIGHT — intro disappears and battle begins.

```powershell
git add .
git commit -m "Add opponent intro screen before battle"
git push
```

---

### Step B10 — Screen Shake & Battle Juice

/clear before running this prompt.

```
Add visual feedback to make battles feel impactful.

1. Screen shake on merge during battle:
   - Create scripts/effects/ScreenShake.gd
   - Attach it to the main Camera2D or the root Control of BattleScene
   - Function: shake(intensity: float, duration: float):
     - Randomly offset the node's position by up to intensity pixels
     - Reduce intensity over duration, return to original position
   - Call shake on every merge during battle:
     - Normal damage: shake(3.0, 0.15)
     - Super effective: shake(8.0, 0.25)
     - Combo 5+: shake(12.0, 0.3)

2. Health bar flash:
   - When damage is dealt, briefly flash the HP bar white (0.1s) then return to normal color
   - When opponent HP drops below 25%, the bar turns from red to a pulsing dark red

3. Timer urgency effects:
   - When timer < 30 seconds: background color subtly shifts to a darker red tint
   - When timer < 10 seconds: the timer label pulses (scale 1.0 to 1.15 and back, every 0.5s)
   - Optional: a subtle heartbeat-like vignette effect at the screen edges

4. Super effective flash:
   - When a super effective merge happens, briefly flash the entire screen with a green-tinted overlay (0.15s, then fade out 0.2s)

Keep all effects subtle — they should enhance the feel without being distracting or causing motion sickness.

Don't change anything else.
```

**Verify:** Run a battle. Merge items and check for screen shake. Get a super effective hit and check for green flash. Let timer run low and check for urgency effects.

```powershell
git add .
git commit -m "Add screen shake, HP bar flash, and timer urgency effects"
git push
```

---

## PHASE 4: Integration & Cleanup

---

### Step B11 — Remove Export Function & Clean DataManager

/clear before running this prompt.

```
Clean up DataManager.gd:

1. Remove the export_filtered_data() function entirely
2. Remove the call to export_filtered_data() from _ready()
3. Make sure PERFUMES_PATH points to "res://data/perfumes_filtered.json"
4. Delete data/perfumes.json and data/perfumes_slim.json from the project if they exist (keep only perfumes_filtered.json and opponents.json in the data folder)
5. Also delete data/archive.zip, data/archive/ folder, and data/failed_urls.txt if they exist
6. Update .gitignore: remove any data/*.json ignore rules since we now WANT perfumes_filtered.json and opponents.json tracked in git

Don't change anything else.
```

**Verify:**
```powershell
ls data\
```
Should only show perfumes_filtered.json and opponents.json.

```powershell
git add .
git commit -m "Clean up data folder — keep only filtered perfumes and opponents"
git push
```

---

### Step B12 — Save System Update for Battles

/clear before running this prompt.

```
Make sure the save system properly tracks all battle-related progress.

Update SaveManager.gd:

1. Add these fields to get_default_data() if not already present:
   - beaten_opponents: [] (Array of opponent IDs)
   - battle_stats: {
       total_battles: 0,
       total_victories: 0,
       total_defeats: 0,
       fastest_victory: {} (Dictionary mapping opponent_id to best time),
       highest_combo: 0
     }

2. Add helper functions:
   - mark_opponent_beaten(id: int) — adds to beaten_opponents if not already there, saves
   - is_opponent_beaten(id: int) -> bool
   - get_beaten_count() -> int
   - update_battle_stats(opponent_id: int, won: bool, time_taken: float, max_combo: int):
     - Increment total_battles
     - Increment total_victories or total_defeats
     - Update fastest_victory for this opponent if time_taken is lower than existing
     - Update highest_combo if max_combo is higher
     - Save

3. Wire these into BattleResult.gd:
   - On victory: call mark_opponent_beaten() and update_battle_stats()
   - On defeat: call update_battle_stats() with won=false

4. In BattleSelect.gd: show a small "Best: X:XX" time under each beaten opponent's card if a fastest_victory exists for them.

Don't change anything else.
```

**Verify:** Beat opponent 1, go to battle select, confirm it shows beaten with best time. Beat it again faster, confirm time updates.

```powershell
git add .
git commit -m "Track battle stats — victories, best times, highest combo"
git push
```

---

## What Comes After This File

After completing Steps B1 through B12, the remaining work is:

1. **Tutorial update** — redo the tutorial to introduce both modes
2. **Art** — opponent portraits and perfume bottles (Nano Banana automation)
3. **Sound & Music** — Gemini music generation
4. **UI/UX polish pass** — colors, fonts, spacing, animations
5. **HTML5 export & Poki submission**
6. **Android port**

These will be separate prompt files since they depend on external tools (image generation, music generation) and design decisions that need discussion first.
