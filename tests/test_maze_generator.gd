extends TestBase

var _test_name = "test_maze_generator"

func _make_maze(size: int, seed_val: int = 42) -> MazeData:
	return MazeGenerator.new().generate(size, seed_val)

func _bfs_reachable(data: MazeData, start: Vector2i) -> int:
	var visited = {}
	var queue = [start]
	visited[start] = true

	while queue.size() > 0:
		var current = queue.pop_front()
		var col = current.x
		var row = current.y
		var cell = data.get_cell(col, row)

		var dirs = [
			["top", Vector2i(col, row - 1)],
			["right", Vector2i(col + 1, row)],
			["bottom", Vector2i(col, row + 1)],
			["left", Vector2i(col - 1, row)],
		]
		for d in dirs:
			var dir_name = d[0]
			var neighbor = d[1]
			if data.is_valid(neighbor.x, neighbor.y) and not visited.has(neighbor):
				if not cell.get_wall(dir_name):
					visited[neighbor] = true
					queue.append(neighbor)

	return visited.size()

func run_tests() -> void:
	_test_small_generates_without_error()
	_test_medium_generates_without_error()
	_test_large_generates_without_error()
	_test_small_connectivity()
	_test_medium_connectivity()
	_test_large_connectivity()
	_test_small_location_count()
	_test_medium_location_count()
	_test_large_location_count()
	_test_exit_placed()
	_test_exit_in_bottom_right_quadrant()
	_test_spawn_in_top_left_quadrant()
	_test_exit_reachable_from_spawn()
	_test_same_seed_identical()
	_test_different_seeds_different()
	_test_large_performance()
	_test_location_min_distance_small()
	_test_grid_dimensions_small()
	_test_grid_dimensions_medium()
	_test_grid_dimensions_large()
	_test_all_cells_have_passage()
	_test_scene_manager_has_game_scene_constant()

func _test_small_generates_without_error() -> void:
	var data = _make_maze(Enums.MapSize.SMALL)
	assert_true(data != null, "small_generates_without_error")
	assert_true(data is MazeData, "small_is_maze_data")

func _test_medium_generates_without_error() -> void:
	var data = _make_maze(Enums.MapSize.MEDIUM)
	assert_true(data != null, "medium_generates_without_error")
	assert_true(data is MazeData, "medium_is_maze_data")

func _test_large_generates_without_error() -> void:
	var data = _make_maze(Enums.MapSize.LARGE)
	assert_true(data != null, "large_generates_without_error")
	assert_true(data is MazeData, "large_is_maze_data")

func _test_small_connectivity() -> void:
	var data = _make_maze(Enums.MapSize.SMALL)
	var reachable = _bfs_reachable(data, Vector2i(0, 0))
	assert_equal(reachable, 15 * 15, "small_connectivity")

func _test_medium_connectivity() -> void:
	var data = _make_maze(Enums.MapSize.MEDIUM)
	var reachable = _bfs_reachable(data, Vector2i(0, 0))
	assert_equal(reachable, 25 * 25, "medium_connectivity")

func _test_large_connectivity() -> void:
	var data = _make_maze(Enums.MapSize.LARGE)
	var reachable = _bfs_reachable(data, Vector2i(0, 0))
	assert_equal(reachable, 40 * 40, "large_connectivity")

func _test_small_location_count() -> void:
	var data = _make_maze(Enums.MapSize.SMALL)
	assert_equal(data.locations.size(), 4, "small_location_count")

func _test_medium_location_count() -> void:
	var data = _make_maze(Enums.MapSize.MEDIUM)
	assert_equal(data.locations.size(), 8, "medium_location_count")

func _test_large_location_count() -> void:
	var data = _make_maze(Enums.MapSize.LARGE)
	assert_equal(data.locations.size(), 14, "large_location_count")

func _test_exit_placed() -> void:
	var data = _make_maze(Enums.MapSize.SMALL)
	assert_true(data.exit != Vector2i(-1, -1), "exit_placed_position")
	assert_true(data.get_cell_v(data.exit).is_exit, "exit_cell_flag")

func _test_exit_in_bottom_right_quadrant() -> void:
	var data = _make_maze(Enums.MapSize.SMALL)
	var exit = data.exit
	assert_true(exit.x >= 7 and exit.y >= 7, "exit_in_bottom_right_quadrant")

func _test_spawn_in_top_left_quadrant() -> void:
	var data = _make_maze(Enums.MapSize.SMALL)
	var spawn = data.player_spawn
	assert_true(spawn.x < 7 and spawn.y < 7, "spawn_in_top_left_quadrant")

