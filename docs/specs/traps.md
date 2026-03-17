# Feature Spec: Traps

## Overview
Player places traps at current position to slow opponents. Traps are invisible to opponents until triggered.

## Supply
- By map size: Small 2, Medium 3, Large 5
- Not replenished during a match

## Placement
- Input: Space bar (`place_trap` action)
- Places at player's current grid cell
- Cannot place on: spawn, exit, locations, existing traps
- Cannot place during task/clash/pause
- 3-second cooldown between placements

## Trigger
- Opponent steps on trap cell
- Placer is immune to own traps
- Effect: 0.4x speed multiplier for 4 seconds
- Trap consumed (single-use)
- Brief red flash on victim

## AI Behavior
- AI cannot place traps (player-only feature)
- AI cannot see or avoid traps
- AI continues pathfinding at reduced speed when slowed

## HUD
- "Traps: X" counter displayed below energy bar

## Constants
```
TRAP_SUPPLY = {SMALL: 2, MEDIUM: 3, LARGE: 5}
TRAP_SLOW_DURATION = 4.0
TRAP_SLOW_MULTIPLIER = 0.4
TRAP_PLACEMENT_COOLDOWN = 3.0
```

## Save/Load
- Trap positions saved under `"traps"` key
- Player supply count saved
- Active slow effects (target + remaining duration) saved

## Testing Criteria
- [ ] Correct trap supply per map size
- [ ] Trap placed at player's grid cell
- [ ] Cannot place on spawn, exit, locations, existing traps
- [ ] Cannot place during task/clash/pause
- [ ] 3-second cooldown enforced
- [ ] Opponent triggers trap on step
- [ ] Placer immune to own traps
- [ ] 0.4x speed applied for 4 seconds
- [ ] Trap consumed after trigger
- [ ] Red flash visual on victim
- [ ] HUD counter updates correctly
- [ ] AI continues pathfinding while slowed
- [ ] Traps persist correctly through save/load
