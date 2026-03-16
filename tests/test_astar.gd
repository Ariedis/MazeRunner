extends TestBase


func run_tests() -> void:
	_test_name = "AStarPathfinder"
	_test_same_start_end()
	_test_path_includes_endpoints()
	_test_path_no_duplicate_cells()
	_test_all_steps_have_open_passage()
	_test_path_found_small_spawn_to_exit()
	_test_path_found_medium_spawn_to_exit()
	_test_path_found_large_spawn_to_exit()
	_test_invalid_from_returns_empty()
	_test_invalid_to_returns_empty()
	_test_passable_neighbors_bounded_by_walls()
	_test_passable_neighbors_at_least_one_in_valid_maze()
	_test_path_optimal_length_straight_corridor()
	_test_path_is_deterministic()
	_test_large_maze_performance()
	_test_multi_path_stress()


# --- Helpers ---

func _make_maze(size: int) -> MazeData:
	var gen := MazeGenerator.new()
	return gen.generate(size, 12345)


func _path_has_open_passage(maze: MazeData, path: Array[Vector2i]) -> bool:
	var pf := AStarPathfinder.new()
	for i in range(path.size() - 1):
		var a := path[i]
		var b := path[i + 1]
		var neighbors := pf.get_passable_neighbors(maze, a)
		if not neighbors.has(b):
			return false
	return true


# --- Tests ---

func _test_same_start_end() -> void:
	var maze := _make_maze(Enums.MapSize.SMALL)
	var pf := AStarPathfinder.new()
	var path := pf.find_path(maze, maze.player_spawn, maze.player_spawn)
	assert_equal(path.size(), 1, "same_start_end: path length 1")
	assert_equal(path[0], maze.player_spawn, "same_start_end: contains only start")


func _test_path_includes_endpoints() -> void:
	var maze := _make_maze(Enums.MapSize.SMALL)
	var pf := AStarPathfinder.new()
	var path := pf.find_path(maze, maze.player_spawn, maze.exit)
	assert_true(path.size() >= 2, "endpoints: path has at least 2 cells")
	assert_equal(path[0], maze.player_spawn, "endpoints: first cell is spawn")
	assert_equal(path[path.size() - 1], maze.exit, "endpoints: last cell is exit")


func _test_path_no_duplicate_cells() -> void:
	var maze := _make_maze(Enums.MapSize.SMALL)
	var pf := AStarPathfinder.new()
	var path := pf.find_path(maze, maze.player_spawn, maze.exit)
	var seen: Dictionary = {}
	var ok := true
	for cell in path:
		if seen.has(cell):
			ok = false
			break
		seen[cell] = true
	assert_true(ok, "no_duplicates: all cells unique")


func _test_all_steps_have_open_passage() -> void:
	var maze := _make_maze(Enums.MapSize.SMALL)
	var pf := AStarPathfinder.new()
	var path := pf.find_path(maze, maze.player_spawn, maze.exit)
	assert_true(_path_has_open_passage(maze, path), "open_passage: every step traversable")


func _test_path_found_small_spawn_to_exit() -> void:
	var maze := _make_maze(Enums.MapSize.SMALL)
	var pf := AStarPathfinder.new()
	var path := pf.find_path(maze, maze.player_spawn, maze.exit)
	assert_true(path.size() > 0, "small_path: found")


func _test_path_found_medium_spawn_to_exit() -> void:
	var maze := _make_maze(Enums.MapSize.MEDIUM)
	var pf := AStarPathfinder.new()
	var path := pf.find_path(maze, maze.player_spawn, maze.exit)
	assert_true(path.size() > 0, "medium_path: found")


func _test_path_found_large_spawn_to_exit() -> void:
	var maze := _make_maze(Enums.MapSize.LARGE)
	var pf := AStarPathfinder.new()
	var path := pf.find_path(maze, maze.player_spawn, maze.exit)
	assert_true(path.size() > 0, "large_path: found")


