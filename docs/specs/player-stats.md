# Feature Spec: Player Stats

## Overview
Each character (player and AI) has three stats that affect gameplay.

## Stats

### Size
- **Range:** 1 to 10
- **Starting value:** 1 (modifiable in character creator, within allowed allocation)
- **Modified by:** Size increaser items (+1 per pickup, capped at 10)
- **Affects:**
  - Clash rolls (added to dice result)
  - Clash penalty scaling (weight tier for loser's task)

### Speed
- **States:** Full or Half
- **Determined by:** Energy level
  - Energy > 0%: Full speed
  - Energy = 0%: Half speed
- **Not directly modifiable** — driven by energy

### Energy
- **Range:** 0% to 100%
- **Starting value:** 100%
- **Drain:** Decreases while player is moving (rate TBD — suggest 1% per second of movement)
- **Regen:** Increases while player is stationary (rate TBD — suggest 2% per second)
- **Affects:**
  - Speed state (above)
  - Clash penalty scaling (speed modifier for loser's task)

## Character Creator Allocation
- Player starts with an allocation budget (e.g., 3 points)
- Can increase starting Size (costs 1 point per +1 Size)
- Starting Energy is always 100%
- Starting Speed is always Full
- Allocation budget is a balance lever — tune in Phase 12

## Testing Criteria
- [ ] Size capped at 10, cannot exceed
- [ ] Speed toggles correctly at energy boundary
- [ ] Energy drains and regens at defined rates
- [ ] Starting stats respect character creator allocation
- [ ] Stats persist correctly through save/load
