# Phase 11: Settings & Customization

## Status: COMPLETE

## Goal
Implement settings screen with standard game settings and custom content management (tasks, items, clash penalties).

## Tasks

### Standard Settings
- [x] Resolution selector
- [x] Fullscreen toggle
- [x] (Sound/music volume — placeholder controls, no audio system yet)
- [x] Settings persistence (save to config file)

### Custom Tasks
- [x] Add Task UI: text description + media file path (gif/mp4/webm)
- [x] Task list management (add, edit, remove)
- [x] Store custom tasks in user data directory
- [x] Validate media files (supported formats, reasonable file size)
- [x] Custom tasks appear in location task pool

### Custom Items
- [x] Add Item UI: name + icon image path
- [x] Item list management (add, edit, remove)
- [x] Store custom items in user data directory
- [x] Custom items appear in New Game item selector

### Custom Clash Penalty Tasks
- [x] Add penalty task UI: exercise name + reps
- [x] Penalty task list management
- [x] Custom penalties selectable as clash consequence

## Dependencies
- Phase 5 (task system to integrate custom tasks)
- Phase 6 (item system to integrate custom items)
- Phase 8 (clash system for custom penalties)
- Phase 9 (settings screen shell)

## Key Specs
- [Custom Content](../specs/custom-content.md)

## Deliverables
- Settings screen with standard options
- Custom task creation and management
- Custom item creation and management
- Custom clash penalty creation
- All custom content persists and loads into game systems

## Testing Criteria
- [x] Resolution and fullscreen settings apply correctly
- [x] Settings persist across game restarts
- [x] Custom task with gif/video displays correctly in game
- [x] Custom item appears in New Game item selector
- [x] Custom clash penalty triggers correctly in clash
- [x] Invalid media files rejected with user-friendly error
- [x] Removing custom content doesn't break existing saves
- [x] Default content always available even if no custom content added
