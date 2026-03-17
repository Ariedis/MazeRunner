class_name HazardManager
extends Node2D

## Generates and manages maze hazards: dead-end traps, teleporters, one-way doors.
## Uses RNG seeded from maze_data.seed_val + 200 for deterministic placement.

## Dict: Vector2i -> bool  (false = active, true = triggered/disarmed)
var _dead_end_traps: Dictionary = {}

## Dict: Vector2i -> Vector2i  (portal -> partner)
var _teleporter_pairs: Dictionary = {}

## Dict: Vector2i -> float  (teleporter cooldown timer per portal)
var _teleporter_cooldowns: Dictionary = {}

var _tile_size: int
var _renderer: MazeRenderer

## Visuals
var _dead_end_visuals: Dictionary = {}   # Vector2i -> Node2D
var _teleporter_visuals: Dictionary = {} # Vector2i -> Node2D


func setup(maze_data: MazeData, tile_size: int, renderer: MazeRenderer) -> void:
	_tile_size = tile_size
	_renderer = renderer

	var map_size: int = GameState.config.get("map_size", Enums.MapSize.SMALL)
	var rng := RandomNumberGenerator.new()
	rng.seed = maze_data.seed_val + 200

	# Build excluded set (spawn, exit, locations).
	var excluded: Array[Vector2i] = []
	excluded.append(maze_data.player_spawn)
	excluded.append(maze_data.exit)
	for loc in maze_data.locations:
		excluded.append(loc)

	# Generation order per spec: one-way doors → teleporters → dead-end traps.
	_generate_one_way_doors(maze_data, rng, map_size, excluded)
	_generate_teleporters(maze_data, rng, map_size, excluded)
	_generate_dead_end_traps(maze_data, rng, excluded)

	# Expose teleporter pairs through MazeData for AI pathfinding.
	maze_data.teleporter_pairs = _teleporter_pairs.duplicate()


func _process(delta: float) -> void:
	var keys := _teleporter_cooldowns.keys()
	for pos in keys:
		_teleporter_cooldowns[pos] -= delta
		if _teleporter_cooldowns[pos] <= 0.0:
			_teleporter_cooldowns.erase(pos)


# ---------- Public API ----------

func is_dead_end_trap(pos: Vector2i) -> bool:
	return _dead_end_traps.has(pos) and not _dead_end_traps[pos]


func trigger_dead_end_trap(pos: Vector2i) -> void:
	if _dead_end_traps.has(pos):
		_dead_end_traps[pos] = true  # Disarmed.
		if _dead_end_visuals.has(pos):
			_dead_end_visuals[pos].modulate.a = 0.15


func has_teleporter(pos: Vector2i) -> bool:
	return _teleporter_pairs.has(pos)


func get_teleporter_partner(pos: Vector2i) -> Vector2i:
	return _teleporter_pairs.get(pos, Vector2i(-1, -1))


func is_on_cooldown(pos: Vector2i) -> bool:
	return _teleporter_cooldowns.get(pos, 0.0) > 0.0


func start_teleporter_cooldown(pos: Vector2i) -> void:
	_teleporter_cooldowns[pos] = Enums.HAZARD_TELEPORTER_COOLDOWN
	var partner := get_teleporter_partner(pos)
	if partner != Vector2i(-1, -1):
		_teleporter_cooldowns[partner] = Enums.HAZARD_TELEPORTER_COOLDOWN


## Returns all currently-active (non-triggered) dead-end trap positions.
func get_active_dead_end_trap_positions() -> Array:
	var result: Array = []
	for pos in _dead_end_traps:
		if not _dead_end_traps[pos]:
			result.append(pos)
	return result


## Restores triggered dead-end trap state from a save.
func load_triggered_traps(triggered: Array) -> void:
	for pos_arr in triggered:
		var pos := Vector2i(int(pos_arr[0]), int(pos_arr[1]))
		if _dead_end_traps.has(pos):
			_dead_end_traps[pos] = true
			if _dead_end_visuals.has(pos):
				_dead_end_visuals[pos].modulate.a = 0.15


## Serialises which dead-end traps have been triggered.
func save_triggered_traps() -> Array:
	var result: Array = []
	for pos in _dead_end_traps:
		if _dead_end_traps[pos]:
			result.append([pos.x, pos.y])
	return result


# ---------- Generation ----------

func _generate_dead_end_traps(maze_data: MazeData, rng: RandomNumberGenerator,
		excluded: Array[Vector2i]) -> void:
	var dead_ends := maze_data.get_dead_ends()
	for pos in dead_ends:
		if excluded.has(pos):
			continue
		if rng.randf() < Enums.HAZARD_DEAD_END_PERCENT:
			_dead_end_traps[pos] = false  # false = active
			var visual := _make_dead_end_visual()
			visual.position = _renderer.get_world_position(pos)
			add_child(visual)
			_dead_end_visuals[pos] = visual


func _generate_teleporters(maze_data: MazeData, rng: RandomNumberGenerator,
		map_size: int, excluded: Array[Vector2i]) -> void:
	var pair_count: int = Enums.HAZARD_TELEPORTER_PAIRS.get(map_size, 1)

	# Candidates: corridor cells (not dead-ends, not excluded, not already a dead-end trap).
	var candidates: Array[Vector2i] = []
	for row in maze_data.height:
		for col in maze_data.width:
			var pos := Vector2i(col, row)
			if excluded.has(pos):
				continue
			var cell := maze_data.get_cell_v(pos)
			if cell == null or cell.is_dead_end():
				continue
			if _dead_end_traps.has(pos):
				continue
			candidates.append(pos)

	# Shuffle.
	for i in range(candidates.size() - 1, 0, -1):
		var j := rng.randi() % (i + 1)
		var tmp := candidates[i]
		candidates[i] = candidates[j]
		candidates[j] = tmp

	var pair_idx := 0
	var i := 0
	while pair_idx < pair_count and i + 1 < candidates.size():
		var a := candidates[i]
		var b := candidates[i + 1]
		_teleporter_pairs[a] = b
		_teleporter_pairs[b] = a
		_spawn_teleporter_visual(a, pair_idx + 1)
		_spawn_teleporter_visual(b, pair_idx + 1)
		pair_idx += 1
		i += 2


