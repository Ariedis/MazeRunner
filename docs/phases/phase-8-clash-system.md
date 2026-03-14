# Phase 8: Clash System

## Status: NOT STARTED

## Goal
Implement the clash mechanic when players collide, including dice roll, stat modifiers, and the loser's penalty task.

## Tasks
- [ ] Detect collision between player and AI opponent
- [ ] Trigger clash overlay UI
- [ ] Implement dice roll mechanic (random 1-6 + size stat for each participant)
- [ ] Display dice animation and stat comparison
- [ ] Determine winner (higher total wins; handle ties — re-roll)
- [ ] Winner result: continue moving, no penalty
- [ ] Loser result: display penalty task overlay
- [ ] Implement penalty task system:
  - Default: bicep curls (10 reps)
  - Weight scales with winner's size: 1-3 = 1kg, 4-7 = 2kg, 8-10 = 3kg
  - Speed scales with winner's energy: >80% = quickly, 50-80% = normal, <50% = slowly
- [ ] Penalty task timer (honor system, scaled duration based on speed modifier)
- [ ] Loser is immobilized during penalty task
- [ ] AI as loser: simulate penalty wait duration
- [ ] AI as winner: continue pathing after clash resolves
- [ ] Support custom clash penalty tasks (loaded from settings)

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
- [ ] Collision between player and AI triggers clash
- [ ] Dice roll produces values 1-6 + size stat
- [ ] Higher total wins consistently
- [ ] Ties trigger re-roll
- [ ] Penalty task displays correct weight based on winner size
- [ ] Penalty task displays correct speed based on winner energy
- [ ] Loser cannot move during penalty
- [ ] AI handles being clash loser (waits appropriate duration)
- [ ] Custom penalty tasks load from settings
- [ ] Multiple clashes in one game work correctly
