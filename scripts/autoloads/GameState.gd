extends Node

var _current_state: int = 0  # Enums.GameState.MENU

var current_state: int:
	get:
		return _current_state
	set(value):
		var old_state := _current_state
		_current_state = value
		SignalBus.game_state_changed.emit(old_state, value)

var config: Dictionary = {
	"map_size": 0,
	"num_opponents": 1,
	"ai_difficulties": [],
	"seed": 0,
	"item_id": "",
	"avatar_id": 0,
}

var player: Dictionary = {
	"avatar_id": 0,
	"size": 1,
	"energy": 100.0,
	"has_item": false,
	"item_id": "",
	"position": Vector2.ZERO,
	"explored_cells": []
}

var match_state: Dictionary = {
	"locations_completed": [],
	"opponents": [],
	"is_paused": false
}


func reset_for_new_game() -> void:
	player = {
		"avatar_id": config.get("avatar_id", 0),
		"size": 1,
		"energy": 100.0,
		"has_item": false,
		"item_id": "",
		"position": Vector2.ZERO,
		"explored_cells": []
	}
	match_state = {
		"locations_completed": [],
		"opponents": [],
		"is_paused": false
	}
	SignalBus.game_config_changed.emit()


## Holds save data to be applied when loading a game scene.
var _pending_save_data: Variant = null


## Returns true when at least one save file exists.
func has_save_data() -> bool:
	return SaveManager.has_any_save()


## Queues save data for application after the game scene loads.
func queue_load(save_dict: Dictionary) -> void:
	var data: Dictionary = save_dict.get("data", {})
	# Restore config so maze generation uses the same seed/size.
	if data.has("config"):
		config = data["config"].duplicate(true)
	# Restore player baseline for Player.setup() to pick up.
	if data.has("player"):
		var p: Dictionary = data["player"]
		player["avatar_id"] = p.get("avatar_id", 0)
		player["size"] = p.get("size", 1)
		player["energy"] = p.get("energy", 100.0)
		player["has_item"] = p.get("has_item", false)
		player["item_id"] = p.get("item_id", "")
		player["explored_cells"] = []
	match_state = {
		"locations_completed": [],
		"opponents": [],
		"is_paused": false,
	}
	_pending_save_data = data


## Returns and clears pending save data, or null if none.
func take_pending_save_data() -> Variant:
	var data = _pending_save_data
	_pending_save_data = null
	return data


func is_in_match() -> bool:
	return _current_state == Enums.GameState.IN_GAME or _current_state == Enums.GameState.PAUSED
