# Feature Spec: Map Sizes

## Overview
Three map sizes define maze dimensions and location count.

## Size Definitions

| Property | Small | Medium | Large |
|----------|-------|--------|-------|
| Grid (cells) | 15x15 | 25x25 | 40x40 |
| Locations | 4 | 8 | 14 |
| Max Opponents | 2 | 4 | 6 |
| Recommended Cell px | 64x64 | 48x48 | 32x32 |

*Grid dimensions and location counts are suggested starting points — tune during Phase 12.*

## Location Scaling
- Locations = (number of players) + (bonus locations for size increasers)
- Minimum locations = players + 1 (to guarantee each player has an item location + at least 1 size increaser)
- Formula suggestion: `locations = num_players + ceil(grid_area * 0.005)`

## Constraints
- Every player's item must be at exactly one location
- Remaining locations contain size increasers or opponent items
- Locations must be at least N cells apart (N = grid_width / location_count, minimum 3)

## Testing Criteria
- [ ] Each size generates within its grid dimensions
- [ ] Location count matches formula for given player count
- [ ] Location minimum distance constraint respected
- [ ] Max opponent limit enforced in New Game UI
