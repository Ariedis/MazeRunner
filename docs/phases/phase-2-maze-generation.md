# Phase 2: Maze Generation & Rendering

## Status: COMPLETE (2026-03-15)

## Goal
Implement procedural maze generation with three map sizes and render it using TileMap.

## Tasks
- [x] Implement recursive backtracker (DFS) maze generation algorithm
- [x] Define grid dimensions for Small, Medium, Large maps
- [x] Generate maze data structure (2D array of cells with wall flags)
- [x] Place locations (task nodes) within the maze — count scales with map size
- [x] Place exit point in bottom-right quadrant, preferring dead-ends
- [x] Place player spawn in top-left quadrant, preferring dead-ends
- [x] Place AI spawns in remaining open cells
- [x] Create TileSet with wall tile via programmatic ImageTexture
- [x] Render maze to TileMap using corridor-grid expansion
- [x] Implement camera system that follows the player (Camera2D on PlayerEntity)
- [x] Ensure maze is fully connected (DFS guarantees single spanning tree)
- [x] Add "Start Game" button to Main Menu wired to GameScene

## Dependencies
- Phase 1 (project structure, autoloads)

## Key Specs
- [Map Sizes](../specs/map-sizes.md)
- [Maze Generation](../specs/maze-generation.md)

## Deliverables
- Maze generates correctly at all three sizes
- Maze renders visually with TileMap
- Locations and exit are placed within the maze
- Camera follows a test entity through the maze with WASD

## Testing Criteria
- [x] Small/Medium/Large mazes generate without errors
- [x] Every cell in the maze is reachable from every other cell (BFS validates full connectivity)
- [x] Location count matches expected count per map size (4 / 8 / 14)
- [x] Exit is placed and reachable from player spawn
- [x] Regenerating with same seed produces identical mazes; different seeds differ
- [x] Performance: maze generates in <1s for Large (40×40) maps
- [x] `SceneManager.SCENE_GAME_SCENE` constant is present and non-empty

---

## Implementation Details

### Files Created

#### Data Layer (`scripts/maze/`)
- **`MazeCell.gd`** — `RefCounted`. Stores `position: Vector2i`, `walls: Dictionary`
  (`{"top", "right", "bottom", "left"}` all defaulting to `true`), and boolean flags
  `visited`, `has_location`, `is_exit`, `is_spawn`. `is_dead_end()` returns true when
  exactly 3 walls are present.

- **`MazeData.gd`** — `RefCounted`. Holds the `grid` (2D Array of `MazeCell`), dimensions
  `width`/`height`, `seed_val`, and placement results: `locations: Array[Vector2i]`,
  `exit: Vector2i` (default `(-1,-1)`), `player_spawn: Vector2i`, `ai_spawns: Array[Vector2i]`.
  Methods: `get_cell(col, row)`, `get_cell_v(pos)`, `is_valid(col, row)`, `get_dead_ends()`.

- **`MazeGenerator.gd`** — `RefCounted`. Entry point is `generate(map_size, seed_override=-1) -> MazeData`.
  Stores `_map_size` as instance var so private methods can access it.
  - **`_run_dfs`** — Iterative stack-based DFS (no recursion limit). Starts at `(0,0)`,
    marks visited, pushes to stack; at each step picks a random unvisited neighbour, carves
    walls in both directions, then advances. Backtracks by popping when no unvisited neighbours remain.
  - **`_place_exit`** — Quadrant 3 (bottom-right: `col >= width/2, row >= height/2`). Prefers
    dead-ends; falls back to all quadrant cells.
  - **`_place_player_spawn`** — Quadrant 0 (top-left), excludes exit cell. Same dead-end preference.
  - **`_place_locations`** — Fisher-Yates shuffle of all non-spawn/non-exit cells. Places
    `location_count` entries with minimum manhattan distance of `max(3, grid_width / location_count)`.
    Retries with decrementing `min_dist` (down to 1) if placement fails.
  - **`_place_ai_spawns`** — Shuffles remaining cells (excluding spawn, exit, locations), takes
    first `max_opponents` entries.

- **`MazeRenderer.gd`** — `Node`. `render(maze_data, cell_px)` creates a `TileMap` child,
  builds a single-source `TileSet` from a programmatic 64×64 gray `ImageTexture`, then applies
  corridor-grid expansion:
  - TileMap is `(2W+1) × (2H+1)` tiles; tile size is `cell_px / 2`.
  - Fill pass: every tile position gets the wall tile.
  - Carve pass: for each maze cell `(cx, cy)`, erase `(2cx+1, 2cy+1)` (floor); if no right
    wall, erase `(2cx+2, 2cy+1)`; if no bottom wall, erase `(2cx+1, 2cy+2)`.
  - `get_world_position(grid_pos)` converts maze grid coords to world pixel coords.

#### Game Scene (`scenes/game/`)
- **`GameScene.tscn`** — Root `Node2D` with a `CanvasLayer` UI containing `LabelSeed`,
  `LabelSize`, and `BtnMainMenu`. `MazeRenderer` and `PlayerEntity` are added at runtime.
- **`GameScene.gd`** — Reads `map_size` and `seed` from `GameState.config`, generates maze,
  renders it, creates a `Node2D` PlayerEntity with a `Camera2D` child positioned at the player
  spawn. Sets `GameState.current_state = IN_GAME`. `_process()` moves the player with WASD
  (free-form, no wall collision — that belongs to Phase 3).

#### Tests (`tests/`)
- **`test_maze_generator.gd`** — 22 assertions across: generation without error (3), full
  connectivity via BFS (3), location counts (3), exit placement and quadrant (2), spawn quadrant (1),
  exit reachability from spawn (1), same-seed determinism (1), different-seed variance (1),
  large-map performance <1000ms (1), location min-distance (1), grid dimensions (3), all cells
  have at least one passage (1), `SceneManager.SCENE_GAME_SCENE` exists (1).

### Files Modified

- **`scripts/autoloads/SceneManager.gd`** — Added `SCENE_GAME_SCENE` constant and
  `go_to_game_scene()` method.
- **`tests/scenes/TestRunnerScene.gd`** — Added `"res://tests/test_maze_generator.gd"` to
  `TEST_CLASSES`.
- **`scenes/menus/MainMenu.tscn`** — Added `BtnStartGame` Button node before `BtnQuit`.
- **`scenes/menus/MainMenu.gd`** — Connected `BtnStartGame` to `_on_start_game_pressed()`,
  which sets `GameState.config["map_size"] = SMALL`, `seed = 0`, then calls
  `SceneManager.go_to_game_scene()`.

### Architecture Decisions
- **Iterative DFS over recursive** to avoid GDScript call stack limits on large (40×40) mazes.
- **Corridor-grid expansion** for TileMap rendering: a `(2W+1)×(2H+1)` grid encodes both cells
  and the passages between them, avoiding the need for a multi-tile-per-cell wall atlas.
- **Programmatic TileSet** (`Image.create` + `ImageTexture.create_from_image`) eliminates the
  need for external art assets in Phase 2; visual polish deferred to Phase 12.
- **Quadrant-based placement** ensures spawn and exit are always in opposite corners, guaranteeing
  meaningful traversal distance regardless of seed.
- **`_map_size` instance variable** on `MazeGenerator` makes `Enums.MAP_SIZE_DATA[_map_size]`
  accessible in all private placement methods without passing it through every call.
- **Phase 2 movement is free-form** (no wall collision). Wall-collision physics belongs to
  Phase 3 (Player Movement & Mechanics).
