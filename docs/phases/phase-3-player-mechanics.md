# Phase 3: Player Movement & Mechanics

## Status: COMPLETE (2026-03-16)

## Goal
Implement player character with movement, energy system, speed mechanics, and stat tracking.

## Tasks
- [x] Create Player scene (CharacterBody2D with sprite, collision)
- [x] Implement grid-based or free movement through maze corridors
- [x] Implement energy system: movement drains energy
- [x] Implement energy regeneration when standing still
- [x] Implement speed states: Full speed (energy > 0%) and Half speed (energy = 0%)
- [x] Create player stats: Size (1-10), Speed (Half/Full), Energy (0-100%)
- [ ] Implement stat allocation in character creation (feeds into Phase 9 UI)
- [x] Player collision with maze walls
- [ ] Player collision detection with other characters (triggers clash — Phase 8)
- [ ] Smooth movement and animation placeholder

## Dependencies
- Phase 1 (input map, global state)
- Phase 2 (maze structure for collision)

## Key Specs
- [Player Stats](../specs/player-stats.md)
- [Energy & Movement](../specs/energy-movement.md)

## Deliverables
- Player moves through maze with correct collision
- Energy drains while moving, regenerates while stationary
- Speed halves when energy hits 0%
- Stats are tracked and modifiable

## Testing Criteria
- [x] Player cannot walk through walls (StaticBody2D wall collision built from TileMap used cells)
- [x] Energy decreases while moving at consistent rate (unit tested: drain rate matches ENERGY_DRAIN constant)
- [x] Energy increases while stationary at consistent rate (unit tested: regen rate matches ENERGY_REGEN constant)
- [x] Movement speed visibly halves when energy = 0% (unit tested: current_speed() returns HALF_SPEED)
- [x] Speed returns to full when energy > 0% (unit tested: is_full_speed and current_speed())
- [x] Size stat can be modified (unit tested: add_size(), clamped to MIN/MAX)
- [x] Player position updates correctly in global state (unit tested: GameState.player["position"] key + sync)

---

## Implementation Details

### Files Created

#### Player (`scripts/player/` and `scenes/player/`)

- **`scripts/player/PlayerStats.gd`** — `RefCounted`. Pure data class with no scene dependency,
  making it fully unit-testable. Holds `size: int` (default 1) and `energy: float` (default 100.0).
  - **`is_full_speed`** — computed property; returns `energy > 0.0`.
  - **`current_speed()`** — returns `Enums.FULL_SPEED` (150 px/s) when `is_full_speed`, else
    `Enums.HALF_SPEED` (75 px/s).
  - **`drain(delta)`** — decreases energy by `Enums.ENERGY_DRAIN * delta`, floored at 0.
  - **`regen(delta)`** — increases energy by `Enums.ENERGY_REGEN * delta`, capped at 100.
  - **`add_size(amount)`** — clamps `size + amount` to `[Enums.MIN_SIZE, Enums.MAX_SIZE]`.

- **`scenes/player/Player.gd`** — `CharacterBody2D`. Owns a `PlayerStats` instance.
  - **`setup(tile_size)`** — called from `GameScene._ready()` after the player is in the scene
    tree. Sets `CollisionShape2D.shape` to a `CircleShape2D` with `radius = tile_size * 0.4`
    (fits all corridor widths: 12.8 px for SMALL, 9.6 px for MEDIUM, 6.4 px for LARGE), then
    reads initial `size` and `energy` from `GameState.player`.
  - **`_physics_process(delta)`** — reads four directional input actions (`move_up/down/left/right`),
    sets `velocity` to `input_dir.normalized() * stats.current_speed()` when moving (calls
    `stats.drain(delta)`), or `Vector2.ZERO` when stationary (calls `stats.regen(delta)`).
    Skips movement when `GameState.match_state["is_paused"]` is true. Calls `move_and_slide()`,
    then syncs `energy`, `size`, and `position` to `GameState.player` and emits
    `SignalBus.player_energy_changed`.

