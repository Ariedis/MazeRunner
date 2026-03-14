# Feature Spec: Procedural Maze Generation

## Overview
Generate a 2D maze using the recursive backtracker (DFS) algorithm. The maze is a grid of cells connected by passages, with no loops (spanning tree). Every cell is reachable from every other cell.

## Algorithm: Recursive Backtracker
1. Start at a random cell, mark it visited
2. While there are unvisited cells:
   a. If current cell has unvisited neighbors, pick one at random
   b. Remove the wall between current and chosen neighbor
   c. Push current to stack, move to chosen neighbor
   d. If no unvisited neighbors, pop from stack (backtrack)
3. Result: a perfect maze (exactly one path between any two cells)

## Data Structure
```
Cell:
  - walls: { top: bool, right: bool, bottom: bool, left: bool }
  - has_location: bool
  - is_exit: bool
  - position: Vector2i (grid coordinates)

Maze:
  - grid: Array[Array[Cell]]
  - width: int
  - height: int
  - seed: int (for reproducibility / save-load)
  - locations: Array[Vector2i]
  - exit: Vector2i
  - player_spawn: Vector2i
  - ai_spawns: Array[Vector2i]
```

## Placement Rules
- **Player spawn:** top-left quadrant of maze
- **Exit:** bottom-right quadrant, placed after generation, must be a dead-end or near one
- **Locations:** distributed evenly across the maze (avoid clustering), minimum distance from spawn
- **AI spawns:** distributed in remaining quadrants, equidistant from locations where possible

## Seeding
- Accept optional seed for reproducibility
- Store seed in save data so maze can be regenerated identically

## Rendering
- Use Godot TileMap with a TileSet where tile IDs correspond to wall configurations
- Cell size in pixels: TBD (recommend 32x32 or 64x64 tiles)
- Walls rendered as filled tiles, passages as empty/floor tiles

## Performance Target
- Small: <100ms generation
- Medium: <300ms generation
- Large: <1000ms generation

## Testing Criteria
- [ ] Algorithm produces a perfect maze (no loops, fully connected)
- [ ] Same seed produces identical maze
- [ ] Different seeds produce different mazes
- [ ] Locations placed with minimum distance constraints
- [ ] Exit reachable from spawn
- [ ] Generation time within targets per size
