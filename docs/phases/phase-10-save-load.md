# Phase 10: Save & Load System

## Status: NOT STARTED

## Goal
Implement mid-maze save and load with multiple save slots.

## Tasks
- [ ] Define save data schema (JSON or Godot Resource):
  - Maze seed + generation parameters
  - Player position, stats, inventory, explored cells
  - AI positions, stats, inventory, internal state
  - Location states (completed/uncompleted, item assignments)
  - Exit position and discovery state
  - Game config (map size, difficulty, etc.)
  - Timestamp and slot metadata
- [ ] Implement save serialization
- [ ] Implement save deserialization / game state reconstruction
- [ ] Save to file system (user data directory)
- [ ] Multiple save slots
- [ ] Save from pause menu
- [ ] Load Game screen: list saves with metadata (date, map size, progress)
- [ ] Continue button: load most recent save
- [ ] Delete save option
- [ ] Handle corrupt/incompatible save files gracefully

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
- [ ] Save captures complete game state
- [ ] Load restores game to exact saved state (player pos, stats, fog, AI)
- [ ] Multiple save slots work independently
- [ ] Continue loads the most recent save
- [ ] Corrupt save file shows error, doesn't crash
- [ ] Save file size reasonable for Large maps
- [ ] Load time acceptable (<2s)
- [ ] Saving during task/clash overlay works correctly
