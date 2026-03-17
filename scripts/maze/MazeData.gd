class_name MazeData
extends RefCounted

var grid: Array = []
var width: int
var height: int
var seed_val: int
var locations: Array[Vector2i] = []
var exit: Vector2i = Vector2i(-1, -1)
var player_spawn: Vector2i = Vector2i(-1, -1)
var ai_spawns: Array[Vector2i] = []

## Populated by HazardManager when hazards feature is enabled.
## Maps portal position (Vector2i) -> partner position (Vector2i).
var teleporter_pairs: Dictionary = {}

func _init(w: int, h: int) -> void:
	width = w
	height = h
	for row in h:
		var r = []
		for col in w:
			r.append(MazeCell.new(col, row))
		grid.append(r)

func get_cell(col: int, row: int) -> MazeCell:
	return grid[row][col]

func get_cell_v(pos: Vector2i) -> MazeCell:
	return grid[pos.y][pos.x]

func is_valid(col: int, row: int) -> bool:
	return col >= 0 and col < width and row >= 0 and row < height

func get_dead_ends() -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for row in height:
		for col in width:
			if get_cell(col, row).is_dead_end():
				result.append(Vector2i(col, row))
	return result
