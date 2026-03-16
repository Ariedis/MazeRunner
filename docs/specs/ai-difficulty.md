# Feature Spec: AI Difficulty Levels

## Overview
AI difficulty is selectable per-opponent in the New Game screen. Difficulty affects decision-making quality, task simulation time, and optional fog cheating.

## Difficulty Levels

### Easy
- **Exploration:** Random frontier cell selection (no preference for unexplored or nearest)
- **Task wait:** 1.5× default duration
- **Speed:** 0.8× base (120 px/s full / 60 px/s half)
- **Energy management:** Rests when energy ≤ 40, resumes when energy ≥ 80
- **Fog:** Fully respects fog — discovers locations and exit only by physically entering their cells
- **Pathing:** 15% chance of random wrong turn at junctions (≥3 passable neighbours)

### Medium
- **Exploration:** 70% chance of nearest frontier cell, 30% random
- **Task wait:** 1.0× default duration
- **Speed:** 1.0× base (150 px/s full / 75 px/s half)
- **Energy management:** Rests when energy ≤ 20, resumes when energy ≥ 50
- **Fog:** Fully respects fog — discovers locations and exit only by physically entering their cells
- **Pathing:** Optimal A* pathing

### Hard
- **Exploration:** Frontier cell biased toward item location or exit (directional bias via `_nearest_to_target`)
- **Task wait:** 0.7× default duration
- **Speed:** 1.2× base (180 px/s full / 90 px/s half)
- **Energy management:** Rests when energy ≤ 5, resumes when energy ≥ 30 (effectively never rests)
- **Fog:** Full omniscience — all location positions and exit position are known from game start
- **Pathing:** Optimal A* pathing; always prioritises own item location when choosing between known locations

## Per-Opponent Configuration
- In New Game screen, each AI opponent has its own difficulty dropdown
- Mix of difficulties is allowed (e.g., 1 Easy + 1 Hard)

## Testing Criteria
- [x] Easy AI is noticeably less efficient than Medium (1.5× vs 1.0× task wait; random vs nearest-biased exploration)
- [x] Medium AI is noticeably less efficient than Hard (1.0× vs 0.7× task wait; 70% nearest vs full bias)
- [x] Easy AI makes visible wrong turns (15% wrong-turn at junctions verified in test_ai_brain.gd)
- [x] Hard AI prioritizes exploration efficiently (directional bias to item/exit tested)
- [x] Task wait durations scale correctly per difficulty (AI_TASK_MULTIPLIER constants verified)
- [x] Energy management differs between levels (rest thresholds: 40/20/5, targets: 80/50/30)
- [x] Hard AI has full omniscience from setup (all locations + exit pre-populated)
- [x] Per-opponent difficulty applies independently (each AIBrain seeded separately with ai_idx)
