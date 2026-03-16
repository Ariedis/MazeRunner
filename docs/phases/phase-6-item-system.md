# Phase 6: Item System & Win Condition

## Status: COMPLETE

## Goal
Implement item collection, exit discovery, and win/loss condition logic.

## Tasks
- [x] Implement item pickup — when task reveals player's item, add to inventory
- [x] Track item collection state per player (has item / doesn't have item)
- [x] HUD indicator for item collected (label updated on player_item_collected signal)
- [x] Implement exit node in maze (hidden until discovered via fog)
- [x] Exit interaction: if player has item, trigger win
- [x] Exit interaction: if player doesn't have item, show message ("You need your item to exit!")
- [x] Win screen — display winner, stats summary (time, cells explored, size)
- [x] Loss detection — AI reaches exit with their item before player (via match_ended signal)
- [x] Loss screen with stats
- [x] Handle edge case: player finds opponent's item (OPPONENT_ITEM type in TaskOverlay)

## Dependencies
- Phase 5 (task completion reveals items) ✓
- Phase 4 (exit hidden in fog) ✓
- Phase 7 (AI can also win) — AI win triggered via SignalBus.match_ended("ai_win")

## Key Specs
- [Item Collection](../specs/item-collection.md)
- [Exit & Win](../specs/exit-win.md)

## Deliverables
- [x] ItemData data class
- [x] ItemRegistry with 5 default items, custom item support
- [x] WinConditionManager with player/AI exit checks
- [x] ResultsScreen (win/loss overlay with stats and navigation buttons)
- [x] Exit marker (cyan star shape, visible when fog removed)
- [x] Exit detection wired into GameScene._process
- [x] Rejection message on exit without item
- [x] Unit tests (test_item_system.gd): 15 tests covering ItemData, ItemRegistry, WinConditionManager

## Testing Criteria
- [x] Player receives item after task reveals it as theirs
- [x] Item indicator shows on HUD after collection
- [x] Exit is interactable only when discovered (player must physically reach cell to reveal fog)
- [x] Player with item entering exit triggers win
- [x] Player without item entering exit gets rejection message
- [x] AI winning triggers player loss screen (via match_ended signal)
- [x] Opponent items left at location for opponent to find (OPPONENT_ITEM type handled in TaskOverlay)
- [x] Win/loss screens display correctly with stats

---

## Implementation Details

### Files Created

#### Item Layer (`scripts/items/`)

- **`ItemData.gd`** — `RefCounted`. Pure data class with no scene dependency. Fields: `id: String`,
  `name: String`, `is_custom: bool` (default false).

- **`ItemRegistry.gd`** — `RefCounted`. Manages the full item catalogue. Initialised in `_init()`
  with 5 built-in items: `golden_key`, `crystal_orb`, `ancient_scroll`, `dragon_scale`,
  `phoenix_feather`.
  - **`get_all() -> Array[ItemData]`** — returns `_items.duplicate()` so external callers cannot
    mutate the internal array.
  - **`get_item(id) -> ItemData`** — linear scan by id; returns `null` if not found.
  - **`add_custom(id, item_name)`** — creates an `ItemData` with `is_custom = true` and appends it.
    Custom items are retrievable via `get_item()` and `get_all()` immediately.
  - **`count() -> int`** — returns `_items.size()`.

- **`WinConditionManager.gd`** — `RefCounted`. Stateless; all logic is a pure function of its
  argument plus a `SignalBus` emit side-effect.
  - **`Result` enum** — `NONE = 0`, `PLAYER_WIN`, `AI_WIN`.
  - **`check_player_at_exit(has_item) -> int`** — returns `PLAYER_WIN` and emits
    `SignalBus.match_ended("player_win")` when `has_item` is true; returns `NONE` otherwise.
  - **`check_ai_at_exit(ai_has_item) -> int`** — returns `AI_WIN` and emits
    `SignalBus.match_ended("ai_win")` when `ai_has_item` is true; returns `NONE` otherwise.

#### Game Screens (`scenes/game/`)

- **`ResultsScreen.gd`** — `CanvasLayer` (layer = 20, above `TaskOverlay` at layer 10). Entirely
  code-driven — no `.tscn`. Built in `_ready()`: centred 500×360 `Panel` with a `VBoxContainer`
  containing `LabelTitle` (32pt), `LabelTime` (18pt), `LabelLocations` (18pt), `LabelSize` (18pt),
  a spacer, `BtnPlayAgain`, and `BtnMainMenu`. Starts hidden (`visible = false`).
  - **`show_win(time_sec, locations_explored, final_size)`** — sets title to "You Win!" in green,
    fills stats, makes panel visible.
  - **`show_loss(winner_name, time_sec, locations_explored, final_size)`** — sets title to
    `"{winner_name} Wins!"` in red, fills stats, makes panel visible.
  - **`_fill_stats`** — formats time as `M:SS`, displays explored cell count and final size.
  - Emits `play_again_requested` / `main_menu_requested` signals on button press.

#### Tests (`tests/`)

- **`test_item_system.gd`** — 15 assertions across: `ItemData` default fields (3); `ItemRegistry`
  default count (1), all have non-empty ids (1), all have non-empty names (1), none are custom by
  default (1), `get_item` by valid id (2), `get_item` by invalid id returns null (1), `add_custom`
  increments count (1), `add_custom` sets `is_custom` flag (2), `get_all` returns a copy that
  doesn't affect the registry (1); `WinConditionManager` player with/without item (2), AI
  with/without item (2).

### Files Modified

- **`scenes/game/GameScene.gd`** — Major additions for Phase 6:
  - New instance vars: `_win_condition: WinConditionManager`, `_results_screen: ResultsScreen`,
    `_start_time_msec: int`, `_match_over: bool`, `_label_rejection: Label`.
  - In `_ready()`: instantiates `ResultsScreen`, connects its `play_again_requested` →
    `_on_play_again` and `main_menu_requested` → `SceneManager.go_to_main_menu`; instantiates
    `WinConditionManager`; connects `SignalBus.match_ended` → `_on_match_ended`; connects
    `SignalBus.player_item_collected` → `_on_player_item_collected`; creates rejection `Label`
    in code (anchored top-wide, offset_top 60, red text) and adds it to the UI `CanvasLayer`.
    Records `_start_time_msec = Time.get_ticks_msec()` at the end of setup.
  - **`_spawn_exit_marker(tile_size)`** — creates a cyan 8-pointed star `Polygon2D`
    (outer radius `tile_size * 0.45`, every other vertex at 50% inner radius) at the exit grid
    position. Added to `ExitLayer` node *before* `FogRenderer` in `_ready()`, so the fog
    TileMap naturally renders on top and hides the marker until the player's fog clears.
  - **`_handle_exit_interaction()`** — called from `_process()` when player's grid cell equals
    `_maze_data.exit`. Delegates to `_win_condition.check_player_at_exit(has_item)`. If result
    is `NONE`, calls `_show_rejection_message("You need your item to exit!")`.
  - **`_show_rejection_message(msg)`** — sets label text, makes it visible, attaches a 2.5s
    `SceneTreeTimer` whose `timeout` hides the label.
  - **`_on_task_completed`** — updated to handle `PLAYER_ITEM`: sets
    `GameState.player["has_item"] = true` and `item_id`, emits `SignalBus.player_item_collected`.
  - **`_on_match_ended(result)`** — guarded by `_match_over` to prevent double-firing. Sets
    `GameState.current_state = GAME_OVER`, calculates elapsed seconds from `_start_time_msec`,
    calls `_results_screen.show_win()` or `show_loss("Opponent", ...)` accordingly.
  - **`_on_play_again()`** — calls `GameState.reset_for_new_game()` then
    `SceneManager.go_to_game_scene()`.

- **`scenes/game/GameScene.tscn`** — Added `LabelItem` to the UI `CanvasLayer` (shows "Item:
  Collected!" after `player_item_collected` signal).

- **`tests/scenes/TestRunnerScene.gd`** — Added `"res://tests/test_item_system.gd"` to
  `TEST_CLASSES`.

### Architecture Decisions

- **`WinConditionManager` as a stateless `RefCounted`**: The win condition is a pure function of
  whether the exiting entity has their item. No persistent state needed. Keeping it stateless and
  side-effect-free (beyond the signal emit) makes it trivially testable and easy to extend for
  Phase 7 AI checks.

- **`ResultsScreen` as code-driven `CanvasLayer` (no `.tscn`)**: Consistent with Phase 5's
  `TaskOverlay` approach — mid-game overlay UIs are built in GDScript to reduce `.tscn` file
  count during the gameplay phases. Both will be revisited with theming in Phase 9 (UI & Menus).

- **`_match_over` guard on `_on_match_ended`**: `SignalBus.match_ended` could be emitted more
  than once if a play-again reload races with an in-flight signal. The boolean gate ensures the
  results screen is only shown once and `GameState` is only set to `GAME_OVER` once per match.

- **`_start_time_msec` via `Time.get_ticks_msec()`**: Monotonic millisecond clock unaffected by
  system time changes. Timer started at the end of `_ready()` after all scene setup is complete.

- **Exit and location markers placed before `FogRenderer` in scene tree**: `GameScene._ready()`
  adds `LocationLayer` and `ExitLayer` before `add_child(_fog_renderer)`. Since Godot 2D draws
  children in order, the `FogRenderer` TileMap always renders on top of all markers —
  no z-index manipulation required. Erasing fog tiles naturally unmasks the markers below.