- **`scenes/player/Player.tscn`** — `CharacterBody2D` with `motion_mode = MOTION_MODE_FLOATING`
  (required for top-down 2D; avoids platformer-style floor-snapping). Children:
  - `CollisionShape2D` — shape is `null` at scene load; assigned at runtime by `setup()`.
  - `Polygon2D` — placeholder visual; blue square (`Color(0.2, 0.6, 1, 1)`) at ±10 px.

#### Tests (`tests/`)

- **`test_player_stats.gd`** — 22 assertions across: initial values (3), drain rate and
  consistency (3), regen rate and consistency (3), energy floor/cap (2), speed states at zero
  and positive energy (4), speed restores after regen (1), `add_size` increases (1), size
  clamping at max and min (2), GameState key presence (2), energy sync to GameState (1).

### Files Modified

- **`scripts/maze/MazeRenderer.gd`** — Added `_build_wall_collisions()`. Called after
  `_carve_passages()`, it creates a single `StaticBody2D` child (`"WallCollision"`) and
  iterates `TileMap.get_used_cells(0)` — every tile remaining after carving is a wall. For each
  wall tile at TileMap grid `(tc, tr)`, adds a `CollisionShape2D` with a shared
  `RectangleShape2D` (size = `_tile_size × _tile_size`) positioned at the tile's world center
  `(tc * _tile_size + half, tr * _tile_size + half)`. All collision shapes share the same
  `RectangleShape2D` instance. Removed physics layer from `TileSet` — the TileMap is now
  visual-only. See **Architecture Decisions** for why.

- **`scenes/game/GameScene.gd`** — Replaced the free-form `Node2D` PlayerEntity and `_process`
  movement loop with the `Player.tscn` scene. Instantiates and `add_child`s the Player, then
  calls `setup(tile_size)` and positions it at `_renderer.get_world_position(player_spawn)`.
  Camera2D is still added as a runtime child of the Player. Connects
  `SignalBus.player_energy_changed` to `_on_player_energy_changed` which updates `LabelEnergy`
  and `LabelSpeed` in the UI.

- **`scenes/game/GameScene.tscn`** — Added `LabelEnergy` (offset_top 70) and `LabelSpeed`
  (offset_top 100) to the UI `CanvasLayer`. `BtnMainMenu` moved to offset_top 130.

- **`tests/scenes/TestRunnerScene.gd`** — Added `"res://tests/test_player_stats.gd"` to
  `TEST_CLASSES`.

### Architecture Decisions

- **`PlayerStats` as a `RefCounted`** (not a `Node`): keeps stat logic pure and unit-testable
  without needing a running scene tree. The `Player` node owns the instance and calls its
  methods each physics frame.

- **`StaticBody2D` for wall collision instead of TileSet physics layers**: programmatic TileSet
  physics setup in Godot 4 (adding physics layers and collision polygons to `TileData` at
  runtime) is unreliable — the coordinate system for `TileData` polygon points and the
  interaction between TileSet physics layers and dynamically created TileMaps produced no
  collision. A `StaticBody2D` with one `CollisionShape2D` per wall tile is explicit, uses only
  standard Godot 2D physics, and requires no TileSet configuration. The shared
  `RectangleShape2D` keeps memory cost low regardless of maze size.

- **`MOTION_MODE_FLOATING`** on Player: the default `MOTION_MODE_GROUNDED` applies
  platformer-style floor-snapping and gravity interaction, causing erratic behaviour in a
  top-down 2D scene. `MOTION_MODE_FLOATING` treats all surfaces as collidable obstacles
  without any floor/ceiling bias.

- **`setup(tile_size)` over `_ready()`** for collision shape initialisation: the tile size
  is only known after `GameScene` generates the maze, so the collision radius is assigned via
  an explicit call rather than in `_ready()`. This keeps the Player scene self-contained while
  allowing the shape to adapt to all three map sizes.
