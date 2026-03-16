class_name WinConditionManager
extends RefCounted

enum Result { NONE, PLAYER_WIN, AI_WIN }


func check_player_at_exit(has_item: bool) -> int:
	if has_item:
		SignalBus.match_ended.emit("player_win")
		return Result.PLAYER_WIN
	return Result.NONE


func check_ai_at_exit(ai_has_item: bool) -> int:
	if ai_has_item:
		SignalBus.match_ended.emit("ai_win")
		return Result.AI_WIN
	return Result.NONE
