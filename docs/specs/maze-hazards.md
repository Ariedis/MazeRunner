# Feature Spec: Maze Hazards

## Overview
Environmental dangers generated as part of the maze: dead-end traps, teleporters, one-way doors. All hazards are deterministically placed using RNG seeded from `seed_val + 200`.

## Generation Order
After base maze generation: one-way doors (affects pathfinding) → teleporters → dead-end traps.

---

## Dead-End Traps

### Rules
- 30% of dead ends marked as trapped (excluding spawn/exit/locations)
- One-time trigger (disarmed after first activation)

### Effect
- -25 energy drain
- 2-second freeze (cannot move)

### Visual
- Subtle red tint on cell floor

### AI Behavior

| Difficulty | Behavior |
|------------|----------|
| Easy | No avoidance |
| Medium | Avoids after triggering one |
| Hard | Pre-avoids all dead-end traps |

---

## Teleporters

### Rules
- Paired portals: Small 1 pair, Medium 2 pairs, Large 3 pairs
- Placed on corridor cells (non-dead-end, non-location, non-spawn)
- Two-way transport
- 1-second cooldown after use (prevents ping-pong)

### Visual
- Purple circle with pair number label

### AI Behavior
- All difficulties use teleporters in pathfinding (added as zero-cost edges in AStarPathfinder)

### AStarPathfinder Changes
- Teleporter pairs added as zero-cost bidirectional edges

---

## One-Way Doors

### Rules
- Directional passages: Small 2, Medium 4, Large 6
- Implemented via asymmetric wall data: cell A `wall["right"] = false`, cell B `wall["left"] = true`
- **Validation:** After placement, verify path exists from all spawns to exit. Remove and retry if broken.

### Visual
- Arrow marker on passage tile indicating allowed direction

### AI Behavior
- Handled implicitly by wall data representation (no special AI logic needed)

---

## Constants
```
HAZARD_TELEPORTER_PAIRS = {SMALL: 1, MEDIUM: 2, LARGE: 3}
HAZARD_ONE_WAY_DOORS = {SMALL: 2, MEDIUM: 4, LARGE: 6}
HAZARD_DEAD_END_PERCENT = 0.30
HAZARD_DEAD_END_ENERGY_DRAIN = 25.0
HAZARD_DEAD_END_FREEZE_DURATION = 2.0
HAZARD_TELEPORTER_COOLDOWN = 1.0
```

## Save/Load
- Hazards regenerated deterministically from seed (not saved directly)
- Only triggered dead-end positions saved (to track which are disarmed)

## Testing Criteria
- [ ] Dead-end traps placed on ~30% of eligible dead ends
- [ ] Dead-end trap drains 25 energy and freezes for 2 seconds
- [ ] Dead-end trap disarmed after first trigger
- [ ] Teleporter pairs spawn correct count per map size
- [ ] Teleporters transport between paired cells
- [ ] Teleporter 1-second cooldown prevents ping-pong
- [ ] One-way doors enforce directional movement
- [ ] One-way door validation: path exists from all spawns to exit
- [ ] Broken one-way doors removed and retried
- [ ] Hazards deterministic from seed
- [ ] AStarPathfinder includes teleporter edges
- [ ] AI Easy does not avoid dead-end traps
- [ ] AI Medium avoids dead-end traps after triggering
- [ ] AI Hard pre-avoids all dead-end traps
- [ ] Triggered dead-ends persist through save/load
