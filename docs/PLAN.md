# Maze Battle - Implementation Plan

## Overview
**Game:** Maze Battle
**Engine:** Godot 4 (2D)
**Premise:** Players navigate a procedurally generated maze competing against AI opponents. Each competitor must find their item at task locations and reach the exit first.

---

## Phase Tracker

| Phase | Name | Status | Specs |
|-------|------|--------|-------|
| 1 | Project Setup & Core Infrastructure | COMPLETE | [spec](phases/phase-1-project-setup.md) |
| 2 | Maze Generation & Rendering | COMPLETE | [spec](phases/phase-2-maze-generation.md) |
| 3 | Player Movement & Mechanics | COMPLETE | [spec](phases/phase-3-player-mechanics.md) |
| 4 | Fog of War & Exploration | COMPLETE | [spec](phases/phase-4-fog-of-war.md) |
| 5 | Locations & Task System | COMPLETE | [spec](phases/phase-5-task-system.md) |
| 6 | Item System & Win Condition | COMPLETE | [spec](phases/phase-6-item-system.md) |
| 7 | AI Opponents | COMPLETE | [spec](phases/phase-7-ai-opponents.md) |
| 8 | Clash System | COMPLETE | [spec](phases/phase-8-clash-system.md) |
| 9 | UI & Menus | COMPLETE | [spec](phases/phase-9-ui-menus.md) |
| 10 | Save & Load System | NOT STARTED | [spec](phases/phase-10-save-load.md) |
| 11 | Settings & Customization | NOT STARTED | [spec](phases/phase-11-settings.md) |
| 12 | Polish & Integration | NOT STARTED | [spec](phases/phase-12-polish.md) |

---

## Feature Specs

| Feature | Spec | Phase |
|---------|------|-------|
| Procedural Maze Generation | [spec](specs/maze-generation.md) | 2 |
| Map Sizes (S/M/L) | [spec](specs/map-sizes.md) | 2 |
| Player Stats (Size/Speed/Energy) | [spec](specs/player-stats.md) | 3 |
| Energy & Movement | [spec](specs/energy-movement.md) | 3 |
| Fog of War | [spec](specs/fog-of-war.md) | 4 |
| Task Locations | [spec](specs/task-locations.md) | 5 |
| Task Display & Completion | [spec](specs/task-display.md) | 5 |
| Item Collection | [spec](specs/item-collection.md) | 6 |
| Exit Discovery & Win | [spec](specs/exit-win.md) | 6 |
| AI Pathfinding | [spec](specs/ai-pathfinding.md) | 7 |
| AI Difficulty Levels | [spec](specs/ai-difficulty.md) | 7 |
| Clash Mechanic | [spec](specs/clash-mechanic.md) | 8 |
| Clash Task (Loser Penalty) | [spec](specs/clash-task.md) | 8 |
| Character Creator | [spec](specs/character-creator.md) | 9 |
| Main Menu & Screens | [spec](specs/main-menu.md) | 9 |
| HUD & Game UI | [spec](specs/hud.md) | 9 |
| Mid-Maze Save/Load | [spec](specs/save-load.md) | 10 |
| Custom Tasks & Items | [spec](specs/custom-content.md) | 11 |

---

## Architecture Notes

