# Feature Spec: Task Locations

## Overview
Locations are special cells in the maze where players can interact to receive a task. Completing the task reveals an item.

## Location Properties
```
Location:
  - position: Vector2i
  - completed_by: Array[player_id]  # tracks who has completed this location
  - item_type: "player_item" | "opponent_item" | "size_increaser"
  - item_owner: player_id (if player_item or opponent_item)
  - task: TaskData
  - revealed: bool  # whether fog has been cleared
```

## Interaction Flow
1. Player reaches location cell
2. If player has not completed this location → trigger task overlay
3. If player has already completed this location → show "Already completed" (no re-interaction)
4. Task overlay displays (see task-display.md)
5. On completion → reveal item
6. Item is either collected (if player's) or noted (if opponent's / size increaser applied)

## Item Distribution (at maze generation)
1. For each player (including AI), assign their item to exactly one random location
2. Remaining locations get "size_increaser" items
3. Shuffle location order so item placement is unpredictable
4. If a player visits a location with an opponent's item:
   - Item is left there (marked as belonging to that opponent)
   - Player sees "This isn't your item" or similar message

## Visual States
- **Unrevealed (in fog):** not visible
- **Revealed, uncompleted:** placeholder icon (e.g., question mark)
- **Revealed, completed by player:** shows what item was found
- **Revealed, completed by another:** different visual indicator

## Testing Criteria
- [x] Each player's item placed at exactly one location
- [x] Remaining locations have size increasers
- [x] Interaction triggers task overlay on first visit
- [x] Second visit shows "already completed" (has_uncompleted_at returns false after completion)
- [x] Opponent item is left for opponent (OPPONENT_ITEM type handled in TaskOverlay)
- [x] Location visual state updates correctly (marker turns green after completion)
