# Feature Spec: AI Difficulty Levels

## Overview
AI difficulty is selectable per-opponent in the New Game screen. Difficulty affects decision-making quality, task simulation time, and optional fog cheating.

## Difficulty Levels

### Easy
- **Exploration:** Random direction at junctions (no preference for unexplored)
- **Task wait:** 1.5x default duration
- **Energy management:** No resting strategy (runs until depleted, then walks at half)
- **Fog:** Fully respects fog (no knowledge of unexplored areas)
- **Pathing:** Occasionally takes suboptimal paths (10-20% chance of wrong turn at junction)

### Medium
- **Exploration:** Prefers unexplored directions (70% chance)
- **Task wait:** 1.0x default duration
- **Energy management:** Rests when energy <20% near locations
- **Fog:** Fully respects fog
- **Pathing:** Optimal A* pathing

### Hard
- **Exploration:** Always picks unexplored directions
- **Task wait:** 0.7x default duration
- **Energy management:** Strategic resting — rests when approaching locations or exit to ensure high energy for potential clashes
- **Fog:** Partial omniscience — knows general direction of nearest location (but not exact path)
- **Pathing:** Optimal A* pathing with shortest-path preference

## Per-Opponent Configuration
- In New Game screen, each AI opponent has its own difficulty dropdown
- Mix of difficulties is allowed (e.g., 1 Easy + 1 Hard)

## Testing Criteria
- [ ] Easy AI is noticeably less efficient than Medium
- [ ] Medium AI is noticeably less efficient than Hard
- [ ] Easy AI makes visible wrong turns
- [ ] Hard AI prioritizes exploration efficiently
- [ ] Task wait durations scale correctly per difficulty
- [ ] Energy management differs visibly between levels
- [ ] Hard AI's directional hint works without revealing full maze
- [ ] Per-opponent difficulty applies independently
