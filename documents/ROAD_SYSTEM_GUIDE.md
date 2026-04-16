# PerfumeFusion — Road & Path System Implementation Guide

---

## Overview

Add a U-shaped road/path to both Free Play and Battle mode. In Battle mode, the player's character walks from the bottom-right, goes left, then up, then right along a U-path to reach the opponent at the top-right. The merge grid sits in the center of the right side. Each merge moves the character forward. Reaching the opponent starts dealing damage.

---

## PHASE 1: Road Layout & Character

---

### Step R1 — Road Background Scene

/clear before running this prompt.

```
Create a road/path visual for the game background that shows in both Free Play and Battle mode.

Create scenes/effects/RoadPath.tscn with script scripts/effects/RoadPath.gd.

The road is a U-shaped path drawn on screen. Think of the screen in portrait mode (1080x1920):

- The path starts at the BOTTOM-RIGHT corner
- Goes LEFT along the bottom
- Turns UP along the left side
- Turns RIGHT along the top
- Ends at the TOP-RIGHT corner (where the opponent stands in battle mode)

The grid (5x5) sits in the CENTER-RIGHT area of the screen, next to the vertical part of the path.

Draw the road using Line2D node:
- Line2D with these points (approximate, adjust to look good):
  - Point 1: Vector2(900, 1700) — bottom right start
  - Point 2: Vector2(180, 1700) — bottom left corner
  - Point 3: Vector2(180, 300) — top left corner
  - Point 4: Vector2(900, 300) — top right end (opponent position)
- Width: 60px
- Color: a subtle dark grey (Color(0.25, 0.22, 0.3)) so it doesn't distract from the grid
- Use rounded joints and caps
- Add a subtle dashed or dotted center line for a road feel (use a second thinner Line2D on top with a different color and dashes)

RoadPath.gd:
- Variable: path_points — the array of Vector2 points defining the road
- Function: get_position_at_progress(progress: float) -> Vector2:
  - progress is 0.0 (start) to 1.0 (end)
  - Interpolates along the path segments to return the world position at that progress
  - For example, progress 0.0 = bottom right, 0.5 = somewhere on the left side going up, 1.0 = top right
- Function: get_total_length() -> float:
  - Returns the total pixel length of the path

Add this as a child of both GameScene.tscn and BattleScene.tscn, rendered BEHIND the grid (lower z-index).

Don't change anything else.
```

**Verify:** Run the game. You should see a U-shaped road behind the grid in both modes.

```powershell
git add .
git commit -m "Add U-shaped road path background"
git push
```

---

### Step R2 — Player Character on the Road

/clear before running this prompt.

```
Create a player character that walks along the road path.

Create scenes/effects/PlayerCharacter.tscn with script scripts/effects/PlayerCharacter.gd.

PlayerCharacter.tscn:
- Root: Node2D
- Child: a simple placeholder visual — a ColorRect (40x40, bright green) or a Polygon2D shaped like a simple character silhouette
- Child: Label underneath showing "You" in small font, centered

PlayerCharacter.gd:
- Variable: current_progress: float = 0.0 (0.0 = start of road, 1.0 = end)
- Variable: target_progress: float = 0.0
- Variable: road_path: Node = null (reference to RoadPath)
- Variable: move_speed: float = 0.3 (how fast progress increases per second during animation)

- Function: setup(path: Node):
  - Store road_path reference
  - Set position to road_path.get_position_at_progress(0.0)

- Function: advance(amount: float):
  - target_progress = clamp(current_progress + amount, 0.0, 1.0)
  - The character will smoothly move to this position in _process

- In _process(delta):
  - If current_progress < target_progress:
    - current_progress = move_toward(current_progress, target_progress, move_speed * delta)
    - position = road_path.get_position_at_progress(current_progress)
  - Flip the character sprite/rect based on movement direction:
    - Moving left: no flip
    - Moving up: no flip
    - Moving right: flip horizontal

Add PlayerCharacter as a child of both GameScene and BattleScene.

In Battle mode:
- The character starts at progress 0.0
- Each merge advances the character by a calculated amount:
  - advance_amount = 1.0 / (opponent_hp / base_damage_per_merge)
  - Simplified: each merge moves the character roughly proportional to the damage dealt vs total HP
  - When progress reaches 1.0, the character has reached the opponent

In Free Play mode:
- The character just stands at the start position (progress 0.0) as decoration
- Or slowly walks back and forth as an idle animation

Don't change anything else.
```

**Verify:** Run a battle. The character should start at the bottom-right and move along the path as you merge perfumes.

```powershell
git add .
git commit -m "Add player character walking along road path"
git push
```

---

### Step R3 — Opponent Character on the Road

/clear before running this prompt.

