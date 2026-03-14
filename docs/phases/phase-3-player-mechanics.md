# Phase 3: Player Movement & Mechanics

## Status: NOT STARTED

## Goal
Implement player character with movement, energy system, speed mechanics, and stat tracking.

## Tasks
- [ ] Create Player scene (CharacterBody2D with sprite, collision)
- [ ] Implement grid-based or free movement through maze corridors
- [ ] Implement energy system: movement drains energy
- [ ] Implement energy regeneration when standing still
- [ ] Implement speed states: Full speed (energy > 0%) and Half speed (energy = 0%)
- [ ] Create player stats: Size (1-10), Speed (Half/Full), Energy (0-100%)
- [ ] Implement stat allocation in character creation (feeds into Phase 9 UI)
- [ ] Player collision with maze walls
- [ ] Player collision detection with other characters (triggers clash — Phase 8)
- [ ] Smooth movement and animation placeholder

## Dependencies
- Phase 1 (input map, global state)
- Phase 2 (maze structure for collision)

## Key Specs
- [Player Stats](../specs/player-stats.md)
- [Energy & Movement](../specs/energy-movement.md)

## Deliverables
- Player moves through maze with correct collision
- Energy drains while moving, regenerates while stationary
- Speed halves when energy hits 0%
- Stats are tracked and modifiable

## Testing Criteria
- [ ] Player cannot walk through walls
- [ ] Energy decreases while moving at consistent rate
- [ ] Energy increases while stationary at consistent rate
- [ ] Movement speed visibly halves when energy = 0%
- [ ] Speed returns to full when energy > 0%
- [ ] Size stat can be modified (for size increaser item)
- [ ] Player position updates correctly in global state
