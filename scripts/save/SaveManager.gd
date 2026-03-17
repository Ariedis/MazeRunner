extends Node

const SAVE_VERSION: String = "1.0"
const MAX_SLOTS: int = 5
const SAVE_DIR: String = "user://saves/"
const SAVE_PREFIX: String = "save_slot_"
const SAVE_EXT: String = ".json"


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(SAVE_DIR)


## Returns the file path for a given slot number (1-based).
func _slot_path(slot: int) -> String:
	return SAVE_DIR + SAVE_PREFIX + str(slot) + SAVE_EXT


## Save the current game state to the given slot. Returns true on success.
func save_game(slot: int, game_data: Dictionary) -> bool:
	if slot < 1 or slot > MAX_SLOTS:
		push_error("SaveManager: invalid slot %d" % slot)
		return false

	var save_dict := {
		"version": SAVE_VERSION,
		"timestamp": Time.get_datetime_string_from_system(true),
		"slot": slot,
		"data": game_data,
	}

	var json_string := JSON.stringify(save_dict, "\t")
	var file := FileAccess.open(_slot_path(slot), FileAccess.WRITE)
	if file == null:
		push_error("SaveManager: could not open file for writing: %s" % _slot_path(slot))
		return false

	file.store_string(json_string)
	file.close()
	return true


## Load a save from the given slot. Returns null on failure.
func load_game(slot: int) -> Variant:
	if slot < 1 or slot > MAX_SLOTS:
		push_error("SaveManager: invalid slot %d" % slot)
		return null
	return _read_save_file(_slot_path(slot))


## Returns the save data from the most recently saved slot, or null if none.
func load_most_recent() -> Variant:
	var best: Dictionary = {}
	var best_time: String = ""
	for slot in range(1, MAX_SLOTS + 1):
		var save := _read_save_file(_slot_path(slot))
		if save == null:
			continue
		var ts: String = save.get("timestamp", "")
		if ts > best_time:
			best_time = ts
			best = save
	if best.is_empty():
		return null
	return best


## Delete a save slot. Returns true if the file was deleted.
func delete_save(slot: int) -> bool:
	if slot < 1 or slot > MAX_SLOTS:
		return false
	var path := _slot_path(slot)
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
		return true
	return false


## Returns true if at least one save file exists.
func has_any_save() -> bool:
	for slot in range(1, MAX_SLOTS + 1):
		if FileAccess.file_exists(_slot_path(slot)):
			return true
	return false


## Returns metadata for all slots. Each entry is a Dictionary with keys:
## slot, exists, timestamp, map_size, locations_completed, locations_total, corrupt
func get_all_slot_info() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for slot in range(1, MAX_SLOTS + 1):
		var info: Dictionary = {"slot": slot, "exists": false, "timestamp": "", "map_size": "", "locations_completed": 0, "locations_total": 0, "corrupt": false}
		var path := _slot_path(slot)
		if not FileAccess.file_exists(path):
			result.append(info)
			continue

		var save := _read_save_file(path)
		if save == null:
			info["exists"] = true
			info["corrupt"] = true
			result.append(info)
			continue

		info["exists"] = true
		info["timestamp"] = save.get("timestamp", "")
		var data: Dictionary = save.get("data", {})
		var config: Dictionary = data.get("config", {})
		var map_size_val: int = config.get("map_size", 0)
		match map_size_val:
			Enums.MapSize.SMALL:
				info["map_size"] = "Small"
			Enums.MapSize.MEDIUM:
				info["map_size"] = "Medium"
			Enums.MapSize.LARGE:
				info["map_size"] = "Large"
			_:
				info["map_size"] = "Unknown"
		var locs: Array = data.get("locations", [])
		info["locations_total"] = locs.size()
		var completed := 0
		for loc in locs:
			if loc.get("completed", false):
				completed += 1
		info["locations_completed"] = completed
		result.append(info)
	return result


