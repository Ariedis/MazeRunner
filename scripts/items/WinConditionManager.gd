class_name WinConditionManager
extends RefCounted

enum Result { NONE, PLAYER_WIN, AI_WIN }

var _resolved: bool = false


func check_player_at_exit(has_item: bool) -> int:
	if _resolved:
		return Result.NONE
	if has_item:
		_resolved = true
		SignalBus.match_ended.emit("player_win")
		return Result.PLAYER_WIN
	return Result.NONE


func check_ai_at_exit(ai_has_item: bool) -> int:
	if _resolved:
		return Result.NONE
	if ai_has_item:
		_resolved = true
		SignalBus.match_ended.emit("ai_win")
		return Result.AI_WIN
	return Result.NONE
