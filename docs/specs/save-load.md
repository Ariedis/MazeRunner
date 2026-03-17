# Feature Spec: Mid-Maze Save/Load

## Status: IMPLEMENTED

## Overview
Players can save their game mid-maze from the pause menu and load from the main menu. The system supports 5 save slots with metadata, overwrite confirmation, and graceful corrupt-file handling.

## Architecture

### SaveManager (Autoload)
- Registered in `project.godot` as the 5th autoload (after Enums, SignalBus, GameState, SceneManager)
- Handles all file I/O, serialization, and slot management
- Save directory: `user://saves/`
- Files: `save_slot_1.json` through `save_slot_5.json`
- `capture_game_state()` builds the complete save dictionary from live game objects
- `arr_to_v2i()` / `arr_to_v2()` static helpers for JSON-safe vector conversion

### SaveSlotPanel (Code-Driven UI)
- `CanvasLayer` at z=30 (above all other UI)
- Supports two modes: `Mode.SAVE` and `Mode.LOAD`
- Instantiated from `GameScene` (save mode) and `MainMenu` (load mode)
- Overwrite confirmation dialog when saving to an occupied slot
- Per-slot delete button

### GameState Integration
- `queue_load(save_dict)` — stages save data and restores config/player baseline before scene transition
- `take_pending_save_data()` — consumed by `GameScene._ready()` after maze regeneration
- `has_save_data()` — delegates to `SaveManager.has_any_save()`

### GameScene Integration
- `_on_pause_save()` — opens the `SaveSlotPanel`
- `_on_save_slot_selected(slot)` — calls `SaveManager.capture_game_state()` then `SaveManager.save_game()`
- `_apply_save_data(data)` — restores all runtime state after the maze is regenerated from the saved seed

### Load Flow
1. User selects Continue (most recent) or Load Game (pick slot) from Main Menu
2. `GameState.queue_load()` restores `config` dict so maze generation uses the same seed/size
3. `SceneManager.go_to_game_scene()` transitions to `GameScene`
4. `GameScene._ready()` regenerates the identical maze from seed, spawns all objects at default positions
5. `GameScene._apply_save_data()` then overwrites positions, stats, fog, locations, AI brain state

## Save Data Schema (Actual Implementation)
```json
{
  "version": "1.0",
  "timestamp": "2026-03-17T14:30:00",
  "slot": 1,
  "data": {
    "config": {
      "map_size": 1,
      "num_opponents": 2,
      "ai_difficulties": [0, 2],
      "seed": 12345,
      "item_id": "golden_key",
      "avatar_id": 3
    },
    "maze": {
      "width": 25,
      "height": 25,
      "seed": 12345,
      "exit": [20, 22],
      "player_spawn": [0, 0],
      "ai_spawns": [[5, 5], [10, 10]],
      "locations": [[3, 7], [8, 12], [15, 3]]
    },
    "player": {
      "position": [150.5, 220.0],
      "grid_pos": [5, 8],
      "size": 3,
      "energy": 72.5,
      "has_item": true,
      "item_id": "golden_key",
      "avatar_id": 3,
      "explored_cells": [[0, 0], [0, 1], [1, 0]],
      "clash_cooldown": 0.0,
      "is_frozen": false
    },
    "opponents": [
      {
        "index": 0,
        "position": [300.0, 100.0],
        "grid_pos": [12, 3],
        "size": 2,
        "energy": 90.0,
        "difficulty": 0,
        "has_item": false,
        "state": 0,
        "explored_cells": [[5, 5], [5, 6]],
        "known_uncompleted_locs": [[8, 12]],
        "exit_known": false,
        "exit_pos": [-1, -1],
        "penalty_timer": 0.0,
        "task_timer": 0.0,
        "current_path": [[6, 6], [7, 6]],
        "clash_cooldown": 0.0,
        "_item_loc_pos": [3, 7],
        "_current_task_pos": [-1, -1],
        "_current_target": [7, 6],
        "_pre_rest_state": 0,
        "_pre_penalty_state": 0,
        "_rest_threshold": 40.0,
        "_rest_target": 80.0
      }
    ],
    "locations": [
      {
        "id": 0,
        "grid_pos": [3, 7],
        "item_type": 0,
        "completed": true,
        "completed_by": ["player"]
      },
      {
        "id": 1,
        "grid_pos": [8, 12],
        "item_type": 2,
        "completed": false,
        "completed_by": []
      }
    ],
    "elapsed_msec": 45000,
    "clash_active": false
  }
}
```

### Key Schema Notes
- All enum values stored as integers (e.g., `MapSize.MEDIUM` = 1, `AIBrain.State.EXPLORE` = 0)
- Positions stored as `[x, y]` arrays (world coordinates for positions, grid coordinates for grid_pos)
- `explored_cells` stored as arrays of `[x, y]` pairs
- AI brain internal state fully captured: `_item_loc_pos`, `_current_task_pos`, `_current_target`, `_pre_rest_state`, `_pre_penalty_state`, rest thresholds
- `elapsed_msec` tracks game time for results screen continuity

## Save Slots
- 5 slots (configurable via `SaveManager.MAX_SLOTS`)
- Each slot shows: map size (Small/Medium/Large), timestamp (YYYY-MM-DD HH:MM), locations completed / total
- Overwrite existing slot prompts for confirmation
- Corrupt slots marked as "CORRUPT" and disabled for loading but can be deleted

## Continue Button
- Loads the save with the most recent timestamp (compares ISO-8601 strings)
- Greyed out if no saves exist (`GameState.has_save_data()` returns false)

## Load Game Button
- Opens `SaveSlotPanel` in `Mode.LOAD`
- Empty slots disabled; occupied slots show metadata; corrupt slots disabled
- Selecting a slot loads the save and transitions to `GameScene`

## Error Handling
- Corrupt JSON → `_read_save_file()` returns null, slot marked as corrupt in metadata
- Empty file → returns null
- Non-Dictionary root → returns null
- Version mismatch → warning logged, data still returned (forward-compatible)
- Missing save file → slot appears empty
- Invalid slot number (< 1 or > MAX_SLOTS) → save/load returns false/null

## Files
- `scripts/save/SaveManager.gd` — Autoload, all save/load logic
- `scripts/save/SaveSlotPanel.gd` — Reusable slot selection UI (CanvasLayer z=30)
- `tests/test_save_system.gd` — 14 test functions covering all testing criteria

## Testing Criteria
- [x] Save writes complete game state to JSON
- [x] Load restores exact game state
- [x] Player position, stats, inventory correct after load
- [x] AI position, stats, state correct after load
- [x] Fog of war restored from explored cells
- [x] Location completion states restored
- [x] Continue loads most recent save
- [x] Corrupt file handled gracefully
- [x] Overwrite prompts for confirmation