func _test_invalid_from_returns_empty() -> void:
	var maze := _make_maze(Enums.MapSize.SMALL)
	var pf := AStarPathfinder.new()
	var path := pf.find_path(maze, Vector2i(-1, -1), maze.exit)
	assert_equal(path.size(), 0, "invalid_from: empty path")


func _test_invalid_to_returns_empty() -> void:
	var maze := _make_maze(Enums.MapSize.SMALL)
	var pf := AStarPathfinder.new()
	var path := pf.find_path(maze, maze.player_spawn, Vector2i(9999, 9999))
	assert_equal(path.size(), 0, "invalid_to: empty path")


func _test_passable_neighbors_bounded_by_walls() -> void:
	var maze := _make_maze(Enums.MapSize.SMALL)
	var pf := AStarPathfinder.new()
	# Every neighbor returned must be within maze bounds.
	var ok := true
	for row in maze.height:
		for col in maze.width:
			var neighbors := pf.get_passable_neighbors(maze, Vector2i(col, row))
			for nb in neighbors:
				if not maze.is_valid(nb.x, nb.y):
					ok = false
	assert_true(ok, "neighbors_bounded: all within maze bounds")


func _test_passable_neighbors_at_least_one_in_valid_maze() -> void:
	# DFS-generated maze guarantees every cell has ≥1 passage.
	var maze := _make_maze(Enums.MapSize.SMALL)
	var pf := AStarPathfinder.new()
	var ok := true
	for row in maze.height:
		for col in maze.width:
			var neighbors := pf.get_passable_neighbors(maze, Vector2i(col, row))
			if neighbors.is_empty():
				ok = false
	assert_true(ok, "neighbors_nonempty: every cell has ≥1 passage")


func _test_path_optimal_length_straight_corridor() -> void:
	# Build a simple 5x1 corridor maze manually.
	var data := MazeData.new(5, 1)
	for col in 4:
		data.get_cell(col, 0).set_wall("right", false)
		data.get_cell(col + 1, 0).set_wall("left", false)

	var pf := AStarPathfinder.new()
	var path := pf.find_path(data, Vector2i(0, 0), Vector2i(4, 0))
	assert_equal(path.size(), 5, "optimal_length: corridor path is 5 cells")


func _test_path_is_deterministic() -> void:
	var maze := _make_maze(Enums.MapSize.SMALL)
	var pf := AStarPathfinder.new()
	var path1 := pf.find_path(maze, maze.player_spawn, maze.exit)
	var path2 := pf.find_path(maze, maze.player_spawn, maze.exit)
	assert_equal(path1, path2, "deterministic: same maze same path")


func _test_large_maze_performance() -> void:
	var gen := MazeGenerator.new()
	var t0 := Time.get_ticks_msec()
	var maze := gen.generate(Enums.MapSize.LARGE, 99999)
	var pf := AStarPathfinder.new()
	pf.find_path(maze, maze.player_spawn, maze.exit)
	var elapsed := Time.get_ticks_msec() - t0
	assert_true(elapsed < 500, "performance: large maze A* under 500ms (took %dms)" % elapsed)


func _test_multi_path_stress() -> void:
	var gen := MazeGenerator.new()
	var maze := gen.generate(Enums.MapSize.LARGE, 54321)
	var pf := AStarPathfinder.new()
	var rng := RandomNumberGenerator.new()
	rng.seed = 11111
	var t0 := Time.get_ticks_msec()
	for i in 10:
		var a := Vector2i(rng.randi_range(0, maze.width - 1), rng.randi_range(0, maze.height - 1))
		var b := Vector2i(rng.randi_range(0, maze.width - 1), rng.randi_range(0, maze.height - 1))
		var path := pf.find_path(maze, a, b)
		# Path should be non-empty (fully connected DFS maze).
		assert_true(path.size() > 0, "stress_%d: path found" % i)
	var elapsed := Time.get_ticks_msec() - t0
	assert_true(elapsed < 2000, "stress_perf: 10 large paths under 2000ms (took %dms)" % elapsed)
