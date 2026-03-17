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


## Returns true when a save file exists. Phase 10 will implement actual file checks.
func has_save_data() -> bool:
	return false


func apply_save_data(data: Dictionary) -> void:
	# Stub for Phase 10 SaveSystem
	pass


func is_in_match() -> bool:
	return _current_state == Enums.GameState.IN_GAME or _current_state == Enums.GameState.PAUSED
