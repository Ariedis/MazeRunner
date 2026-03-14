# Phase 2: Maze Generation & Rendering

## Status: NOT STARTED

## Goal
Implement procedural maze generation with three map sizes and render it using TileMap.

## Tasks
- [ ] Implement recursive backtracker (DFS) maze generation algorithm
- [ ] Define grid dimensions for Small, Medium, Large maps
- [ ] Generate maze data structure (2D array of cells with wall flags)
- [ ] Place locations (task nodes) within the maze — count scales with map size
- [ ] Place exit point (hidden until discovered by exploration)
- [ ] Create TileSet with wall tiles for all wall configurations
- [ ] Render maze to TileMap from generated data
- [ ] Implement camera system that follows the player
- [ ] Ensure maze is fully connected (no unreachable areas)
- [ ] Add visual distinction for location cells (placeholder markers, hidden until revealed)

## Dependencies
- Phase 1 (project structure, autoloads)

## Key Specs
- [Map Sizes](../specs/map-sizes.md)
- [Maze Generation](../specs/maze-generation.md)

## Deliverables
- Maze generates correctly at all three sizes
- Maze renders visually with TileMap
- Locations and exit are placed within the maze
- Camera follows a test entity through the maze

## Testing Criteria
- [ ] Small/Medium/Large mazes generate without errors
- [ ] Every cell in the maze is reachable from every other cell
- [ ] Location count matches expected count per map size
- [ ] Exit is placed and reachable
- [ ] TileMap renders walls correctly (no visual gaps or overlaps)
- [ ] Regenerating produces different mazes (seeded randomness)
- [ ] Performance: maze generates in <1s for Large maps
