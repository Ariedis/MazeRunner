# Feature Spec: AI Pathfinding

## Overview
AI opponents navigate the maze autonomously using A* pathfinding on the maze graph. AI builds its own explored map (respects fog of war).

## Pathfinding
- **Algorithm:** A* on maze cell graph
- **Graph:** cells are nodes, open passages are edges
- **Heuristic:** Manhattan distance (grid-based maze)
- **Path recalculation:** when target changes or path is blocked by clash

## AI State Machine
```
States:
  EXPLORE     → pick an unexplored direction, move toward it
  GO_TO_LOC   → pathfind to nearest known uncompleted location
  DO_TASK     → wait at location (simulating task completion)
  SEARCH      → continue exploring (item not yet found)
  GO_TO_EXIT  → pathfind to exit (if discovered), else explore
  CLASH       → in clash resolution (frozen)
  PENALTY     → performing clash penalty (frozen for duration)

Transitions:
  EXPLORE → GO_TO_LOC   (when a location is discovered)
  GO_TO_LOC → DO_TASK   (when location reached)
  DO_TASK → SEARCH      (when task done, item not player's)
  DO_TASK → GO_TO_EXIT  (when task done, item is player's)
  SEARCH → GO_TO_LOC    (when another location discovered)
  SEARCH → EXPLORE      (when no known uncompleted locations)
  GO_TO_EXIT → EXPLORE  (if exit not yet discovered, keep exploring)
  Any → CLASH           (on collision with another character)
  CLASH → PENALTY       (if clash lost)
  CLASH → previous      (if clash won)
  PENALTY → previous    (when penalty timer done)
```

## Exploration Strategy
- AI picks unexplored passages using depth-first or breadth-first approach
- AI remembers its own explored cells (separate from player's fog)
- AI does not know the full maze layout (except on Hard — see ai-difficulty.md)

## Movement
- AI moves at same base speed as player
- AI energy system works identically to player
- AI can enter half-speed when energy depleted
- AI may choose to rest (stand still) to regen energy — smarter AI does this more strategically

## Testing Criteria
- [ ] A* produces valid paths through maze
- [ ] AI never walks through walls
- [ ] AI state transitions follow defined rules
- [ ] AI explores unknown areas when no targets known
- [ ] AI pathfinds to locations when discovered
- [ ] AI pathfinds to exit when item collected and exit known
- [ ] AI handles energy drain/regen
