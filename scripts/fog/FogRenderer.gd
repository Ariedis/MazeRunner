class_name FogRenderer
extends Node

var _fog_map: TileMap
var _source_id: int
var _tile_size: int
var _map_width: int
var _map_height: int


func initialize(maze_width: int, maze_height: int, tile_size: int) -> void:
	_tile_size = tile_size
	_map_width = 2 * maze_width + 1
	_map_height = 2 * maze_height + 1

	_fog_map = TileMap.new()
	_fog_map.name = "FogTileMap"

	var ts := TileSet.new()
	ts.tile_size = Vector2i(tile_size, tile_size)

	var img := Image.create(tile_size, tile_size, false, Image.FORMAT_RGB8)
	img.fill(Color(0.0, 0.0, 0.0))
	var tex := ImageTexture.create_from_image(img)
	var source := TileSetAtlasSource.new()
	source.texture = tex
	source.texture_region_size = Vector2i(tile_size, tile_size)
	source.create_tile(Vector2i(0, 0))

	_source_id = ts.add_source(source)
	_fog_map.tile_set = ts

	for tr in _map_height:
		for tc in _map_width:
			_fog_map.set_cell(0, Vector2i(tc, tr), _source_id, Vector2i(0, 0))

	add_child(_fog_map)


func reveal_cells(cells: Array[Vector2i]) -> void:
	for maze_cell in cells:
		var cx := 2 * maze_cell.x + 1
		var cy := 2 * maze_cell.y + 1
		for dy in range(-1, 2):
			for dx in range(-1, 2):
				var tx := cx + dx
				var ty := cy + dy
				if tx < 0 or tx >= _map_width:
					continue
				if ty < 0 or ty >= _map_height:
					continue
				_fog_map.erase_cell(0, Vector2i(tx, ty))
