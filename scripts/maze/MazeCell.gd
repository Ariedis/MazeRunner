class_name MazeCell
extends RefCounted

var position: Vector2i
var walls: Dictionary      # {"top": bool, "right": bool, "bottom": bool, "left": bool}
var visited: bool = false
var has_location: bool = false
var is_exit: bool = false
var is_spawn: bool = false

func _init(col: int, row: int) -> void:
	position = Vector2i(col, row)
	walls = {"top": true, "right": true, "bottom": true, "left": true}

func get_wall(direction: String) -> bool:
	return walls[direction]

func set_wall(direction: String, value: bool) -> void:
	walls[direction] = value

func is_dead_end() -> bool:
	var count = 0
	for w in walls.values():
		if w: count += 1
	return count == 3
