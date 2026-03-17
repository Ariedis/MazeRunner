# Feature Spec: Leaderboard

## Overview
Track best completion times per map size. Persists independently of game saves at `user://leaderboard.json`.

## Data Structure
```json
{
  "small": [{"time_sec": 120.5, "date": "2026-03-17", "size": 3, "opponents": 2}],
  "medium": [],
  "large": []
}
```
- Max 10 entries per map size
- Sorted by time ascending (fastest first)

## Recording
- Only recorded on player win with leaderboard toggle ON
- Entry includes: completion time, date, player size stat, number of opponents

## Display

### ResultsScreen
- On player win: shows "Leaderboard Rank: #X" or "New Record!" if rank 1
- "View Leaderboard" button opens leaderboard overlay

### MainMenu
- New "Leaderboard" button opens CanvasLayer overlay
- 3 tabs: Small / Medium / Large
- Each tab shows table: Rank / Time / Date / Size / Opponents

## Manager
- `LeaderboardManager` autoload (consistent with SettingsManager/SaveManager pattern)
- Handles read/write of `user://leaderboard.json`
- Provides `add_entry(map_size, time_sec, player_size, opponents) -> int` (returns rank)
- Provides `get_entries(map_size) -> Array`

## Constants
```
LEADERBOARD_MAX_ENTRIES = 10
LEADERBOARD_FILE_PATH = "user://leaderboard.json"
```

## Independence
- Leaderboard data is never part of save slots
- Leaderboard persists across game sessions independently

## Testing Criteria
- [ ] Entry recorded on player win with toggle ON
- [ ] Entry not recorded on player loss
- [ ] Entry not recorded with toggle OFF
- [ ] Max 10 entries per map size
- [ ] Entries sorted by time ascending
- [ ] Correct rank returned on add
- [ ] "New Record!" shown for rank 1
- [ ] Leaderboard persists across sessions
- [ ] Leaderboard independent of save system
- [ ] Graceful handling of missing/corrupt leaderboard file
- [ ] MainMenu overlay displays all 3 tabs correctly
- [ ] ResultsScreen shows rank on player win
