# Phase 12: Polish & Integration

## Status: COMPLETE

## Goal
Final integration testing, bug fixes, visual polish, and performance optimization.

## Tasks
- [x] Full playthrough testing at each map size
- [x] AI behavior tuning per difficulty level
- [x] Energy drain/regen rate balancing
- [x] Clash balance testing (dice + size feel fair?)
- [x] Task timer duration balancing
- [x] UI/UX review — button sizing, readability, flow
- [x] Performance profiling on Large maps
- [x] Memory leak testing (scene transitions, long play sessions)
- [x] Edge case handling:
  - All locations completed but item not found (verified: PLAYER_ITEM always placed)
  - Multiple AI reaching exit simultaneously (fixed: WinConditionManager._resolved guard)
  - Clash during clash (fixed: pending AI-AI clash queue)
  - Save/load during overlay states (fixed: explicit guard in _on_pause_save)
- [x] Visual polish: AI state colors, pulsing animations, penalty purple indicator
- [x] Build and export testing

## Dependencies
- All previous phases complete

## Deliverables
- Stable, polished game build
- Known issues documented
- Balance values tuned

## Bug Fixes

### Exit Interaction Double-Win (HIGH)
**Problem:** `GameScene._handle_exit_interaction()` did not set `_match_over = true` on player win, allowing `match_ended` to fire while `_on_match_ended` was processing.
**Fix:** Added `_match_over = true` immediately in `_handle_exit_interaction()` on PLAYER_WIN result. Also added `_match_over` early-return guard at top of the method.

### WinConditionManager Double-Call (HIGH)
**Problem:** Multiple AI opponents reaching the exit on the same frame could each call `check_ai_at_exit()`, emitting multiple `match_ended` signals.
**Fix:** Added `_resolved: bool` flag to `WinConditionManager`. Once any win condition triggers, all subsequent checks return `NONE`.

### Clash During Active Clash (MEDIUM)
**Problem:** AI-AI clashes detected while a player-AI clash overlay was active were silently dropped.
**Fix:** Added `_pending_ai_clashes` queue. AI-AI clashes detected during an active player clash are deferred and resolved on the next frame after the player clash completes.

### Save During Overlay (MEDIUM)
**Problem:** The pause menu's save button could theoretically be invoked while a task overlay or clash overlay was active (though in practice overlays block the pause menu).
**Fix:** Added explicit guard in `_on_pause_save()` that returns early if `_match_over`, `_clash_active`, or `_task_overlay.visible`.

## Testing Criteria
- [x] Complete game loop works: menu → new game → explore → tasks → item → exit → win
- [x] AI completes same loop autonomously
- [x] 10+ consecutive games without crash
- [x] Save/load works across all game states
- [x] Settings persist and apply correctly
- [x] Custom content integrates without issues
- [x] Performance: stable 60fps on target hardware at all map sizes

## Files
- `scenes/game/GameScene.gd` — Exit double-win fix, save guard, clash queue
- `scripts/items/WinConditionManager.gd` — Double-call prevention
- `tests/test_polish.gd` — 34 integration tests covering all testing criteria
