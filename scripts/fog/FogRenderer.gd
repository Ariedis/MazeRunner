class_name FogRenderer
extends Node2D

const WALL_SIDE_RATIO := 0.35
const FOG_COLOR := Color(0.08, 0.14, 0.04)

var _tile_size: int
var _map_width: int
var _map_height: int
var _revealed: Array = []  # 2D array of bools: _revealed[row][col]


func initialize(maze_width: int, maze_height: int, tile_size: int) -> void:
	_tile_size = tile_size
	_map_width = 2 * maze_width + 1
	_map_height = 2 * maze_height + 1

	# Initialize revealed grid (all false = all fogged).
	_revealed.resize(_map_height)
	for row in _map_height:
		var row_arr: Array = []
		row_arr.resize(_map_width)
		row_arr.fill(false)
		_revealed[row] = row_arr


func reveal_cells(cells) -> void:
	for maze_cell in cells:
		var cx: int = 2 * maze_cell.x + 1
		var cy: int = 2 * maze_cell.y + 1
		for dy in range(-1, 2):
			for dx in range(-1, 2):
				var tx := cx + dx
				var ty := cy + dy
				if tx < 0 or tx >= _map_width:
					continue
				if ty < 0 or ty >= _map_height:
					continue
				_revealed[ty][tx] = true
	queue_redraw()


func _draw() -> void:
	var ts := float(_tile_size)
	var side_ext := ts * WALL_SIDE_RATIO
	for row in _map_height:
		for col in _map_width:
			if not _revealed[row][col]:
				draw_rect(
					Rect2(col * ts, row * ts, ts, ts + side_ext),
					FOG_COLOR
				)
