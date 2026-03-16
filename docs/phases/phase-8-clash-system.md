# Phase 8: Clash System

## Status: COMPLETE

## Goal
Implement the clash mechanic when players collide, including dice roll, stat modifiers, and the loser's penalty task.

## Tasks
- [x] Detect collision between player and AI opponent
- [x] Trigger clash overlay UI
- [x] Implement dice roll mechanic (random 1-6 + size stat for each participant)
- [x] Display dice animation and stat comparison
- [x] Determine winner (higher total wins; handle ties — re-roll)
- [x] Winner result: continue moving, no penalty
- [x] Loser result: display penalty task overlay
- [x] Implement penalty task system:
  - Default: bicep curls (10 reps)
  - Weight scales with winner's size: 1-3 = 1kg, 4-7 = 2kg, 8-10 = 3kg
  - Speed scales with winner's energy: >80% = quickly, 50-80% = normal, <50% = slowly
- [x] Penalty task timer (honor system, scaled duration based on speed modifier)
- [x] Loser is immobilized during penalty task
- [x] AI as loser: simulate penalty wait duration
- [x] AI as winner: continue pathing after clash resolves
- [x] Support custom clash penalty tasks (loaded from settings)

## Dependencies
- Phase 3 (player stats, collision)
- Phase 7 (AI opponents, collision)

## Key Specs
- [Clash Mechanic](../specs/clash-mechanic.md)
- [Clash Task](../specs/clash-task.md)

## Deliverables
- Clashes trigger on collision
- Dice + size roll determines winner
- Loser receives penalty task scaled by winner's stats
- Both player-vs-AI and AI-vs-AI clashes work

## Testing Criteria
- [x] Collision between player and AI triggers clash
- [x] Dice roll produces values 1-6 + size stat
- [x] Higher total wins consistently
- [x] Ties trigger re-roll
- [x] Penalty task displays correct weight based on winner size
- [x] Penalty task displays correct speed based on winner energy
- [x] Loser cannot move during penalty
- [x] AI handles being clash loser (waits appropriate duration)
- [x] Custom penalty tasks load from settings
- [x] Multiple clashes in one game work correctly

## Implementation Notes

### New Files
| File | Purpose |
|------|---------|
| `scripts/clash/ClashResolver.gd` | Pure logic (static methods): dice rolling, clash resolution, penalty weight/speed/duration calculation. No node dependencies — fully unit-testable. |
| `scripts/clash/ClashTaskLoader.gd` | Loads penalty task from `user://clash_tasks.json`; falls back to default (Bicep Curls, 10 reps) if file absent or invalid. |
| `scenes/clash/ClashOverlay.gd` | CanvasLayer (z=15) for player-involved clashes. Phase 1: dice roll result screen. Phase 2: penalty task screen with countdown timer and "Done" button. |

### Modified Files
| File | Change |
|------|--------|
| `scripts/ai/AIBrain.gd` | Added `PENALTY` state. `start_penalty(duration)` saves pre-clash state; `tick()` counts down and restores state on expiry. No energy regen during penalty. |
| `scenes/ai/AIOpponent.gd` | Collision layer 4, mask 1 (walls only). PENALTY state handling in `_physics_process`. `resolve_ai_ai_clash(other)` method for instant AI-AI resolution. |
| `scenes/player/Player.gd` | Collision layer 2, mask 1 (walls only). `freeze()`/`unfreeze()` methods. `_is_frozen` and `_clash_cooldown` fields. |
| `scenes/game/GameScene.gd` | `_check_clashes()` called every frame: distance-based proximity detection for all character pairs. Owns clash RNG, `ClashOverlay`, and `_clash_active` guard. |
| `scripts/autoloads/Enums.gd` | Added `CLASH_COOLDOWN_SECONDS`, `CLASH_PENALTY_EXERCISE`, `CLASH_PENALTY_REPS`. |

### Architecture Decisions
- **Phase-through collision**: Player (layer 2) and AI (layer 4) have non-overlapping collision masks — they pass through each other physically and can never block each other. Both still collide with walls (layer 1). This prevents the player from being trapped by AI opponents.
- **Distance-based detection**: `GameScene._check_clashes()` runs every frame, measuring `distance_to()` between all character pairs. Triggers at `tile_size * 1.0`. This replaces slide-collision detection which required physical contact to register.
- **Centralised detection**: All clash detection lives in `GameScene`, which holds references to the player and all AI opponents. Neither `Player` nor `AIOpponent` need to know about each other for detection purposes.
- **Cooldown = base + penalty duration**: Both characters receive `CLASH_COOLDOWN_SECONDS + penalty_duration` cooldown so neither can re-clash until the loser's penalty has expired.
- **Separation**: After a clash, both characters are pushed `tile_size * 0.6` apart along their separation vector before the cooldown window closes.
- **AI-AI clashes**: Resolved instantly via `AIOpponent.resolve_ai_ai_clash(other)` — no overlay shown to the player. Loser AI enters `PENALTY` state for the same duration a player would wait.
- **`_clash_active` guard**: Set to `true` the moment a player clash begins; cleared when the overlay emits `clash_resolved` or `penalty_completed`. Prevents a second clash from firing while the overlay is open.
