# Phase 13 – Power-ups, Traps, Leaderboard & Maze Hazards

## Goal
Add four independently scoped systems on top of the Phase 12 baseline, each with full save/load support, deterministic placement, and code-driven visuals consistent with earlier phases.

## Deliverables

| System | Script(s) | Notes |
|--------|-----------|-------|
| Power-ups | `scripts/powerups/PowerupManager.gd` | Node2D child of GameScene |
| Traps | `scripts/traps/TrapManager.gd` | Node2D child of GameScene |
| Leaderboard | `scripts/leaderboard/LeaderboardManager.gd`<br>`scripts/leaderboard/LeaderboardOverlay.gd` | New autoload; CanvasLayer z=25 |
| Maze Hazards | `scripts/hazards/HazardManager.gd` | Node2D child of GameScene |

Enums additions (in `scripts/autoloads/Enums.gd`):
- `PowerupType` enum (`SPEED_BOOST`, `ENERGY_REFILL`, `AREA_REVEAL`)
- `POWERUP_*`, `TRAP_*`, `HAZARD_*` constants

---

## Power-ups

See full spec: [specs/power-ups.md](../specs/power-ups.md)

- 3 / 6 / 10 collectibles for Small / Medium / Large maps.
- Seeded placement via `maze_data.seed_val + 100`; min Manhattan distance 3 between items.
- Types: Speed Boost (1.8× for 5 s), Energy Refill (+50), Area Reveal (radius-5 fog clear).
- Diamond Polygon2D visuals, colour-coded cyan / green / magenta.
- AI behaviour by difficulty: Easy ignores, Medium opportunistic, Hard actively seeks when energy < 40.
- `save_state()` / `load_state()` — positions + types array.

---

## Traps

See full spec: [specs/traps.md](../specs/traps.md)

- Supply: 2 / 3 / 5 for Small / Medium / Large. Not replenished mid-match.
- Input: Space bar (`place_trap` action) at player's current grid cell.
- Invalid placement on spawn, exit, location cells, or existing traps. 3 s cooldown between placements.
- Trap is invisible to opponents; triggers when an opponent steps on it → 0.4× speed for 4 s, trap consumed.
- Placer is immune to own traps.
- HUD counter ("Traps: X") below energy bar.
- `save_state()` / `load_state()` — positions, supply, cooldown state.

---

## Leaderboard

See full spec: [specs/leaderboard.md](../specs/leaderboard.md)

- `LeaderboardManager` autoload: reads/writes `user://leaderboard.json` independently of save slots.
- Top 10 entries per map size (Small / Medium / Large), sorted ascending by completion time.
- Entry recorded on player win if leaderboard toggle is ON; fields: time_sec, date, player size stat, opponent count.
- `add_entry()` returns 1-based rank (or -1 if trimmed out of top 10).
- `LeaderboardOverlay` (CanvasLayer z=25): tabbed panel opened from MainMenu "Leaderboard" button or ResultsScreen "View Leaderboard" button.
- ResultsScreen shows "Leaderboard Rank: #X" or "New Record!" (rank 1) on player win.
- Corrupt/missing leaderboard file handled gracefully (empty data, no crash).

---

## Maze Hazards

See full spec: [specs/maze-hazards.md](../specs/maze-hazards.md)

Generation seeded via `maze_data.seed_val + 200`. Order: one-way doors → teleporters → dead-end traps.

### Dead-End Traps
- 30% of eligible dead ends (excluding spawn/exit/locations) are trapped.
- Effect: −25 energy + 2 s freeze on first trigger; disarmed thereafter (visual fades to 15% alpha).
- AI Easy: no avoidance. Medium: avoids after triggering one. Hard: pre-avoids all.

### Teleporters
- 1 / 2 / 3 pairs for Small / Medium / Large. Placed on corridor cells (non-dead-end, non-excluded).
- Two-way transport; 1 s cooldown after use (both portals locked) to prevent ping-pong.
- Purple circle visuals with white inner dot; hue shifts per pair index for visual distinction.
- `AStarPathfinder` receives teleporter pairs as zero-cost bidirectional edges → all AI difficulties use them.

### One-Way Doors
- 2 / 4 / 6 doors for Small / Medium / Large.
- Implemented via asymmetric wall data (cell A passage open, cell B wall closed on return side).
- **Validation:** after each placement, A* verifies a path exists from every spawn to exit; placement is reverted and retried (up to 300 attempts total) if broken.
- Arrow Polygon2D visual indicates allowed direction.

### Save/Load
- Hazards regenerate deterministically from seed on load — no placement data saved.
- Only triggered dead-end positions are serialised (`"hazards_triggered_traps"` key in save JSON).

---

## Architecture Integration

- `GameScene` creates and `setup()`s all four managers after maze generation, in this order:
  `HazardManager` → `PowerupManager` → `TrapManager`.
- `LeaderboardManager` is registered as an autoload (load order: after `SettingsManager`).
- `GameScene._process()` polls proximity for power-up pickup and trap triggering; teleporter/dead-end checks run on `_on_player_moved()`.
- `GameScene._save_game()` includes `"powerups"`, `"traps"`, `"hazards_triggered_traps"` keys.
- `GameScene._apply_save_data()` calls `load_state()` on each manager after maze regeneration.
- CanvasLayer z-ordering unchanged; `LeaderboardOverlay` at z=25 sits between `ClashOverlay` (15) and `ResultsScreen` (20) — correction: above ResultsScreen (20), so effective z=25 is the new top except SaveSlotPanel (30).
