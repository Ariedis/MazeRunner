# Phase 7: AI Opponents

## Status: NOT STARTED

## Goal
Implement AI-controlled opponents that navigate the maze, complete tasks at locations, collect their items, and race to the exit.

## Tasks
- [ ] Create AI character scene (same base as player, different controller)
- [ ] Implement A* pathfinding on maze graph
- [ ] AI state machine: Explore → Go to Location → Wait at Location (simulate task) → Search for Item → Go to Exit
- [ ] AI exploration: pick unexplored paths, build internal map
- [ ] AI task simulation: wait at location for a duration (simulates task completion)
- [ ] AI item awareness: know when they've found their item
- [ ] AI exit-seeking: once item collected, pathfind to exit
- [ ] Implement difficulty levels affecting AI behavior:
  - Easy: slower decision-making, suboptimal pathing, longer task wait
  - Medium: balanced pathing, moderate task wait
  - Hard: optimal pathing, short task wait, prioritizes efficient routes
- [ ] AI collision with player triggers clash (Phase 8)
- [ ] Support configurable number of opponents (1-N, based on map size)
- [ ] AI respects fog of war for its own exploration (doesn't cheat on Easy/Medium)

## Dependencies
- Phase 2 (maze structure for pathfinding)
- Phase 3 (character base scene)
- Phase 5 (location/task interaction)

## Key Specs
- [AI Pathfinding](../specs/ai-pathfinding.md)
- [AI Difficulty](../specs/ai-difficulty.md)

## Deliverables
- AI opponents navigate the maze autonomously
- AI completes tasks and collects items
- AI races to exit after item collection
- Difficulty levels produce noticeably different behavior

## Testing Criteria
- [ ] AI navigates maze without getting stuck
- [ ] AI visits locations and simulates task completion
- [ ] AI collects its item when found
- [ ] AI pathfinds to exit after item collection
- [ ] Easy AI is noticeably slower/less efficient than Hard
- [ ] Multiple AI opponents don't interfere with each other's pathing
- [ ] AI triggers clash when colliding with player
- [ ] AI doesn't cheat (no fog-penetrating knowledge on Easy/Medium)
- [ ] Hard AI may have partial fog cheating (design decision per difficulty spec)