func _test_exit_reachable_from_spawn() -> void:
	var data = _make_maze(Enums.MapSize.SMALL)
	# BFS from spawn, check if exit is visited
	var visited = {}
	var queue = [data.player_spawn]
	visited[data.player_spawn] = true

	while queue.size() > 0:
		var current = queue.pop_front()
		var col = current.x
		var row = current.y
		var cell = data.get_cell(col, row)

		var dirs = [
			["top", Vector2i(col, row - 1)],
			["right", Vector2i(col + 1, row)],
			["bottom", Vector2i(col, row + 1)],
			["left", Vector2i(col - 1, row)],
		]
		for d in dirs:
			var dir_name = d[0]
			var neighbor = d[1]
			if data.is_valid(neighbor.x, neighbor.y) and not visited.has(neighbor):
				if not cell.get_wall(dir_name):
					visited[neighbor] = true
					queue.append(neighbor)

	assert_true(visited.has(data.exit), "exit_reachable_from_spawn")

func _test_same_seed_identical() -> void:
	var data1 = _make_maze(Enums.MapSize.SMALL, 12345)
	var data2 = _make_maze(Enums.MapSize.SMALL, 12345)

	# Compare walls in top-left 5x5
	var walls_match = true
	for row in 5:
		for col in 5:
			var c1 = data1.get_cell(col, row)
			var c2 = data2.get_cell(col, row)
			for dir in ["top", "right", "bottom", "left"]:
				if c1.get_wall(dir) != c2.get_wall(dir):
					walls_match = false
					break

	assert_true(walls_match, "same_seed_walls_match")
	assert_equal(data1.exit, data2.exit, "same_seed_exit_match")
	assert_equal(data1.player_spawn, data2.player_spawn, "same_seed_spawn_match")

func _test_different_seeds_different() -> void:
	var data1 = _make_maze(Enums.MapSize.MEDIUM, 11111)
	var data2 = _make_maze(Enums.MapSize.MEDIUM, 99999)

	var found_difference = false
	for row in data1.height:
		if found_difference:
			break
		for col in data1.width:
			if found_difference:
				break
			var c1 = data1.get_cell(col, row)
			var c2 = data2.get_cell(col, row)
			for dir in ["top", "right", "bottom", "left"]:
				if c1.get_wall(dir) != c2.get_wall(dir):
					found_difference = true
					break

	assert_true(found_difference, "different_seeds_different")

func _test_large_performance() -> void:
	var start = Time.get_ticks_msec()
	var _data = _make_maze(Enums.MapSize.LARGE)
	var elapsed = Time.get_ticks_msec() - start
	assert_true(elapsed < 1000, "large_performance_under_1000ms")

func _test_location_min_distance_small() -> void:
	var data = _make_maze(Enums.MapSize.SMALL)
	var min_required = max(3, 15 / 4)
	var all_ok = true
	for i in data.locations.size():
		for j in range(i + 1, data.locations.size()):
			var dist = abs(data.locations[i].x - data.locations[j].x) + abs(data.locations[i].y - data.locations[j].y)
			if dist < min_required:
				all_ok = false
				break
	assert_true(all_ok, "location_min_distance_small")

func _test_grid_dimensions_small() -> void:
	var data = _make_maze(Enums.MapSize.SMALL)
	assert_equal(data.width, 15, "grid_width_small")
	assert_equal(data.height, 15, "grid_height_small")

func _test_grid_dimensions_medium() -> void:
	var data = _make_maze(Enums.MapSize.MEDIUM)
	assert_equal(data.width, 25, "grid_width_medium")
	assert_equal(data.height, 25, "grid_height_medium")

func _test_grid_dimensions_large() -> void:
	var data = _make_maze(Enums.MapSize.LARGE)
	assert_equal(data.width, 40, "grid_width_large")
	assert_equal(data.height, 40, "grid_height_large")

func _test_all_cells_have_passage() -> void:
	var data = _make_maze(Enums.MapSize.SMALL)
	var all_ok = true
	for row in data.height:
		for col in data.width:
			var cell = data.get_cell(col, row)
			var wall_count = 0
			for w in cell.walls.values():
				if w: wall_count += 1
			if wall_count == 4:
				all_ok = false
				break
	assert_true(all_ok, "all_cells_have_passage")

func _test_scene_manager_has_game_scene_constant() -> void:
	assert_true(SceneManager.SCENE_GAME_SCENE.length() > 0, "scene_manager_has_game_scene_constant")
