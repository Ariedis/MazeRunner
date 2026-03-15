extends TestBase


func _init() -> void:
	_test_name = "test_fog_of_war"


func run_tests() -> void:
	_test_initial_no_explored_cells()
	_test_is_explored_false_before_reveal()
	_test_is_explored_true_after_reveal()
	_test_reveal_returns_newly_revealed_cells()
	_test_reveal_cells_are_explored_after()
	_test_reveal_does_not_return_already_explored()
	_test_already_explored_stays_in_set()
	_test_reveal_radius_2_covers_expected_cells()
	_test_reveal_radius_1_covers_expected_cells()
	_test_reveal_clips_to_maze_bounds_top_left()
	_test_reveal_clips_to_maze_bounds_bottom_right()
	_test_reveal_at_origin_does_not_go_negative()
	_test_default_reveal_radius_is_2()
	_test_get_explored_array_empty_initially()
	_test_get_explored_array_contains_revealed()
	_test_load_from_array_restores_explored()
	_test_load_from_array_then_reveal_no_overlap()
	_test_reveal_large_maze_valid_bounds()
	_test_multiple_reveals_accumulate()
	_test_reveal_radius_custom()
	_test_get_explored_array_matches_is_explored()
	_test_load_empty_array_clears_state()


func _make_fog() -> FogOfWar:
	return FogOfWar.new()


func _test_initial_no_explored_cells() -> void:
	var f := _make_fog()
	assert_equal(f.explored.size(), 0, "initial_no_explored_cells")


func _test_is_explored_false_before_reveal() -> void:
	var f := _make_fog()
	assert_false(f.is_explored(Vector2i(2, 2)), "is_explored_false_before_reveal")


func _test_is_explored_true_after_reveal() -> void:
	var f := _make_fog()
	f.reveal_radius = 0
	f.reveal(Vector2i(2, 2), 10, 10)
	assert_true(f.is_explored(Vector2i(2, 2)), "is_explored_true_after_reveal")


func _test_reveal_returns_newly_revealed_cells() -> void:
	var f := _make_fog()
	f.reveal_radius = 0
	var result := f.reveal(Vector2i(3, 3), 10, 10)
	assert_equal(result.size(), 1, "reveal_returns_one_cell_with_radius_0")
	assert_true(result.has(Vector2i(3, 3)), "reveal_returns_correct_cell")


func _test_reveal_cells_are_explored_after() -> void:
	var f := _make_fog()
	f.reveal_radius = 0
	f.reveal(Vector2i(1, 1), 10, 10)
	assert_true(f.is_explored(Vector2i(1, 1)), "revealed_cell_is_explored")


func _test_reveal_does_not_return_already_explored() -> void:
	var f := _make_fog()
	f.reveal_radius = 0
	f.reveal(Vector2i(2, 2), 10, 10)
	var second := f.reveal(Vector2i(2, 2), 10, 10)
	assert_equal(second.size(), 0, "re_reveal_returns_no_new_cells")


func _test_already_explored_stays_in_set() -> void:
	var f := _make_fog()
	f.reveal_radius = 0
	f.reveal(Vector2i(2, 2), 10, 10)
	f.reveal(Vector2i(2, 2), 10, 10)
	assert_true(f.is_explored(Vector2i(2, 2)), "already_explored_cell_persists")


func _test_reveal_radius_2_covers_expected_cells() -> void:
	var f := _make_fog()
	f.reveal_radius = 2
	var result := f.reveal(Vector2i(5, 5), 20, 20)
	assert_equal(result.size(), 25, "radius_2_covers_25_cells_in_open_space")


func _test_reveal_radius_1_covers_expected_cells() -> void:
	var f := _make_fog()
	f.reveal_radius = 1
	var result := f.reveal(Vector2i(5, 5), 20, 20)
	assert_equal(result.size(), 9, "radius_1_covers_9_cells_in_open_space")


func _test_reveal_clips_to_maze_bounds_top_left() -> void:
	var f := _make_fog()
	f.reveal_radius = 2
	var result := f.reveal(Vector2i(0, 0), 10, 10)
	for cell in result:
		assert_true(cell.x >= 0 and cell.y >= 0, "no_negative_coords_top_left")