## Build a complete game state dictionary from the current game scene.
## Called by GameScene when the player saves.
func capture_game_state(
	maze_data: MazeData,
	player: Player,
	fog: FogOfWar,
	location_manager: LocationManager,
	ai_opponents: Array,
	elapsed_msec: int,
	renderer: MazeRenderer,
	clash_active: bool
) -> Dictionary:
	var data := {}

	# Config
	data["config"] = GameState.config.duplicate(true)

	# Maze metadata (regenerated from seed, but store structural info for validation)
	data["maze"] = {
		"width": maze_data.width,
		"height": maze_data.height,
		"seed": maze_data.seed_val,
		"exit": _v2i_to_arr(maze_data.exit),
		"player_spawn": _v2i_to_arr(maze_data.player_spawn),
		"ai_spawns": maze_data.ai_spawns.map(func(s): return _v2i_to_arr(s)),
		"locations": maze_data.locations.map(func(l): return _v2i_to_arr(l)),
	}

	# Player
	data["player"] = {
		"position": _v2_to_arr(player.global_position),
		"grid_pos": _v2i_to_arr(renderer.world_to_grid(player.global_position)),
		"size": player.stats.size,
		"energy": player.stats.energy,
		"has_item": GameState.player.get("has_item", false),
		"item_id": GameState.player.get("item_id", ""),
		"avatar_id": GameState.player.get("avatar_id", 0),
		"explored_cells": fog.get_explored_array().map(func(c): return _v2i_to_arr(c)),
		"clash_cooldown": player._clash_cooldown,
		"is_frozen": player._is_frozen,
	}

	# AI opponents
	var opponents_data: Array = []
	for i in ai_opponents.size():
		var ai: AIOpponent = ai_opponents[i]
		var brain: AIBrain = ai.brain
		var opp := {
			"index": i,
			"position": _v2_to_arr(ai.global_position),
			"grid_pos": _v2i_to_arr(renderer.world_to_grid(ai.global_position)),
			"size": ai.stats.size,
			"energy": ai.stats.energy,
			"difficulty": ai._difficulty,
			"has_item": brain.has_item,
			"state": brain.state,
			"explored_cells": [],
			"known_uncompleted_locs": brain.known_uncompleted_locs.map(func(l): return _v2i_to_arr(l)),
			"exit_known": brain.exit_known,
			"exit_pos": _v2i_to_arr(brain.exit_pos),
			"penalty_timer": brain.penalty_timer,
			"task_timer": brain.task_timer,
			"current_path": brain.current_path.map(func(p): return _v2i_to_arr(p)),
			"clash_cooldown": ai._clash_cooldown,
			"_item_loc_pos": _v2i_to_arr(brain._item_loc_pos),
			"_current_task_pos": _v2i_to_arr(brain._current_task_pos),
			"_current_target": _v2i_to_arr(brain._current_target),
			"_pre_rest_state": brain._pre_rest_state,
			"_pre_penalty_state": brain._pre_penalty_state,
			"_rest_threshold": brain._rest_threshold,
			"_rest_target": brain._rest_target,
		}
		# Serialize explored cells dictionary
		var explored_arr: Array = []
		for cell in brain.explored:
			explored_arr.append(_v2i_to_arr(cell))
		opp["explored_cells"] = explored_arr
		opponents_data.append(opp)
	data["opponents"] = opponents_data

	# Locations
	var locs_data: Array = []
	for loc in location_manager.locations:
		locs_data.append({
			"id": loc.id,
			"grid_pos": _v2i_to_arr(loc.grid_pos),
			"item_type": loc.item_type,
			"completed": loc.completed,
			"completed_by": loc.completed_by.duplicate(),
		})
	data["locations"] = locs_data

	# Timing
	data["elapsed_msec"] = elapsed_msec
	data["clash_active"] = clash_active

	return data


# --- Helpers ---

func _v2i_to_arr(v: Vector2i) -> Array:
	return [v.x, v.y]


func _v2_to_arr(v: Vector2) -> Array:
	return [v.x, v.y]


static func arr_to_v2i(a: Array) -> Vector2i:
	return Vector2i(int(a[0]), int(a[1]))


static func arr_to_v2(a: Array) -> Vector2:
	return Vector2(float(a[0]), float(a[1]))


func _read_save_file(path: String) -> Variant:
	if not FileAccess.file_exists(path):
		return null

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return null

	var content := file.get_as_text()
	file.close()

	if content.is_empty():
		return null

	var json := JSON.new()
	var err := json.parse(content)
	if err != OK:
		push_warning("SaveManager: corrupt save file: %s" % path)
		return null

	var result = json.data
	if not result is Dictionary:
		push_warning("SaveManager: save file root is not a Dictionary: %s" % path)
		return null

	# Version check
	var version: String = result.get("version", "")
	if version != SAVE_VERSION:
		push_warning("SaveManager: version mismatch in %s (expected %s, got %s)" % [path, SAVE_VERSION, version])
		# Still return data — caller can decide what to do

	return result
