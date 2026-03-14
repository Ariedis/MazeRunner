# Phase 1: Project Setup & Core Infrastructure

## Status: COMPLETE (2026-03-15)

## Goal
Establish the Godot 4 project structure, scene hierarchy, autoloads, and foundational systems that all other phases depend on.

## Tasks
- [x] Create Godot 4 project with correct settings (2D, pixel snap if needed)
- [x] Set up folder structure: `scenes/`, `scripts/`, `resources/`, `assets/`, `themes/`, `data/`
- [x] Create scene manager / scene transition system (autoload)
- [x] Create global game state singleton (autoload) — holds current game config, player data, match state
- [x] Create signal bus singleton (autoload) — centralized signal routing
- [x] Create base enums/constants file (map sizes, difficulty levels, game states)
- [x] Set up default project settings (window size, stretch mode, input map)
- [x] Define input actions: move_up, move_down, move_left, move_right, interact, pause
- [x] Create placeholder main scene that loads into main menu

## Dependencies
None — this is the foundation phase.

## Deliverables
- Runnable Godot project that launches to a placeholder main menu
- Scene transition system working (can switch between placeholder scenes)
- Global state accessible from any script
- Input map configured

## Testing Criteria
- [x] Project opens in Godot 4 without errors
- [x] Scene transitions work between 2+ placeholder scenes
- [x] Global state is readable/writable from multiple scripts
- [x] Input actions fire correctly for keyboard
- [x] No orphan nodes or memory leaks on scene transitions

---

## Implementation Details

### Files Created

#### Project Config
- **`project.godot`** — 1280×720, canvas_items stretch, pixel snap, 4 autoloads registered in
  dependency order (Enums → SignalBus → GameState → SceneManager), 6 input actions with WASD +
  arrow key bindings (move_up/down/left/right), E (interact), Escape (pause).

#### Autoloads (`scripts/autoloads/`)
- **`Enums.gd`** — Pure data singleton. Defines `GameState` (7 values), `MapSize` (3 values),
  `Difficulty` (3 values) enums. `MAP_SIZE_DATA` dictionary keyed by `MapSize` with grid dimensions,
  location counts, max opponents, and cell pixel size for each size. Constants: `MIN_SIZE=1`,
  `MAX_SIZE=10`, `CREATOR_BUDGET=3`, `STARTING_ENERGY=100.0`, `ENERGY_DRAIN=1.0`,
  `ENERGY_REGEN=2.0`, `FULL_SPEED=150.0`, `HALF_SPEED=75.0`.

- **`SignalBus.gd`** — Centralized signal hub. Phase 1 signals: `scene_change_requested`,
  `scene_changed`, `scene_transition_started`, `game_state_changed`, `game_config_changed`.
  Phase 3+ stubs: `player_energy_changed`, `player_size_changed`, `player_item_collected`,
  `location_completed`, `match_ended`.

- **`GameState.gd`** — Mutable global state. `current_state` uses a property setter that
  auto-emits `SignalBus.game_state_changed(old, new)`. Holds `config`, `player`, and `match_state`
  dictionaries. Methods: `reset_for_new_game()`, `apply_save_data()` (Phase 10 stub),
  `is_in_match()`.

- **`SceneManager.gd`** — Container-swap pattern. Scenes load into a child `Node` of `Main.tscn`
  rather than replacing the root scene tree, keeping autoloads alive across transitions. Uses
  `queue_free()` (not `free()`) on old children to prevent same-frame access errors. Path constants
  for MainMenu, PlaceholderA, PlaceholderB. Connects to `SignalBus.scene_change_requested` in
  `_ready()`.

#### Scenes
- **`scenes/main/Main.tscn` + `Main.gd`** — Persistent root scene. Registers `SceneContainer`
  with SceneManager and boots to MainMenu.
- **`scenes/menus/MainMenu.tscn` + `MainMenu.gd`** — Phase 1 placeholder menu with "MAZE BATTLE"
  title and buttons for Placeholder A, Placeholder B, and Quit. Sets `GameState.current_state =
  MENU` on ready.
- **`scenes/placeholders/PlaceholderA.tscn` + `PlaceholderA.gd`** — Links to Placeholder B and
  Main Menu.
- **`scenes/placeholders/PlaceholderB.tscn` + `PlaceholderB.gd`** — Links to Placeholder A and
  Main Menu.

#### Tests (`tests/`)
- **`TestBase.gd`** — Lightweight test framework (no external dependencies). Tracks pass/fail
  counts, prints results, calls `push_warning()` on failures so they appear in Godot's Output panel.
- **`test_enums.gd`** — Covers all enum values, all MAP_SIZE_DATA entries, and all 8 constants.
- **`test_game_state.gd`** — Covers default state, state write/read, signal emission with correct
  old/new values, `reset_for_new_game()`, config key presence, `is_in_match()` for MENU/IN_GAME/PAUSED.
- **`test_signal_bus.gd`** — Covers `scene_change_requested`, `scene_transition_started`, and
  `game_state_changed` emit/receive using Godot 4 lambda callables.
- **`test_scene_manager.gd`** — Covers path constant non-emptiness, `_scene_container` is a set
  Node, `scene_change_requested` has at least one connection.
- **`scenes/TestRunnerScene.tscn` + `TestRunnerScene.gd`** — CI-ready runner. Loads all four test
  scripts, prints consolidated report, exits with code 1 on any failure.

### Architecture Decisions
- **Container-swap pattern** for SceneManager: the `SceneContainer` node inside `Main.tscn` is
  the parent for all loaded scenes. Autoloads are never reloaded, so their signal connections and
  state survive every transition.
- **Autoload load order** matters: `Enums` must be first (no dependencies), then `SignalBus`
  (used by GameState and SceneManager), then `GameState` (uses SignalBus), then `SceneManager`
  (uses both).
- **`queue_free()` over `free()`** in SceneManager: prevents crashes when deferred callbacks or
  physics queries still reference the outgoing scene node in the same frame.
