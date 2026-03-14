# Phase 9: UI & Menus

## Status: NOT STARTED

## Goal
Implement all game screens: Main Menu, New Game, Game HUD, and supporting UI overlays.

## Tasks

### Main Menu
- [ ] Layout with buttons: New Game, Continue, Load Game, Settings, Quit
- [ ] Continue button greyed out if no save exists
- [ ] Quit exits application
- [ ] Menu theme/styling

### New Game Screen
- [ ] Map Size selector (Small / Medium / Large)
- [ ] Character Creator:
  - Avatar/portrait selection or customization
  - Stat allocation (Size starting value, within allowed range)
- [ ] Number of Opponents selector
- [ ] AI Difficulty selector (per-AI dropdown)
- [ ] Item Selector (pick from list, custom items available from settings)
- [ ] Start Game button — validates config and launches game

### Game HUD
- [ ] Top-left: player avatar portrait
- [ ] Below portrait: Size, Speed, Energy stats (energy as bar)
- [ ] Top-right of portrait: item collected indicator (hidden until collected)
- [ ] Pause menu overlay (Resume, Save, Quit to Menu)

### Overlays
- [ ] Task overlay (from Phase 5 — integrate into UI layer)
- [ ] Clash overlay (from Phase 8 — integrate into UI layer)
- [ ] Win/Loss screen (from Phase 6 — integrate into UI layer)

## Dependencies
- Phase 1 (scene management)
- Phases 3, 5, 6, 8 (game systems feeding into HUD/overlays)

## Key Specs
- [Main Menu](../specs/main-menu.md)
- [HUD](../specs/hud.md)
- [Character Creator](../specs/character-creator.md)

## Deliverables
- All menu screens navigable
- Game HUD displays live stats
- Overlays integrate with game systems
- Character creator functional

## Testing Criteria
- [ ] All main menu buttons navigate to correct screens
- [ ] Continue button disabled when no save exists
- [ ] New Game screen validates all options before starting
- [ ] Character creator stat allocation works within bounds
- [ ] HUD updates energy, size, speed in real-time
- [ ] Item indicator appears on collection
- [ ] Pause menu works mid-game
- [ ] All overlays display and dismiss correctly
- [ ] UI scales correctly at different resolutions
