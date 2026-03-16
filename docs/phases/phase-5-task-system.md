# Phase 5: Locations & Task System

## Status: COMPLETE

## Goal
Implement the location/task system where players interact with locations to receive and complete tasks, then receive item reveals.

## Tasks
- [x] Create Location scene node placed at designated maze cells
- [x] Implement interaction trigger when player reaches a location
- [x] Create task overlay UI (displays task text + media placeholder)
- [x] Implement honor-system timer for task completion (countdown + "Done" button)
- [x] On task completion, reveal item result (player's item / opponent's item / size increaser)
- [x] Distribute items across locations at maze generation time
- [x] Ensure each player's item exists at exactly one location
- [x] Place size increasers at remaining locations
- [x] Mark locations as completed after interaction
- [x] Support default task set (bundled with game)
- [x] Load custom tasks from user data directory (Phase 11 settings)

## Dependencies
- Phase 2 (location placement in maze)
- Phase 3 (player interaction)
- Phase 4 (location visibility)

## Key Specs
- [Task Locations](../specs/task-locations.md)
- [Task Display](../specs/task-display.md)

## Implementation
Four-class design:
- `scripts/tasks/TaskData.gd` — pure data container (RefCounted)
- `scripts/tasks/TaskLoader.gd` — loads default + user JSON tasks (RefCounted)
- `scripts/tasks/LocationData.gd` — single location state (RefCounted)
- `scripts/tasks/LocationManager.gd` — owns all locations, item distribution, completion (RefCounted)
- `scripts/tasks/TaskOverlay.gd` — CanvasLayer UI, code-driven (no .tscn)

`Enums.ItemType` added: `PLAYER_ITEM`, `OPPONENT_ITEM`, `SIZE_INCREASER`.

### TaskOverlay flow
1. Player enters location cell → `show_task()` called → overlay becomes visible, timer starts, reward label hidden, "Collect" button disabled.
2. Timer counts down each `_process` frame.
3. Timer hits 0 → reward label revealed (gold text, e.g. "Reward: Size +1" / "Reward: Your Item!" / "Reward: Opponent Item") → "Collect" button enabled.
4. Player clicks "Collect" → overlay hides → `task_completed` signal fires → `GameScene._on_task_completed` applies the reward and unpauses.

### Item reward labels (`ITEM_LABELS` constant in `TaskOverlay`)
| ItemType | Label shown |
|---|---|
| `PLAYER_ITEM` | "Reward: Your Item!" |
| `OPPONENT_ITEM` | "Reward: Opponent Item" |
| `SIZE_INCREASER` | "Reward: Size +1" |

## Deliverables
- Locations interactable in maze
- Task overlay displays task title, description, media placeholder, and countdown timer
- Timer-based honor system completion
- Item reveal shown in overlay before collection (gold label appears at timer = 0)
- "Collect" button replaces "Done" — disabled until timer expires
- Size increaser applies `add_size(1)` and emits `player_size_changed`
- Player item sets `GameState.player["has_item"]` and emits `player_item_collected`
- Completed location marker turns green

## Testing Criteria
- [x] Player can interact with location to trigger task overlay
- [x] Task overlay displays text and media placeholder
- [x] Timer counts down correctly
- [x] "Collect" button only active after timer completes
- [x] Item reward label revealed when timer hits 0
- [x] Correct reward label shown per item type
- [x] Correct item type applied on collection (player item, size increaser)
- [x] Size increaser increases player size stat by 1 (capped at 10)
- [x] Completed locations visually distinct from uncompleted (yellow → green)
- [x] Each player's item is placed at exactly one location
- [x] Custom tasks load correctly from user data (user://tasks/*.json)
- [x] 22 unit tests pass for pure logic classes
