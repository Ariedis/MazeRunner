class_name NewGameConfig
extends RefCounted


## Returns true if the config dictionary is valid to start a game.
static func validate(config: Dictionary) -> bool:
	if config.get("item_id", "") == "":
		return false
	var num_opponents: int = config.get("num_opponents", 0)
	if num_opponents < 1:
		return false
	var diffs: Array = config.get("ai_difficulties", [])
	if diffs.size() != num_opponents:
		return false
	var map_size: int = config.get("map_size", -1)
	if not Enums.MAP_SIZE_DATA.has(map_size):
		return false
	var max_opp: int = Enums.MAP_SIZE_DATA[map_size]["max_opponents"]
	if num_opponents > max_opp:
		return false
	return true


## Returns the maximum allowed opponent count for the given map size.
static func get_max_opponents(map_size: int) -> int:
	if not Enums.MAP_SIZE_DATA.has(map_size):
		return 1
	return Enums.MAP_SIZE_DATA[map_size]["max_opponents"]
