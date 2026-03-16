# Phase 7: AI Opponents

## Status: COMPLETE (2026-03-16)

## Goal
Implement AI-controlled opponents that navigate the maze, complete tasks at locations, collect their items, and race to the exit.

## Tasks
- [x] Create AI character scene (code-driven CharacterBody2D, no .tscn)
- [x] Implement A* pathfinding on maze graph
- [x] AI state machine: EXPLORE → GO_TO_LOC → DO_TASK → GO_TO_EXIT → RESTING
- [x] AI exploration: frontier-based — visits adjacent unexplored cells
- [x] AI task simulation: wait at location for difficulty-scaled duration
- [x] AI item awareness: each AI has a randomly assigned item location
- [x] AI exit-seeking: once item collected, pathfind to exit
- [x] AI energy management: enters RESTING state when energy drops below threshold; resumes prior state when recharged to target
- [x] Implement difficulty levels affecting AI behavior:
  - Easy: random frontier exploration, 15% wrong-turn at junctions, 1.5× task wait, 0.8× speed, rest threshold 40→target 80
  - Medium: 70% prefer nearest frontier cell, 1.0× task wait, 1.0× speed, rest threshold 20→target 50
  - Hard: full omniscience (all locations + exit pre-known), biased exploration, 0.7× task wait, 1.2× speed, rest threshold 5→target 30
- [ ] AI collision with player triggers clash (Phase 8)
- [x] Support configurable number of opponents (1-N from GameState.config)
- [x] Easy/Medium respects fog — discovers locations/exit by physical contact only

## Dependencies
- Phase 2 (maze structure for pathfinding)
- Phase 3 (character base scene)
- Phase 5 (location/task interaction)

## Key Specs
- [AI Pathfinding](../specs/ai-pathfinding.md)
- [AI Difficulty](../specs/ai-difficulty.md)

## Deliverables
- AI opponents navigate the maze autonomously
- AI completes tasks and collects items
- AI races to exit after item collection
- Difficulty levels produce noticeably different behavior

## Testing Criteria
- [x] AI navigates maze without getting stuck (A* guarantees valid paths; frontier always non-empty in connected maze)
- [x] AI visits locations and simulates task completion (DO_TASK state countdown)
- [x] AI collects its item when found (_item_loc_pos match triggers has_item = true)
- [x] AI pathfinds to exit after item collection (GO_TO_EXIT state, A* to exit_pos)
- [x] Easy AI is noticeably slower/less efficient than Hard (1.5× vs 0.7× task wait; random vs optimal exploration)
- [x] Multiple AI opponents don't interfere with each other's pathing (each has independent brain + RNG seed)
- [ ] AI triggers clash when colliding with player (Phase 8)
- [x] Easy/Medium AI doesn't cheat (locations/exit discovered only by entering cells)
- [x] Hard AI has full omniscience (all locations and exit known from setup)

## Deliverables
- [x] AStarPathfinder — pure A* on maze graph with Manhattan heuristic
- [x] AIBrain — state machine (EXPLORE/GO_TO_LOC/DO_TASK/GO_TO_EXIT/RESTING) with difficulty-aware exploration and energy management
- [x] AIOpponent — code-driven CharacterBody2D, owns brain, handles movement and task completion
- [x] GameScene integration — spawns AI opponents, wires win condition signal
- [x] Unit tests: test_astar.gd (14 assertions), test_ai_brain.gd (26 assertions)

---

## Implementation Details

### Files Created

#### AI Logic (`scripts/ai/`)

- **`AStarPathfinder.gd`** — `RefCounted`. Entry point: `find_path(maze_data, from, to) -> Array[Vector2i]`
  returns path including both endpoints, or `[]` if invalid. Uses Manhattan distance heuristic.
  Open set stored as `Dictionary` (Vector2i → true), scanned linearly each iteration (O(n²) — fine
  for max 40×40 = 1600 cells). `get_passable_neighbors(maze_data, cell)` is public so `AIBrain`
  can build exploration frontiers without duplicating wall-reading logic.