### Key Design Decisions
- **Maze Algorithm:** Recursive backtracker (DFS), implemented iteratively (no recursion limit) — produces good mazes with single solution paths
- **Rendering:** TileMap-based corridor-grid expansion — `(2W+1)×(2H+1)` tile grid encodes cells and passages, filled then carved. Programmatic `ImageTexture` TileSet (no external art assets in Phases 1–6)
- **Wall Collision:** `StaticBody2D` with one `CollisionShape2D` per wall tile — programmatic TileSet physics layers proved unreliable in Godot 4 at runtime; explicit StaticBody2D uses only standard 2D physics. All collision shapes share a single `RectangleShape2D` instance
- **Player Motion:** `MOTION_MODE_FLOATING` on `CharacterBody2D` — avoids platformer-style floor-snapping in a top-down view
- **Fog of War:** Two-TileMap approach: `FogRenderer` adds a second black-tiled TileMap as a scene child *after* location/exit marker layers, so the draw order naturally hides markers until fog is cleared. Fog state stored as `Dictionary` (Vector2i → true) for O(1) lookup; only newly-revealed cells passed to the renderer each frame
- **AI Navigation:** A* pathfinding on maze graph; `AIBrain` state machine (EXPLORE/GO_TO_LOC/DO_TASK/GO_TO_EXIT/RESTING/PENALTY) with difficulty controlling exploration strategy, movement speed (0.8×/1.0×/1.2×), task wait (1.5×/1.0×/0.7×), and energy rest thresholds (40→80 / 20→50 / 5→30). Hard AI has full omniscience (all locations + exit known from start). Easy/Medium discover locations and exit by physical contact only.
- **Clash System:** Player (collision layer 2) and AI (layer 4) use non-overlapping masks so they phase through each other — no blocking. Clash triggers are distance-based: `GameScene._check_clashes()` checks all character pairs every frame. Player-AI clashes show `ClashOverlay`; AI-AI clashes resolve instantly. Both characters receive a cooldown equal to `CLASH_COOLDOWN_SECONDS + penalty_duration` after a clash. `ClashResolver` is a pure-logic class (static methods) for dice rolling and penalty parameter lookup.
- **Save Format:** JSON serialization of full game state *(Phase 10)*
- **Code-Driven UI:** All UI elements (overlays, HUD, menus) are built entirely in GDScript with no `.tscn` node hierarchies — reduces scene-file maintenance and keeps layout logic version-controlled alongside logic. `TaskOverlay`, `ResultsScreen`, `ClashOverlay` (Phases 5–8), `GameHUD`, `PauseMenu`, and `NewGameScreen` (Phase 9) all follow this pattern.
- **Scene Management:** Container-swap pattern — all scenes load into a `SceneContainer` node inside `Main.tscn`; autoloads (Enums → SignalBus → GameState → SceneManager) remain alive across every transition
- **HUD & Pause:** `GameHUD` (CanvasLayer z=5) owns the portrait, stat labels, energy bar, and item indicator. `PauseMenu` (CanvasLayer z=10) is toggled by `GameScene._unhandled_input()` on Escape; blocked while task/clash overlays are active. CanvasLayer z-ordering: HUD (5) → PauseMenu (10) → ClashOverlay (15) → ResultsScreen (20) → TaskOverlay (highest).
- **Character Creator Logic:** `CharacterCreatorLogic` (pure `RefCounted`) manages stat allocation with budget constraints independently of any UI node — keeps logic unit-testable without a running scene.
- **New Game Config Validation:** `NewGameConfig` (static methods on `RefCounted`) validates the config dict before `GameState` is written — item selected, opponent count in bounds, difficulty array length matches opponent count.
- **GameState `item_id`:** Stored as a `String` (e.g. `"golden_key"`) matching `ItemRegistry` IDs. Default is `""` (empty = not set). Previously was `-1` (int) — changed in Phase 9 to align with `ItemRegistry`.
- **Phase 10 Stubs:** `GameState.has_save_data()` returns `false`; Main Menu Continue/Load Game buttons are disabled; `PauseMenu` Save Game emits a signal with no handler — all wired up in Phase 10.

### Suggested Additional Features (Future)
- **Power-ups:** Temporary speed boost, energy refill, reveal nearby area
- **Traps:** Placeable by players to slow opponents
- **Spectator mode:** Watch AI opponents after completing your run
- **Maze themes/biomes:** Visual variety per map section
- **Leaderboard:** Track best completion times per map size
- **Multiplayer (local/online):** Replace AI with human opponents
- **Difficulty modifiers:** Fog density, task time limits, clash frequency
- **Maze hazards:** Dead-end traps, teleporters, one-way doors
