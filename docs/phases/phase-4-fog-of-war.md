# Phase 4: Fog of War & Exploration

## Status: COMPLETE

## Goal
Implement fog of war so players only see explored areas of the maze. Locations and exit are hidden until the player reaches them.

## Tasks
- [x] Implement fog of war overlay (tile overlay via FogRenderer)
- [x] Track explored cells per player (FogOfWar.explored Dictionary)
- [x] Reveal cells as player moves through them (radius-based, default radius 2)
- [x] Location markers hidden under fog, revealed when player reaches the cell *(marker layer added before FogRenderer in Phase 5 — fog covers via draw order)*
- [x] Exit hidden under fog, revealed when player reaches it *(exit marker added before FogRenderer in Phase 6)*
- [ ] AI opponents are only visible when in player's explored area *(Phase 7)*
- [x] Ensure fog works correctly at all three map sizes

## Dependencies
- Phase 2 (maze rendering)
- Phase 3 (player movement, position tracking)

## Key Specs
- [Fog of War](../specs/fog-of-war.md)

## Deliverables
- [x] Maze starts fully fogged except player's starting area
- [x] Fog clears as player explores
- [x] Locations and exit only visible when reached *(via scene-tree draw order — implemented in Phases 5 & 6)*
- [ ] AI opponents visible only in explored area *(Phase 7)*

## Testing Criteria
- [x] Maze starts fogged — unexplored areas not visible
- [x] Moving through corridors reveals cells permanently
- [x] Locations appear as yellow octagon markers, hidden until player reaches them *(Phase 5)*
- [x] Exit is not visible until player discovers it *(Phase 6)*
- [ ] AI opponents hidden in unexplored fog *(Phase 7)*
- [x] Performance acceptable at Large map size
- [ ] Fog state preserved during save/load (Phase 10)

---

## Implementation Details

### Files Created

#### Fog Logic (`scripts/fog/`)

- **`FogOfWar.gd`** — `RefCounted`. Pure data class with no scene dependency, making it fully
  unit-testable. Tracks explored cells in a `Dictionary` (Vector2i → true) for O(1) lookup.
  - **`reveal_radius: int`** — default `2`. Controls the square half-extent of the reveal window.
  - **`reveal(center, maze_width, maze_height) -> Array[Vector2i]`** — iterates all cells in
    `[center.x - radius, center.x + radius] × [center.y - radius, center.y + radius]`, clamps
    to `[0, maze_width) × [0, maze_height)`, skips already-explored cells, adds remaining cells
    to `explored`, and returns only the newly revealed cells. Returning only new cells keeps the
    downstream `FogRenderer.reveal_cells()` call cheap — no redundant tile erases.
  - **`is_explored(pos) -> bool`** — `explored.has(pos)`.
  - **`get_explored_array() -> Array`** — returns `explored.keys()` for save/load serialisation.
  - **`load_from_array(cells)`** — clears `explored` then re-populates from an Array of
    Vector2i values. Loading `[]` fully resets fog state.

- **`FogRenderer.gd`** — `Node`. Manages a second `TileMap` that sits on top of the maze
  rendering TileMap (draw order determined by scene-tree child order).
  - **`initialize(maze_width, maze_height, tile_size)`** — creates a TileSet with a single
    programmatic black `ImageTexture` (matching the maze TileMap's tile size), fills every
    position in the `(2W+1) × (2H+1)` overlay grid with the fog tile, then calls `add_child`
    on the internal TileMap.
  - **`reveal_cells(cells: Array[Vector2i])`** — for each maze cell `(col, row)`, computes the
    TileMap centre `(2*col+1, 2*row+1)` and erases a 3×3 block of fog tiles centred there
    (covering the cell and the four adjacent passage tiles). All positions are clamped to valid
    TileMap bounds before erasing.

#### Tests (`tests/`)

- **`test_fog_of_war.gd`** — 22 assertions across: initial empty state (2), reveal marking
  cells explored (2), return value of `reveal()` (2), idempotency — re-revealing returns nothing
  but explored set is unchanged (2), radius coverage for radius 2 (25 cells) and radius 1
  (9 cells) in open space (2), bounds clamping at top-left, bottom-right, and origin (3),
  default radius constant (1), serialisation round-trip via `get_explored_array()` and
  `load_from_array()` (4), large-map bounds validity (1), sequential reveal accumulation (1),
  custom radius (1), `get_explored_array` ↔ `is_explored` agreement (1), clearing state with
  empty array (1).

### Files Modified

- **`scripts/maze/MazeRenderer.gd`** — Added `world_to_grid(world_pos: Vector2) -> Vector2i`.
  Inverse of `get_world_position`: `col = int(world_pos.x / tile_size - 1.0) / 2`,
  `row = int(world_pos.y / tile_size - 1.0) / 2`. Verified: cell `(0,0)` world position
  `(tile_size, tile_size)` → `col = (1-1)/2 = 0` ✓; cell `(1,0)` world position
  `(3*tile_size, tile_size)` → `col = (3-1)/2 = 1` ✓.

- **`scenes/game/GameScene.gd`** — Added `_fog: FogOfWar`, `_fog_renderer: FogRenderer`, and
  `_last_grid_cell := Vector2i(-1, -1)`. In `_ready()`, instantiates `FogRenderer` after the
  Player is positioned and calls `initialize(width, height, tile_size)`. `FogRenderer` is added
  as a child of `GameScene` after `MazeRenderer`, placing it higher in the draw order so fog
  tiles render on top of maze tiles. Added `_process(_delta)`: converts
  `_player.global_position` to a maze grid cell via `_renderer.world_to_grid()`; early-returns
  if the cell hasn't changed; otherwise calls `_fog.reveal()`, passes newly revealed cells to
  `_fog_renderer.reveal_cells()`, and syncs `GameState.player["explored_cells"]`.

- **`tests/scenes/TestRunnerScene.gd`** — Added `"res://tests/test_fog_of_war.gd"` to
  `TEST_CLASSES`.

### Architecture Decisions

- **Two-class split (`FogOfWar` + `FogRenderer`)** mirrors the Phase 3 `PlayerStats`/`Player`
  pattern: logic is pure and unit-testable independent of the scene tree; the renderer handles
  only visual concerns.

- **Poll in `_process` rather than signals**: fog reveal is a continuous spatial query that
  runs every frame anyway. Introducing a signal would add complexity without reducing work —
  `_process` already has to call `world_to_grid` to know whether to act, and early-returns
  immediately when the cell hasn't changed.

- **Return only newly revealed cells from `reveal()`**: `FogRenderer.reveal_cells()` calls
  `TileMap.erase_cell()` per tile. Passing the full explored set each frame would make reveal
  cost O(explored) instead of O(newly revealed). In the common case (player hasn't moved to a
  new cell) the call is skipped entirely.

- **3×3 fog erase block per maze cell**: each maze cell maps to TileMap coordinate
  `(2*col+1, 2*row+1)`. The adjacent tiles at offsets `(±1, 0)` and `(0, ±1)` are passage
  corridors; `(±1, ±1)` are wall corners shared between cells. Erasing all 9 ensures no
  visible fog remnants appear in corridors between revealed cells.

- **Scene-tree child order for draw order**: adding `FogRenderer` after `MazeRenderer` in
  `GameScene._ready()` means the fog TileMap is always drawn on top of the maze TileMap in
  Godot 4's default 2D rendering. No z-index manipulation required.
