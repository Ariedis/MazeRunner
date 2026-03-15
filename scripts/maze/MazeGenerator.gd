class_name MazeGenerator
extends RefCounted

var _map_size: int

func generate(map_size: int, seed_override: int = -1) -> MazeData:
	_map_size = map_size
	var size_data = Enums.MAP_SIZE_DATA[map_size]
	var w = size_data["grid_width"]
	var h = size_data["grid_height"]

	var rng = RandomNumberGenerator.new()
	var actual_seed = seed_override if seed_override != -1 else rng.randi()
	rng.seed = actual_seed

	var data = MazeData.new(w, h)
	data.seed_val = actual_seed

	_run_dfs(data, rng)
	_place_exit(data, rng)
	_place_player_spawn(data, rng)
	_place_locations(data, rng)
	_place_ai_spawns(data, rng, size_data["max_opponents"])
	return data

func _run_dfs(data: MazeData, rng: RandomNumberGenerator) -> void:
	var start_cell = data.get_cell(0, 0)
	start_cell.visited = true
	var stack = [[0, 0]]

	while stack.size() > 0:
		var current = stack.back()
		var ccol = current[0]
		var crow = current[1]

		var neighbors = []
		var directions = [
			["top", ccol, crow - 1],
			["right", ccol + 1, crow],
			["bottom", ccol, crow + 1],
			["left", ccol - 1, crow],
		]
		for d in directions:
			var dir = d[0]
			var nc = d[1]
			var nr = d[2]
			if data.is_valid(nc, nr) and not data.get_cell(nc, nr).visited:
				neighbors.append([dir, nc, nr])

		if neighbors.size() == 0:
			stack.pop_back()
		else:
			var chosen = neighbors[rng.randi() % neighbors.size()]
			var dir = chosen[0]
			var nc = chosen[1]
			var nr = chosen[2]

			data.get_cell(ccol, crow).set_wall(dir, false)
			data.get_cell(nc, nr).set_wall(_get_opposite(dir), false)
			data.get_cell(nc, nr).visited = true
			stack.push_back([nc, nr])

func _get_opposite(dir: String) -> String:
	match dir:
		"top": return "bottom"
		"bottom": return "top"
		"left": return "right"
		"right": return "left"
	return ""

func _get_quadrant_cells(data: MazeData, quadrant: int) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	var half_w = data.width / 2
	var half_h = data.height / 2
	for row in data.height:
		for col in data.width:
			var in_q = false
			match quadrant:
				0: in_q = col < half_w and row < half_h
				1: in_q = col >= half_w and row < half_h
				2: in_q = col < half_w and row >= half_h
				3: in_q = col >= half_w and row >= half_h
			if in_q:
				result.append(Vector2i(col, row))
	return result

func _place_exit(data: MazeData, rng: RandomNumberGenerator) -> void:
	var q3_cells = _get_quadrant_cells(data, 3)

	# Prefer dead-ends in quadrant 3
	var dead_ends: Array[Vector2i] = []
	for pos in q3_cells:
		if data.get_cell_v(pos).is_dead_end():
			dead_ends.append(pos)

	var candidates = dead_ends if dead_ends.size() > 0 else q3_cells
	if candidates.size() == 0:
		return

	var chosen = candidates[rng.randi() % candidates.size()]
	data.exit = chosen
	data.get_cell_v(chosen).is_exit = true

func _place_player_spawn(data: MazeData, rng: RandomNumberGenerator) -> void:
	var q0_cells = _get_quadrant_cells(data, 0)

	# Exclude exit position
	var filtered: Array[Vector2i] = []
	for pos in q0_cells:
		if pos != data.exit:
			filtered.append(pos)

	# Prefer dead-ends
	var dead_ends: Array[Vector2i] = []
	for pos in filtered:
		if data.get_cell_v(pos).is_dead_end():
			dead_ends.append(pos)

	var candidates = dead_ends if dead_ends.size() > 0 else filtered
	if candidates.size() == 0:
		return

	var chosen = candidates[rng.randi() % candidates.size()]
	data.player_spawn = chosen
	data.get_cell_v(chosen).is_spawn = true

func _place_locations(data: MazeData, rng: RandomNumberGenerator) -> void:
	var size_data = Enums.MAP_SIZE_DATA[_map_size]
	var location_count = size_data["location_count"]
	var min_dist = max(3, size_data["grid_width"] / location_count)

	# Build candidate pool excluding player_spawn and exit
	var all_cells: Array[Vector2i] = []
	for row in data.height:
		for col in data.width:
			var pos = Vector2i(col, row)
			if pos != data.player_spawn and pos != data.exit:
				all_cells.append(pos)

	# Fisher-Yates shuffle
	_shuffle(all_cells, rng)

	# Try placing with current min_dist, retry with decreasing distance
	while min_dist >= 1:
		var placed: Array[Vector2i] = []
		for pos in all_cells:
			if placed.size() >= location_count:
				break
			var too_close = false
			for existing in placed:
				if _manhattan_distance(pos, existing) < min_dist:
					too_close = true
					break
			if not too_close:
				placed.append(pos)

		if placed.size() >= location_count:
			for pos in placed:
				data.locations.append(pos)
				data.get_cell_v(pos).has_location = true
			return

		min_dist -= 1

func _place_ai_spawns(data: MazeData, rng: RandomNumberGenerator, count: int) -> void:
	var excluded: Array[Vector2i] = []
	excluded.append(data.player_spawn)
	excluded.append(data.exit)
	for loc in data.locations:
		excluded.append(loc)

	var remaining: Array[Vector2i] = []
	for row in data.height:
		for col in data.width:
			var pos = Vector2i(col, row)
			if not excluded.has(pos):
				remaining.append(pos)

	_shuffle(remaining, rng)

	for i in min(count, remaining.size()):
		data.ai_spawns.append(remaining[i])

func _manhattan_distance(a: Vector2i, b: Vector2i) -> int:
	return abs(a.x - b.x) + abs(a.y - b.y)

func _shuffle(arr: Array, rng: RandomNumberGenerator) -> void:
	for i in range(arr.size() - 1, 0, -1):
		var j = rng.randi() % (i + 1)
		var tmp = arr[i]
		arr[i] = arr[j]
		arr[j] = tmp
