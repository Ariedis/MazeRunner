class_name MazeRenderer
extends Node

const WALL_SIDE_RATIO := 0.35
const WALL_TOP_COLOR := Color(0.22, 0.4, 0.14)
const WALL_SIDE_COLOR := Color(0.1, 0.2, 0.08)
const WALL_OUTLINE_COLOR := Color(0.06, 0.12, 0.04)
const FLOOR_COLOR := Color(0.24, 0.32, 0.15)

var _tile_map: TileMap
var _tile_size: int
var _source_id: int = 0

func render(maze_data: MazeData, cell_px: int) -> void:
	_tile_size = cell_px / 2

	# Draw floor background behind everything.
	var floor_bg := FloorBackground.new()
	floor_bg.name = "FloorBackground"
	var total_w := (2 * maze_data.width + 1) * _tile_size
	var total_h := (2 * maze_data.height + 1) * _tile_size
	floor_bg.setup(total_w, total_h)
	add_child(floor_bg)

	_tile_map = TileMap.new()
	_tile_map.name = "TileMap"
	add_child(_tile_map)
	_create_tileset(_tile_size)
	_fill_walls(maze_data)
	_carve_passages(maze_data)
	_build_wall_collisions()
	_build_wall_sides()

func _create_tileset(tile_size: int) -> void:
	var ts = TileSet.new()
	ts.tile_size = Vector2i(tile_size, tile_size)

	var img = Image.create(tile_size, tile_size, false, Image.FORMAT_RGB8)
	img.fill(WALL_TOP_COLOR)
	var tex = ImageTexture.create_from_image(img)
	var source = TileSetAtlasSource.new()
	source.texture = tex
	source.texture_region_size = Vector2i(tile_size, tile_size)
	source.create_tile(Vector2i(0, 0))

	_source_id = ts.add_source(source)
	_tile_map.tile_set = ts

func _fill_walls(data: MazeData) -> void:
	for tr in (2 * data.height + 1):
		for tc in (2 * data.width + 1):
			_tile_map.set_cell(0, Vector2i(tc, tr), _source_id, Vector2i(0, 0))

func _carve_passages(data: MazeData) -> void:
	for row in data.height:
		for col in data.width:
			var cell = data.get_cell(col, row)
			_tile_map.erase_cell(0, Vector2i(2 * col + 1, 2 * row + 1))
			if not cell.get_wall("right"):
				_tile_map.erase_cell(0, Vector2i(2 * col + 2, 2 * row + 1))
			if not cell.get_wall("bottom"):
				_tile_map.erase_cell(0, Vector2i(2 * col + 1, 2 * row + 2))

func _build_wall_collisions() -> void:
	var static_body := StaticBody2D.new()
	static_body.name = "WallCollision"
	add_child(static_body)

	var shape := RectangleShape2D.new()
	shape.size = Vector2(_tile_size, _tile_size)
	var half := _tile_size / 2.0

	var used_cells := _tile_map.get_used_cells(0)
	for cell_pos in used_cells:
		var col_shape := CollisionShape2D.new()
		col_shape.shape = shape
		col_shape.position = Vector2(
			cell_pos.x * _tile_size + half,
			cell_pos.y * _tile_size + half
		)
		static_body.add_child(col_shape)

func _build_wall_sides() -> void:
	var drawer := WallSideDrawer.new()
	drawer.name = "WallSideDrawer"
	drawer.z_index = 1
	drawer.setup(_tile_map.get_used_cells(0), _tile_size)
	add_child(drawer)

func get_world_position(grid_pos: Vector2i) -> Vector2:
	var half := _tile_size / 2.0
	return Vector2(
		(2 * grid_pos.x + 1) * _tile_size + half,
		(2 * grid_pos.y + 1) * _tile_size + half
	)

func world_to_grid(world_pos: Vector2) -> Vector2i:
	return Vector2i(
		int(world_pos.x / _tile_size - 1.0) / 2,
		int(world_pos.y / _tile_size - 1.0) / 2
	)

func get_tilemap() -> TileMap:
	return _tile_map


## Draws a solid floor color behind the maze.
class FloorBackground extends Node2D:
	var _width: int = 0
	var _height: int = 0

	func setup(w: int, h: int) -> void:
		_width = w
		_height = h

	func _draw() -> void:
		draw_rect(Rect2(0, 0, _width, _height), MazeRenderer.FLOOR_COLOR)


## Draws dark side faces and outlines below each wall cell for the hedge maze look.
## Side faces are only drawn when the cell below is not a wall (i.e., there's open space).
class WallSideDrawer extends Node2D:
	var _wall_cells: Array[Vector2i] = []
	var _wall_set: Dictionary = {}  # Quick lookup: Vector2i -> true
	var _tile_size: int = 0

	func setup(cells: Array[Vector2i], tile_size: int) -> void:
		_wall_cells = cells
		_tile_size = tile_size
		for cell in cells:
			_wall_set[cell] = true

	func _draw() -> void:
		var ts := float(_tile_size)
		var side_height := ts * MazeRenderer.WALL_SIDE_RATIO
		var outline_w := maxf(1.0, ts * 0.06)

		# Side faces only where the cell below is open space.
		for cell in _wall_cells:
			var below := Vector2i(cell.x, cell.y + 1)
			if _wall_set.has(below):
				continue
			var x := cell.x * ts
			var y := (cell.y + 1) * ts

			draw_rect(Rect2(x, y, ts, side_height), MazeRenderer.WALL_SIDE_COLOR)
			draw_rect(Rect2(x, y, ts, side_height), MazeRenderer.WALL_OUTLINE_COLOR, false, outline_w)

		# Outline around wall tops.
		for cell in _wall_cells:
			var x := cell.x * ts
			var y := cell.y * ts
			draw_rect(Rect2(x, y, ts, ts), MazeRenderer.WALL_OUTLINE_COLOR, false, outline_w)
