# Phase 11: Settings & Customization

## Status: NOT STARTED

## Goal
Implement settings screen with standard game settings and custom content management (tasks, items, clash penalties).

## Tasks

### Standard Settings
- [ ] Resolution selector
- [ ] Fullscreen toggle
- [ ] (Sound/music volume — deferred, placeholder controls)
- [ ] Settings persistence (save to config file)

### Custom Tasks
- [ ] Add Task UI: text description + media file picker (gif/mp4/webm)
- [ ] Task list management (add, edit, remove)
- [ ] Store custom tasks in user data directory
- [ ] Validate media files (supported formats, reasonable file size)
- [ ] Custom tasks appear in location task pool

### Custom Items
- [ ] Add Item UI: name + asset image picker
- [ ] Item list management (add, edit, remove)
- [ ] Store custom items in user data directory
- [ ] Custom items appear in New Game item selector

### Custom Clash Penalty Tasks
- [ ] Add penalty task UI: description + scaling rules
- [ ] Penalty task list management
- [ ] Custom penalties selectable as clash consequence

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
- [ ] Resolution and fullscreen settings apply correctly
- [ ] Settings persist across game restarts
- [ ] Custom task with gif/video displays correctly in game
- [ ] Custom item appears in New Game item selector
- [ ] Custom clash penalty triggers correctly in clash
- [ ] Invalid media files rejected with user-friendly error
- [ ] Removing custom content doesn't break existing saves
- [ ] Default content always available even if no custom content added
