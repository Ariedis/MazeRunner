# Phase 5: Locations & Task System

## Status: NOT STARTED

## Goal
Implement the location/task system where players interact with locations to receive and complete tasks, then receive item reveals.

## Tasks
- [ ] Create Location scene node placed at designated maze cells
- [ ] Implement interaction trigger when player reaches a location
- [ ] Create task overlay UI (displays task text + gif/mp4/webm)
- [ ] Implement honor-system timer for task completion (countdown + "Done" button)
- [ ] On task completion, reveal item result (player's item / opponent's item / size increaser)
- [ ] Distribute items across locations at maze generation time
- [ ] Ensure each player's item exists at exactly one location
- [ ] Place size increasers at remaining locations
- [ ] Mark locations as completed after interaction
- [ ] Support default task set (bundled with game)
- [ ] Load custom tasks from user data directory (Phase 11 settings)

## Dependencies
- Phase 2 (location placement in maze)
- Phase 3 (player interaction)
- Phase 4 (location visibility)

## Key Specs
- [Task Locations](../specs/task-locations.md)
- [Task Display](../specs/task-display.md)

## Deliverables
- Locations interactable in maze
- Task overlay displays with media
- Timer-based honor system completion
- Items revealed after task completion
- Size increaser works correctly

## Testing Criteria
- [ ] Player can interact with location to trigger task overlay
- [ ] Task overlay displays text and media (gif/video)
- [ ] Timer counts down correctly
- [ ] "Done" button only active after timer completes
- [ ] Correct item type revealed (player item, opponent item, size increaser)
- [ ] Size increaser increases player size stat by 1 (capped at 10)
- [ ] Completed locations visually distinct from uncompleted
- [ ] Each player's item is placed at exactly one location
- [ ] Custom tasks load correctly from user data
