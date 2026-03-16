# Feature Spec: Fog of War

## Overview
The maze is hidden by fog. Only areas the player has explored are visible. Locations, the exit, and AI opponents are hidden until the player reaches/sees them.

## Implementation Approach
**Option A — Tile overlay (simpler):**
- Dark overlay tiles cover all cells
- Remove overlay tiles as player explores
- Simple to implement, works well with TileMap

**Option B — Shader (smoother):**
- Full-screen shader with a visibility texture
- Mark explored cells in the texture
- Smoother visual transitions, more visually polished

*Recommend starting with Option A, upgrade to B in polish phase if desired.*

## Visibility Rules
- Player reveals cells within a radius (suggest 2-3 cells) around their current position
- Revealed cells stay revealed permanently (no re-fogging)
- Visibility is per-player (AI has its own explored map, not shown to player)

## What Fog Hides
- Maze walls and passages (structure not visible)
- Locations (appear as generic markers only when revealed)
- Exit (completely hidden until player reaches its cell)
- AI opponents (not visible in fogged areas)
- Items at completed locations (if another player completed it)

## What Fog Shows
- Nothing — fully opaque until explored

## Save/Load
- Explored cell set must be serialized in save data
- On load, fog state is restored from saved explored cells

## Testing Criteria
- [x] Unexplored areas are fully hidden
- [x] Exploration reveals cells permanently
- [x] Locations only visible when in explored area
- [x] Exit only visible when in explored area
- [ ] AI opponents only visible in explored area — deferred to Phase 7
- [ ] Fog state saves and loads correctly — deferred to Phase 10 (load_from_array implemented, serialization wired in Phase 10)
