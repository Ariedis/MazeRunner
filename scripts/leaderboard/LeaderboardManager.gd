extends Node

## Autoload that tracks best completion times per map size.
## Persists at user://leaderboard.json independently of save slots.

const LEADERBOARD_FILE: String = "user://leaderboard.json"
const MAX_ENTRIES: int = 10

var _data: Dictionary = {
	"small":  [],
	"medium": [],
	"large":  [],
}


func _ready() -> void:
	_load()


func _size_key(map_size: int) -> String:
	match map_size:
		Enums.MapSize.SMALL:  return "small"
		Enums.MapSize.MEDIUM: return "medium"
		Enums.MapSize.LARGE:  return "large"
	return "small"


## Add an entry. Returns the 1-based rank achieved, or -1 if trimmed out.
func add_entry(map_size: int, time_sec: float, player_size: int, opponents: int) -> int:
	var key := _size_key(map_size)
	var entries: Array = _data[key]
	var entry := {
		"time_sec": time_sec,
		"date": Time.get_date_string_from_system(),
		"size": player_size,
		"opponents": opponents,
	}
	entries.append(entry)
	# Sort ascending by time (fastest first).
	entries.sort_custom(func(a, b): return a["time_sec"] < b["time_sec"])
	# Find rank before trimming.
	var rank := -1
	for i in entries.size():
		if entries[i] == entry:
			rank = i + 1
			break
	# Trim to max entries.
	while entries.size() > MAX_ENTRIES:
		entries.pop_back()
	_data[key] = entries
	# Entry may have been trimmed off if rank > MAX_ENTRIES.
	if rank > MAX_ENTRIES:
		return -1
	_save()
	return rank


## Returns a copy of the leaderboard entries for [map_size] (sorted ascending by time).
func get_entries(map_size: int) -> Array:
	return _data[_size_key(map_size)].duplicate()


# --- Persistence ---

func _save() -> void:
	var file := FileAccess.open(LEADERBOARD_FILE, FileAccess.WRITE)
	if file == null:
		push_error("LeaderboardManager: could not write %s" % LEADERBOARD_FILE)
		return
	file.store_string(JSON.stringify(_data, "\t"))
	file.close()


func _load() -> void:
	if not FileAccess.file_exists(LEADERBOARD_FILE):
		return
	var file := FileAccess.open(LEADERBOARD_FILE, FileAccess.READ)
	if file == null:
		return
	var content := file.get_as_text()
	file.close()
	if content.is_empty():
		return
	var json := JSON.new()
	if json.parse(content) != OK:
		push_warning("LeaderboardManager: corrupt leaderboard file")
		return
	var parsed = json.data
	if not parsed is Dictionary:
		return
	for key in ["small", "medium", "large"]:
		if parsed.has(key) and parsed[key] is Array:
			_data[key] = parsed[key]
