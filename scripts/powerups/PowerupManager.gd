class_name PowerupManager
extends Node2D

## Manages power-up spawning, visuals, and pickup state.
## Seeded from maze_data.seed_val + 100 for deterministic placement.

# Dict: Vector2i -> {type: int, visual: Node2D}
var _powerups: Dictionary = {}

var _tile_size: int
var _renderer: MazeRenderer


func setup(maze_data: MazeData, tile_size: int, renderer: MazeRenderer) -> void:
	_tile_size = tile_size
	_renderer = renderer

	var rng := RandomNumberGenerator.new()
	rng.seed = maze_data.seed_val + 100

	var map_size: int = GameState.config.get("map_size", Enums.MapSize.SMALL)
	var count: int = Enums.POWERUP_COUNTS.get(map_size, 3)

	# Build excluded set.
	var excluded: Array[Vector2i] = []
	excluded.append(maze_data.player_spawn)
	excluded.append(maze_data.exit)
	for loc in maze_data.locations:
		excluded.append(loc)
	for spawn in maze_data.ai_spawns:
		excluded.append(spawn)

	# Candidate pool.
	var candidates: Array[Vector2i] = []
	for row in maze_data.height:
		for col in maze_data.width:
			var pos := Vector2i(col, row)
			if not excluded.has(pos):
				candidates.append(pos)

	# Fisher-Yates shuffle.
	for i in range(candidates.size() - 1, 0, -1):
		var j := rng.randi() % (i + 1)
		var tmp := candidates[i]
		candidates[i] = candidates[j]
		candidates[j] = tmp

	# Place with minimum manhattan distance 3 between power-ups.
	var placed: Array[Vector2i] = []
	for pos in candidates:
		if placed.size() >= count:
			break
		var too_close := false
		for existing in placed:
			if abs(pos.x - existing.x) + abs(pos.y - existing.y) < 3:
				too_close = true
				break
		if not too_close:
			placed.append(pos)

	# Create powerup entries and visuals.
	for pos in placed:
		var type: int = rng.randi() % 3
		_spawn_powerup(pos, type)


## Returns true if a power-up exists at grid position [pos].
func has_powerup_at(pos: Vector2i) -> bool:
	return _powerups.has(pos)


## Consumes the power-up at [pos] and returns its type. Returns -1 if none.
func consume_powerup(pos: Vector2i) -> int:
	if not _powerups.has(pos):
		return -1
	var type: int = _powerups[pos]["type"]
	var visual: Node2D = _powerups[pos]["visual"]
	visual.queue_free()
	_powerups.erase(pos)
	return type


## Returns all current power-up grid positions.
func get_all_positions() -> Array:
	return _powerups.keys()


## Restores power-ups from save data (array of [x, y, type] entries).
func load_state(saved: Array) -> void:
	for pos in _powerups.keys():
		_powerups[pos]["visual"].queue_free()
	_powerups.clear()
	for entry in saved:
		var pos := Vector2i(int(entry[0]), int(entry[1]))
		var type := int(entry[2])
		_spawn_powerup(pos, type)


## Serialises current powerup state as array of [x, y, type] entries.
func save_state() -> Array:
	var result: Array = []
	for pos in _powerups:
		result.append([pos.x, pos.y, _powerups[pos]["type"]])
	return result


# --- Internal ---

func _spawn_powerup(pos: Vector2i, type: int) -> void:
	var visual := _make_visual(type)
	visual.position = _renderer.get_world_position(pos)
	add_child(visual)
	_powerups[pos] = {"type": type, "visual": visual}


func _make_visual(type: int) -> Node2D:
	var n := Node2D.new()
	var poly := Polygon2D.new()
	var r := float(_tile_size) * 0.3
	# Diamond shape.
	poly.polygon = PackedVector2Array([
		Vector2(0.0, -r),
		Vector2(r,   0.0),
		Vector2(0.0,  r),
		Vector2(-r,  0.0),
	])
	match type:
		Enums.PowerupType.SPEED_BOOST:   poly.color = Color(0.0, 0.9, 0.9)   # Cyan
		Enums.PowerupType.ENERGY_REFILL: poly.color = Color(0.2, 0.9, 0.2)   # Green
		Enums.PowerupType.AREA_REVEAL:   poly.color = Color(0.9, 0.3, 0.9)   # Magenta
	n.add_child(poly)
	return n
