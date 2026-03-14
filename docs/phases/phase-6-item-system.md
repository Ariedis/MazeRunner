# Phase 6: Item System & Win Condition

## Status: NOT STARTED

## Goal
Implement item collection, exit discovery, and win/loss condition logic.

## Tasks
- [ ] Implement item pickup — when task reveals player's item, add to inventory
- [ ] Track item collection state per player (has item / doesn't have item)
- [ ] HUD indicator for item collected (top-right of portrait)
- [ ] Implement exit node in maze (hidden until discovered via fog)
- [ ] Exit interaction: if player has item, trigger win
- [ ] Exit interaction: if player doesn't have item, show message ("You need your item!")
- [ ] Win screen — display winner, stats summary
- [ ] Loss detection — AI reaches exit with their item before player
- [ ] Loss screen with stats
- [ ] Handle edge case: player finds opponent's item (left for opponent, shown as different visual)

## Dependencies
- Phase 5 (task completion reveals items)
- Phase 4 (exit hidden in fog)
- Phase 7 (AI can also win)

## Key Specs
- [Item Collection](../specs/item-collection.md)
- [Exit & Win](../specs/exit-win.md)

## Deliverables
- Items collectable from task locations
- Exit discoverable and functional
- Win/loss conditions trigger correctly
- Results screen displays

## Testing Criteria
- [ ] Player receives item after task reveals it as theirs
- [ ] Item indicator shows on HUD after collection
- [ ] Exit is interactable only when discovered
- [ ] Player with item entering exit triggers win
- [ ] Player without item entering exit gets rejection message
- [ ] AI winning triggers player loss screen
- [ ] Opponent items left at location for opponent to find
- [ ] Win/loss screens display correctly with stats
