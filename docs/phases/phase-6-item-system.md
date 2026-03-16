# Phase 6: Item System & Win Condition

## Status: COMPLETE

## Goal
Implement item collection, exit discovery, and win/loss condition logic.

## Tasks
- [x] Implement item pickup — when task reveals player's item, add to inventory
- [x] Track item collection state per player (has item / doesn't have item)
- [x] HUD indicator for item collected (label updated on player_item_collected signal)
- [x] Implement exit node in maze (hidden until discovered via fog)
- [x] Exit interaction: if player has item, trigger win
- [x] Exit interaction: if player doesn't have item, show message ("You need your item to exit!")
- [x] Win screen — display winner, stats summary (time, cells explored, size)
- [x] Loss detection — AI reaches exit with their item before player (via match_ended signal)
- [x] Loss screen with stats
- [x] Handle edge case: player finds opponent's item (OPPONENT_ITEM type in TaskOverlay)

## Dependencies
- Phase 5 (task completion reveals items) ✓
- Phase 4 (exit hidden in fog) ✓
- Phase 7 (AI can also win) — AI win triggered via SignalBus.match_ended("ai_win")

## Key Specs
- [Item Collection](../specs/item-collection.md)
- [Exit & Win](../specs/exit-win.md)

## Deliverables
- [x] ItemData data class
- [x] ItemRegistry with 5 default items, custom item support
- [x] WinConditionManager with player/AI exit checks
- [x] ResultsScreen (win/loss overlay with stats and navigation buttons)
- [x] Exit marker (cyan star shape, visible when fog removed)
- [x] Exit detection wired into GameScene._process
- [x] Rejection message on exit without item
- [x] Unit tests (test_item_system.gd): 15 tests covering ItemData, ItemRegistry, WinConditionManager

## Testing Criteria
- [x] Player receives item after task reveals it as theirs
- [x] Item indicator shows on HUD after collection
- [x] Exit is interactable only when discovered (player must physically reach cell to reveal fog)
- [x] Player with item entering exit triggers win
- [x] Player without item entering exit gets rejection message
- [x] AI winning triggers player loss screen (via match_ended signal)
- [x] Opponent items left at location for opponent to find (OPPONENT_ITEM type handled in TaskOverlay)
- [x] Win/loss screens display correctly with stats
