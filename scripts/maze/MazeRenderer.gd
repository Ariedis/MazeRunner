class_name MazeRenderer
extends Node

var _tile_map: TileMap
var _tile_size: int
var _source_id: int = 0

func render(maze_data: MazeData, cell_px: int) -> void:
	_tile_size = cell_px / 2
	_tile_map = TileMap.new()
	_tile_map.name = "TileMap"
	add_child(_tile_map)
	_create_tileset(_tile_size)
	_fill_walls(maze_data)
	_carve_passages(maze_data)
	_build_wall_collisions()

func _create_tileset(tile_size: int) -> void:
	var ts = TileSet.new()
	ts.tile_size = Vector2i(tile_size, tile_size)

	var img = Image.create(tile_size, tile_size, false, Image.FORMAT_RGB8)
	img.fill(Color(0.4, 0.4, 0.4))
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

func get_world_position(grid_pos: Vector2i) -> Vector2:
	return Vector2((2 * grid_pos.x + 1) * _tile_size, (2 * grid_pos.y + 1) * _tile_size)

func get_tilemap() -> TileMap:
	return _tile_map
