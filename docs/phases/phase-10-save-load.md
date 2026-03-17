# Phase 10: Save & Load System

## Status: COMPLETE

## Goal
Implement mid-maze save and load with multiple save slots.

## Tasks
- [x] Define save data schema (JSON or Godot Resource):
  - Maze seed + generation parameters
  - Player position, stats, inventory, explored cells
  - AI positions, stats, inventory, internal state
  - Location states (completed/uncompleted, item assignments)
  - Exit position and discovery state
  - Game config (map size, difficulty, etc.)
  - Timestamp and slot metadata
- [x] Implement save serialization
- [x] Implement save deserialization / game state reconstruction
- [x] Save to file system (user data directory)
- [x] Multiple save slots
- [x] Save from pause menu
- [x] Load Game screen: list saves with metadata (date, map size, progress)
- [x] Continue button: load most recent save
- [x] Delete save option
- [x] Handle corrupt/incompatible save files gracefully

## Dependencies
- Phase 1 (global state)
- Phases 2-8 (all game state to serialize)

## Key Specs
- [Save/Load](../specs/save-load.md)

## Deliverables
- Save game from pause menu into slot
- Load game from menu restores full state
- Continue resumes most recent save
- Corrupt saves handled gracefully

## Testing Criteria
- [x] Save captures complete game state
- [x] Load restores game to exact saved state (player pos, stats, fog, AI)
- [x] Multiple save slots work independently
- [x] Continue loads the most recent save
- [x] Corrupt save file shows error, doesn't crash
- [x] Save file size reasonable for Large maps
- [x] Load time acceptable (<2s)
- [x] Saving during task/clash overlay works correctly