```
Add an opponent character at the end of the road in Battle mode.

Create scenes/effects/OpponentCharacter.tscn with script scripts/effects/OpponentCharacter.gd.

OpponentCharacter.tscn:
- Root: Node2D
- Child: ColorRect (50x50) as placeholder — color red
- Child: Label showing opponent initials in bold (e.g. "GBG" for Gym Bro Gary), centered on the rect
- Child: Label below showing opponent name in small font

OpponentCharacter.gd:
- Variable: opponent_data: Dictionary
- Function: setup(data: Dictionary, road_path: Node):
  - Set opponent_data
  - Position at road_path.get_position_at_progress(1.0) — the end of the path
  - Set initials label from first letters of opponent name
  - Set name label

- Function: take_hit():
  - Brief visual feedback: flash white for 0.1s, shake slightly
  - Scale down briefly (0.9) then bounce back to 1.0

- Function: defeated():
  - Play a defeat animation: spin and shrink to 0 over 0.5s

Add OpponentCharacter to BattleScene only (not Free Play).

Wire into BattleManager:
- When damage_dealt signal fires: call opponent_character.take_hit()
- When opponent_defeated signal fires: call opponent_character.defeated()

Only show OpponentCharacter in battle mode, not in free play.

Don't change anything else.
```

**Verify:** Run a battle. Opponent should stand at the end of the road. When you merge, they flash. When defeated, they spin and shrink.

```powershell
git add .
git commit -m "Add opponent character at end of road path"
git push
```

---

### Step R4 — Progress Markers on the Road

/clear before running this prompt.

```
Add visual progress markers along the road so players can see how far they need to go.

Modify RoadPath.gd:

1. Add milestone markers along the path at every 25% progress (0.25, 0.50, 0.75):
   - Small circle or diamond shape drawn at that position
   - A subtle label like "25%" next to it
   - These are just visual indicators, not interactive

2. Add a progress trail effect:
   - Create a second Line2D that traces the path the player has already walked
   - This line should be brighter (e.g. a glowing light blue or gold Color(0.3, 0.8, 1.0, 0.6))
   - Width slightly smaller than the road (50px)
   - Update it in _process: draw the line from point 0 up to the player's current_progress position
   - This creates a "filling" effect along the road as the player progresses

3. Function: update_trail(progress: float):
   - Calculate which segments of the path have been covered
   - Update the trail Line2D points to only include the covered portion

Wire into BattleScene:
- When the player character moves (in PlayerCharacter._process), call road_path.update_trail(current_progress)

Only show progress markers and trail in battle mode. In free play, just show the plain road.

Don't change anything else.
```

**Verify:** Run a battle. As you merge and the character walks, a glowing trail should fill the road behind them. 25/50/75% markers should be visible.

```powershell
git add .
git commit -m "Add progress trail and milestone markers on road"
git push
```

---

## PHASE 2: Grid Repositioning

---

### Step R5 — Move Grid to Center-Right

/clear before running this prompt.

```
Reposition the grid so it sits properly alongside the road.

Currently the grid is centered on screen. Move it so the road layout makes visual sense:

In both GameScene.tscn and BattleScene.tscn:

1. The grid (5x5) should be positioned on the RIGHT side of the screen, vertically centered
   - The road's vertical segment (left side going up) is visible to the LEFT of the grid
   - The road's horizontal segments (top and bottom) are visible ABOVE and BELOW the grid

2. Adjust the parent container of the grid:
   - Remove full-width centering
   - Set the grid container to anchor to the right side with a margin from the right edge (~40px)
   - Vertically center it

3. The HUD elements (essence counter, spawn button, etc.) should remain in their current positions at the top and bottom of the screen — don't move them

4. Make sure the grid slots are small enough that the grid fits on the right half of the screen:
   - Each slot should be roughly 120x120 pixels if needed
   - The total grid should not exceed about 650px width

5. The road path points from Step R1 may need adjustment now that the grid has moved. Update the road points so the vertical segment of the U-path runs along the LEFT side of the grid (not behind it), and the horizontal segments run below and above the grid.

Test at viewport size 540x960 to make sure everything fits.

Don't change anything else.
```

**Verify:** Run the game. Grid should be on the right side. Road should be visible as a U-shape to the left and around the grid.

```powershell
git add .
git commit -m "Reposition grid to right side with road visible alongside"
git push
```

---

### Step R6 — Free Play Decoration

/clear before running this prompt.

```
In Free Play mode, the road exists but has no battle purpose. Add some passive decoration to make it feel alive.

In GameScene.gd:

1. The player character should idle-walk back and forth along the first 10% of the road (bottom section) with a slow speed. Just a gentle back-and-forth loop.

2. Add 2-3 small decorative elements along the road:
   - Small static "perfume shop" icons (just colored squares with tiny labels like "Shop" and "Lab") placed at fixed positions along the path
   - These are purely visual, not interactive
   - Position them at progress 0.3, 0.5, and 0.8 on the path

3. When a merge happens in free play, the player character does a small jump animation (scale up to 1.2, back to 1.0 over 0.3s) at its current idle position. This gives a subtle "celebration" feel without moving along the path.

The road in free play is decorative. It hints that there's more to the game (battle mode) without doing anything functional.

Don't change anything else.
```

**Verify:** Run Free Play. Character should idle-walk at the bottom of the road. Small decorations visible along the path. Merging causes a small bounce.

```powershell
git add .
git commit -m "Add decorative road elements and idle character in free play"
git push
```

---

## What Comes After This File

After completing Steps R1 through R6:
1. The road and character art will need replacing with real art (Nano Banana)
2. The opponent characters need portraits
3. The road decorations can become more detailed
4. Consider adding particle effects along the trail (sparkles, dust from walking)

These visual upgrades go in the art/polish phase.
