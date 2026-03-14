# Phase 12: Polish & Integration

## Status: NOT STARTED

## Goal
Final integration testing, bug fixes, visual polish, and performance optimization.

## Tasks
- [ ] Full playthrough testing at each map size
- [ ] AI behavior tuning per difficulty level
- [ ] Energy drain/regen rate balancing
- [ ] Clash balance testing (dice + size feel fair?)
- [ ] Task timer duration balancing
- [ ] UI/UX review — button sizing, readability, flow
- [ ] Performance profiling on Large maps
- [ ] Memory leak testing (scene transitions, long play sessions)
- [ ] Edge case handling:
  - All locations completed but item not found (shouldn't happen — verify placement)
  - Multiple AI reaching exit simultaneously
  - Clash during clash (queue system)
  - Save/load during overlay states
- [ ] Visual polish: transitions, animations, juice
- [ ] Placeholder art replacement (if final assets available)
- [ ] Build and export testing

## Dependencies
- All previous phases complete

## Deliverables
- Stable, polished game build
- Known issues documented
- Balance values tuned

## Testing Criteria
- [ ] Complete game loop works: menu → new game → explore → tasks → item → exit → win
- [ ] AI completes same loop autonomously
- [ ] 10+ consecutive games without crash
- [ ] Save/load works across all game states
- [ ] Settings persist and apply correctly
- [ ] Custom content integrates without issues
- [ ] Performance: stable 60fps on target hardware at all map sizes