- **`AIBrain.gd`** — `RefCounted`. Pure logic class — no scene tree dependency.
  - **`State` enum** — `EXPLORE`, `GO_TO_LOC`, `DO_TASK`, `GO_TO_EXIT`, `RESTING`. (Local to
    `AIBrain`; `Enums.AIState` is a separate enum used for serialisation.)
  - **`setup(diff, maze_data, rng)`** — assigns a random location from `maze_data.locations` as
    `_item_loc_pos` (the AI's personal "item" to find). Reads `Enums.AI_REST_THRESHOLD` and
    `Enums.AI_REST_TARGET` for this difficulty. Hard AI additionally pre-populates
    `known_uncompleted_locs` with all locations and sets `exit_known = true`.
  - **`tick(delta, grid_pos, maze_data, energy)`** — advances `task_timer` in `DO_TASK`; in
    `RESTING`, waits until `energy >= _rest_target` then restores `_pre_rest_state`; if
    `energy <= _rest_threshold` (and not `GO_TO_EXIT`), saves current state and enters `RESTING`;
    otherwise enforces state consistency (has_item + exit_known → GO_TO_EXIT; EXPLORE ↔ GO_TO_LOC
    based on `known_uncompleted_locs`), then calls `_plan_next_path` if `current_path` is empty.
  - **`on_step_reached(grid_pos, maze_data) -> bool`** — advances `current_path`, marks cell
    explored, discovers locations/exit for Easy/Medium (Hard already knows), applies Easy's 15%
    wrong-turn at junctions, returns `true` on win condition (at exit with item).
  - **`start_task(base_duration, loc_pos)`** — scales `task_timer` by `Enums.AI_TASK_MULTIPLIER[difficulty]`,
    transitions to `DO_TASK`.
  - **`on_task_complete()`** — removes `_current_task_pos` from `known_uncompleted_locs`;
    sets `has_item = true` and `GO_TO_EXIT` if the completed location was `_item_loc_pos`;
    otherwise transitions to `GO_TO_LOC` or `EXPLORE`.
  - **`on_location_completed_externally(loc_pos)`** — removes location from `known_uncompleted_locs`
    and clears `current_path` if the AI was en route there (called when the player completes a location).
  - **Exploration strategy** — builds frontier (cells adjacent via passage to explored territory
    that haven't been visited). Easy: random pick. Medium: 70% nearest, 30% random. Hard: pick
    frontier cell closest to item location or exit (directional bias).
  - **Rest thresholds (from `Enums`)**: Easy rests at ≤40 until ≥80; Medium rests at ≤20 until ≥50;
    Hard rests at ≤5 until ≥30. RESTING is skipped for `GO_TO_EXIT` state so AI always completes
    the final run regardless of energy.

#### AI Scene (`scenes/ai/`)

- **`AIOpponent.gd`** — `CharacterBody2D`. Code-driven (no `.tscn`); `_ready()` creates
  `CollisionShape2D` and `Polygon2D` (orange octagon) as children.
  - **`setup(tile_size, difficulty, ai_idx, maze_data, location_manager, renderer)`** — assigns
    collision radius, draws visual, creates `PlayerStats` and `AIBrain`. Seeds RNG as
    `maze_data.seed_val + ai_idx + 1` to differentiate opponents. Marks spawn cell as explored.
    Connects to `SignalBus.match_ended` to set `_match_over`.
  - **`_physics_process(delta)`** — checks if AI has arrived at `get_next_step()` (within
    `tile_size * 0.25` px); if so, snaps to cell centre, calls `brain.on_step_reached()`, and
    calls `_handle_location_arrival()`. Then calls `brain.tick(delta, grid_pos, maze_data, energy)`.
    Moves toward `get_next_step()` at `stats.current_speed()` (scaled by `Enums.AI_SPEED_MULTIPLIER`).
    Drains/regens energy identically to Player; energy is passed to `brain.tick()` each frame.
  - **`_handle_location_arrival(pos)`** — if location is uncompleted, calls `brain.start_task()`.
    If already completed (e.g., done by player), removes from `brain.known_uncompleted_locs`.
  - **`_complete_task()`** — calls `_location_manager.complete_location()`, emits
    `SignalBus.location_completed`, calls `brain.on_task_complete()`.
  - Emits `reached_exit_with_item` when `brain.on_step_reached()` returns `true`.

### Files Modified

- **`scripts/autoloads/Enums.gd`** — Added `AIState` enum (EXPLORE/GO_TO_LOC/DO_TASK/GO_TO_EXIT)
  and `AI_TASK_MULTIPLIER` dictionary (keyed by Difficulty int: EASY→1.5, MEDIUM→1.0, HARD→0.7).

- **`scenes/game/GameScene.gd`** — Added `_ai_opponents: Array`. In `_ready()`, reads
  `GameState.config["num_opponents"]` (default 1) and `["ai_difficulties"]` (default [EASY]),
  instantiates `AIOpponent` nodes before `add_child(_fog_renderer)` (so fog covers AI in
  unexplored areas), positions each at `_maze_data.ai_spawns[i]`, connects
  `reached_exit_with_item` → `_on_ai_reached_exit_with_item`. Added handler calls
  `_win_condition.check_ai_at_exit(true)` which emits `match_ended("ai_win")`.

- **`tests/scenes/TestRunnerScene.gd`** — Added `test_astar.gd` and `test_ai_brain.gd`.

### Architecture Decisions

- **`_item_loc_pos` instead of `LocationData.item_type` for AI** — `LocationManager` assigns
  `item_type` for the human player's perspective (PLAYER_ITEM / OPPONENT_ITEM / SIZE_INCREASER).
  The AI's "personal item" is tracked separately via `_item_loc_pos`, decoupling AI logic from
  the player-centric item type system. This avoids changing `LocationManager` and allows
  independent difficulty-based location prioritisation.

- **Code-driven `AIOpponent` (no `.tscn`)** — Consistent with Phase 5–6 pattern for game-logic
  nodes. Avoids Godot UID management for a scene that contains no authored resources.

- **AI placed before `FogRenderer` in scene tree** — Ensures fog TileMap renders on top of AI
  `Polygon2D` visuals. AI in unexplored cells is naturally hidden without any z-index management.

- **Full maze graph for A* (not fog-limited)** — AI pathfinds through the full maze graph but
  only _discovers_ locations and the exit by physically entering those cells (Easy/Medium). This
  keeps A* simple and predictable while preserving the exploration requirement. Hard AI's
  omniscience is implemented at the knowledge layer (`known_uncompleted_locs`, `exit_known`),
  not at the pathfinding layer.
