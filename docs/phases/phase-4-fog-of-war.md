# Phase 4: Fog of War & Exploration

## Status: NOT STARTED

## Goal
Implement fog of war so players only see explored areas of the maze. Locations and exit are hidden until the player reaches them.

## Tasks
- [ ] Implement fog of war overlay (shader-based or tile overlay)
- [ ] Track explored cells per player
- [ ] Reveal cells as player moves through them (radius-based or line-of-sight)
- [ ] Location markers hidden under fog, revealed when player reaches the cell
- [ ] Exit hidden under fog, revealed when player reaches it
- [ ] Fog persists — explored areas stay revealed
- [ ] AI opponents are only visible when in player's explored area
- [ ] Ensure fog works correctly at all three map sizes

## Dependencies
- Phase 2 (maze rendering)
- Phase 3 (player movement, position tracking)

## Key Specs
- [Fog of War](../specs/fog-of-war.md)

## Deliverables
- Maze starts fully fogged except player's starting area
- Fog clears as player explores
- Locations and exit only visible when reached
- AI opponents visible only in explored area

## Testing Criteria
- [ ] Maze starts fogged — unexplored areas not visible
- [ ] Moving through corridors reveals cells permanently
- [ ] Locations appear as placeholder until player reaches them
- [ ] Exit is not visible until player discovers it
- [ ] AI opponents hidden in unexplored fog
- [ ] Performance acceptable at Large map size
- [ ] Fog state preserved during save/load (Phase 10)
