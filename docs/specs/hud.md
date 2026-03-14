# Feature Spec: HUD & Game UI

## Overview
The in-game HUD displays player stats and status. Overlays appear for tasks, clashes, and win/loss.

## HUD Layout

### Player Info (top-left)
- **Avatar portrait** (from character creator)
- **Item indicator** (top-right corner of portrait):
  - Hidden until item collected
  - Shows item icon when collected
- **Stats below portrait:**
  - Size: number display (e.g., "Size: 3")
  - Speed: "Full" or "Half" with color coding (green/red)
  - Energy: percentage bar (green → yellow → red as it depletes)

### Minimap
- None (by design — player must explore blind)

## Overlays (layered above game)

### Task Overlay
- See [task-display.md](task-display.md)
- Modal, pauses game

### Clash Overlay
- See [clash-mechanic.md](clash-mechanic.md) and [clash-task.md](clash-task.md)
- Modal, freezes involved characters

### Pause Menu
- Triggered by Escape / pause input
- Semi-transparent overlay
- Buttons: Resume, Save Game, Quit to Menu
- Save Game → writes to next available slot (or overwrite prompt)

### Win/Loss Screen
- See [exit-win.md](exit-win.md)
- Full-screen overlay with results

## Responsiveness
- HUD elements anchored (don't move with camera)
- Scale appropriately with resolution
- Overlays centered on screen regardless of camera position

## Testing Criteria
- [ ] Portrait and stats display correctly
- [ ] Energy bar updates in real-time
- [ ] Speed indicator changes with energy state
- [ ] Item indicator hidden until collected
- [ ] Pause menu opens/closes correctly
- [ ] Save from pause menu works
- [ ] All overlays display above game content
- [ ] HUD readable at all supported resolutions
