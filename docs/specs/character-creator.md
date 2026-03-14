# Feature Spec: Character Creator

## Overview
In the New Game screen, the player customizes their character's appearance and allocates starting stats.

## Appearance
- Select from a set of avatar portraits (bundled with game)
- Selected portrait displays in game HUD and clash overlay
- (Future: color customization, custom portrait upload)

## Stat Allocation
- **Budget:** 3 points (tunable balance value)
- **Allocatable stat:** Size (starting value 1, can increase up to 1 + budget)
- **Fixed stats:** Energy always starts at 100%, Speed always starts at Full
- Unspent points are lost (no banking)

### Allocation UI
- Size displayed with +/- buttons
- Remaining points counter
- Visual preview of current stats

## Constraints
- Size minimum: 1 (cannot go below)
- Size maximum at creation: 1 + budget (e.g., 4 with 3-point budget)
- Size maximum in-game: 10 (from size increasers)
- Budget value stored in game config (adjustable for balancing)

## Testing Criteria
- [ ] Avatar selection works and persists into game
- [ ] Point allocation respects budget
- [ ] Cannot exceed allocation limits
- [ ] Cannot reduce Size below 1
- [ ] Unspent points have no effect
- [ ] Selected stats carry into game correctly
- [ ] UI shows remaining points accurately
