# Feature Spec: Power-ups

## Overview
Collectible items spawned at random maze positions granting temporary buffs. Both player and AI can pick them up.

## Types

| Type | Effect | Duration/Amount |
|------|--------|-----------------|
| Speed Boost | 1.8x speed multiplier | 5 seconds |
| Energy Refill | Instant energy restore | +50 (capped at 100) |
| Area Reveal | Reveal fog in large radius | Radius 5 cells (vs normal 2) |

## Spawn Rules
- Count by map size: Small 3, Medium 6, Large 10
- Placed after locations/spawns using RNG seeded from `maze_data.seed_val + 100`
- No overlap with spawn, exit, locations, ai_spawns
- Minimum manhattan distance 3 between power-ups
- Type assigned randomly (1/3 each)

## Pickup
- Proximity trigger: 1.0 * tile_size distance
- Consumed on pickup, node removed from scene
- Effect applied immediately

## AI Behavior

| Difficulty | Behavior |
|------------|----------|
| Easy | Ignores power-ups entirely |
| Medium | Picks up if on current path (opportunistic) |
| Hard | Actively pathfinds to nearest power-up when energy < 40 or exploring |

## Visual
- Diamond-shaped Polygon2D
- Color-coded: cyan (Speed Boost), green (Energy Refill), magenta (Area Reveal)
- Pulse animation (scale oscillation)

## Constants
```
POWERUP_SPEED_BOOST_MULTIPLIER = 1.8
POWERUP_SPEED_BOOST_DURATION = 5.0
POWERUP_ENERGY_REFILL_AMOUNT = 50.0
POWERUP_AREA_REVEAL_RADIUS = 5
POWERUP_COUNTS = {SMALL: 3, MEDIUM: 6, LARGE: 10}
```

## Save/Load
- Remaining power-ups saved under `"powerups"` key (positions + types)
- Active boost timers saved on player/AI state

## Testing Criteria
- [ ] Correct number of power-ups spawned per map size
- [ ] No overlap with spawn, exit, locations, ai_spawns
- [ ] Minimum distance 3 between power-ups
- [ ] Speed Boost applies 1.8x multiplier for 5 seconds
- [ ] Energy Refill restores +50 capped at 100
- [ ] Area Reveal clears fog in radius 5
- [ ] Power-up consumed on pickup
- [ ] AI Easy ignores power-ups
- [ ] AI Medium picks up opportunistically
- [ ] AI Hard pathfinds to power-ups when energy < 40
- [ ] Power-ups persist correctly through save/load
- [ ] Deterministic placement from seed
