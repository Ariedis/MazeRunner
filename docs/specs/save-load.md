# Feature Spec: Mid-Maze Save/Load

## Overview
Players can save their game mid-maze from the pause menu and load from the main menu.

## Save Data Schema
```json
{
  "version": "1.0",
  "timestamp": "ISO-8601",
  "slot": 1,
  "config": {
    "map_size": "medium",
    "seed": 12345,
    "num_opponents": 2,
    "ai_difficulties": ["easy", "hard"]
  },
  "maze": {
    "width": 25,
    "height": 25,
    "exit_position": [20, 22]
  },
  "player": {
    "position": [5, 8],
    "size": 3,
    "energy": 72.5,
    "has_item": false,
    "item_id": "golden_key",
    "explored_cells": [[0,0], [0,1], [1,0], ...],
    "avatar_id": "avatar_03"
  },
  "opponents": [
    {
      "id": "ai_1",
      "position": [12, 3],
      "size": 2,
      "energy": 90.0,
      "has_item": false,
      "state": "EXPLORE",
      "explored_cells": [...],
      "difficulty": "easy"
    }
  ],
  "locations": [
    {
      "position": [3, 7],
      "completed_by": ["player"],
      "item_type": "size_increaser"
    }
  ]
}
```

## Save Slots
- Multiple slots (suggest 5-10)
- Each slot shows: timestamp, map size, locations completed / total
- Overwrite existing slot requires confirmation

## Continue Button
- Loads the save with the most recent timestamp
- Greyed out if no saves exist

## Error Handling
- Corrupt JSON → show error, don't crash, mark slot as corrupt
- Version mismatch → show warning, attempt load or reject gracefully
- Missing save file → slot appears empty

## File Location
- Godot `user://` data directory
- Files: `save_slot_1.json`, `save_slot_2.json`, etc.

## Testing Criteria
- [ ] Save writes complete game state to JSON
- [ ] Load restores exact game state
- [ ] Player position, stats, inventory correct after load
- [ ] AI position, stats, state correct after load
- [ ] Fog of war restored from explored cells
- [ ] Location completion states restored
- [ ] Continue loads most recent save
- [ ] Corrupt file handled gracefully
- [ ] Overwrite prompts for confirmation