func _test_reveal_clips_to_maze_bounds_bottom_right() -> void:
	var f := _make_fog()
	f.reveal_radius = 2
	var result := f.reveal(Vector2i(9, 9), 10, 10)
	for cell in result:
		assert_true(cell.x < 10 and cell.y < 10, "no_out_of_bounds_bottom_right")


func _test_reveal_at_origin_does_not_go_negative() -> void:
	var f := _make_fog()
	f.reveal_radius = 2
	var result := f.reveal(Vector2i(0, 0), 10, 10)
	for cell in result:
		assert_true(cell.x >= 0, "origin_reveal_x_non_negative")
		assert_true(cell.y >= 0, "origin_reveal_y_non_negative")


func _test_default_reveal_radius_is_2() -> void:
	var f := _make_fog()
	assert_equal(f.reveal_radius, 2, "default_reveal_radius_is_2")


func _test_get_explored_array_empty_initially() -> void:
	var f := _make_fog()
	assert_equal(f.get_explored_array().size(), 0, "get_explored_array_empty_initially")


func _test_get_explored_array_contains_revealed() -> void:
	var f := _make_fog()
	f.reveal_radius = 0
	f.reveal(Vector2i(3, 4), 10, 10)
	var arr := f.get_explored_array()
	assert_equal(arr.size(), 1, "get_explored_array_has_one_entry")
	assert_true(arr.has(Vector2i(3, 4)), "get_explored_array_has_correct_cell")


func _test_load_from_array_restores_explored() -> void:
	var f := _make_fog()
	var cells: Array = [Vector2i(1, 2), Vector2i(3, 4)]
	f.load_from_array(cells)
	assert_true(f.is_explored(Vector2i(1, 2)), "load_restores_cell_1_2")
	assert_true(f.is_explored(Vector2i(3, 4)), "load_restores_cell_3_4")


func _test_load_from_array_then_reveal_no_overlap() -> void:
	var f := _make_fog()
	f.load_from_array([Vector2i(5, 5)])
	f.reveal_radius = 0
	var result := f.reveal(Vector2i(5, 5), 10, 10)
	assert_equal(result.size(), 0, "loaded_cells_not_re_revealed")


func _test_reveal_large_maze_valid_bounds() -> void:
	var f := _make_fog()
	f.reveal_radius = 2
	var result := f.reveal(Vector2i(50, 50), 100, 100)
	for cell in result:
		assert_true(cell.x >= 0 and cell.x < 100, "large_maze_x_in_bounds")
		assert_true(cell.y >= 0 and cell.y < 100, "large_maze_y_in_bounds")


func _test_multiple_reveals_accumulate() -> void:
	var f := _make_fog()
	f.reveal_radius = 0
	f.reveal(Vector2i(1, 1), 10, 10)
	f.reveal(Vector2i(2, 2), 10, 10)
	f.reveal(Vector2i(3, 3), 10, 10)
	assert_equal(f.explored.size(), 3, "multiple_reveals_accumulate_to_3")


func _test_reveal_radius_custom() -> void:
	var f := _make_fog()
	f.reveal_radius = 3
	var result := f.reveal(Vector2i(5, 5), 20, 20)
	assert_equal(result.size(), 49, "radius_3_covers_49_cells_in_open_space")


func _test_get_explored_array_matches_is_explored() -> void:
	var f := _make_fog()
	f.reveal_radius = 1
	f.reveal(Vector2i(5, 5), 20, 20)
	var arr := f.get_explored_array()
	for cell in arr:
		assert_true(f.is_explored(cell), "get_explored_array_matches_is_explored")


func _test_load_empty_array_clears_state() -> void:
	var f := _make_fog()
	f.reveal_radius = 0
	f.reveal(Vector2i(3, 3), 10, 10)
	f.load_from_array([])
	assert_equal(f.explored.size(), 0, "load_empty_array_clears_explored")
	assert_false(f.is_explored(Vector2i(3, 3)), "load_empty_makes_cell_unexplored")