func _generate_one_way_doors(maze_data: MazeData, rng: RandomNumberGenerator,
		map_size: int, excluded: Array[Vector2i]) -> void:
	var door_count: int = Enums.HAZARD_ONE_WAY_DOORS.get(map_size, 2)
	var pathfinder := AStarPathfinder.new()
	var directions := ["top", "right", "bottom", "left"]
	var placed := 0
	var attempts := 0

	while placed < door_count and attempts < 300:
		attempts += 1
		var pos := Vector2i(rng.randi() % maze_data.width, rng.randi() % maze_data.height)
		if excluded.has(pos):
			continue

		var cell := maze_data.get_cell_v(pos)
		var open_dirs: Array[String] = []
		for d in directions:
			if not cell.walls.get(d, true):
				open_dirs.append(d)
		if open_dirs.is_empty():
			continue

		var dir: String = open_dirs[rng.randi() % open_dirs.size()]
		var neighbor := _get_neighbor(pos, dir)
		if not maze_data.is_valid(neighbor.x, neighbor.y):
			continue
		if excluded.has(neighbor):
			continue

		# Make one-way: neighbor loses its wall back to pos.
		var opposite := _get_opposite(dir)
		maze_data.get_cell_v(neighbor).set_wall(opposite, true)

		# Validate: path must exist from every spawn to exit.
		var valid := true
		var all_starts: Array[Vector2i] = [maze_data.player_spawn]
		for spawn in maze_data.ai_spawns:
			all_starts.append(spawn)
		for start in all_starts:
			if pathfinder.find_path(maze_data, start, maze_data.exit).is_empty():
				valid = false
				break

		if not valid:
			# Revert.
			maze_data.get_cell_v(neighbor).set_wall(opposite, false)
			continue

		_spawn_one_way_visual(pos, dir)
		placed += 1


# ---------- Visuals ----------

func _make_dead_end_visual() -> Node2D:
	var n := Node2D.new()
	var poly := Polygon2D.new()
	var h := float(_tile_size) * 0.85
	poly.polygon = PackedVector2Array([
		Vector2(-h, -h), Vector2(h, -h),
		Vector2(h,   h), Vector2(-h, h),
	])
	poly.color = Color(0.8, 0.05, 0.05, 0.22)
	n.add_child(poly)
	return n


func _spawn_teleporter_visual(pos: Vector2i, pair_num: int) -> void:
	var n := Node2D.new()
	var pts: PackedVector2Array
	var r := float(_tile_size) * 0.38
	for i in 16:
		var a := i * TAU / 16.0
		pts.append(Vector2(cos(a), sin(a)) * r)
	var circle := Polygon2D.new()
	circle.polygon = pts
	# Vary shade by pair index so pairs are visually distinguishable.
	var hue := 0.77 + pair_num * 0.07
	circle.color = Color.from_hsv(hue, 0.85, 0.9, 0.75)
	n.add_child(circle)
	# Inner dot for pair identity.
	var dot := Polygon2D.new()
	var dot_pts: PackedVector2Array
	var dr := float(_tile_size) * 0.12
	for i in 8:
		var a := i * TAU / 8.0
		dot_pts.append(Vector2(cos(a), sin(a)) * dr)
	dot.polygon = dot_pts
	dot.color = Color.WHITE
	n.add_child(dot)
	n.position = _renderer.get_world_position(pos)
	add_child(n)
	_teleporter_visuals[pos] = n


func _spawn_one_way_visual(pos: Vector2i, dir: String) -> void:
	var n := Node2D.new()
	var poly := Polygon2D.new()
	var s := float(_tile_size) * 0.28
	match dir:
		"right":
			poly.polygon = PackedVector2Array([
				Vector2(-s, -s * 0.55), Vector2(s * 0.7, 0.0), Vector2(-s, s * 0.55)
			])
		"left":
			poly.polygon = PackedVector2Array([
				Vector2(s, -s * 0.55), Vector2(-s * 0.7, 0.0), Vector2(s, s * 0.55)
			])
		"top":
			poly.polygon = PackedVector2Array([
				Vector2(-s * 0.55, s), Vector2(0.0, -s * 0.7), Vector2(s * 0.55, s)
			])
		"bottom":
			poly.polygon = PackedVector2Array([
				Vector2(-s * 0.55, -s), Vector2(0.0, s * 0.7), Vector2(s * 0.55, -s)
			])
	poly.color = Color(1.0, 0.82, 0.1, 0.75)
	n.add_child(poly)
	n.position = _renderer.get_world_position(pos)
	add_child(n)


# ---------- Helpers ----------

func _get_neighbor(pos: Vector2i, dir: String) -> Vector2i:
	match dir:
		"top":    return Vector2i(pos.x, pos.y - 1)
		"right":  return Vector2i(pos.x + 1, pos.y)
		"bottom": return Vector2i(pos.x, pos.y + 1)
		"left":   return Vector2i(pos.x - 1, pos.y)
	return pos


func _get_opposite(dir: String) -> String:
	match dir:
		"top":    return "bottom"
		"bottom": return "top"
		"left":   return "right"
		"right":  return "left"
	return ""
