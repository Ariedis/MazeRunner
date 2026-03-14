extends TestBase


func _init() -> void:
	_test_name = "test_enums"


func run_tests() -> void:
	_test_game_state_values()
	_test_map_size_values()
	_test_difficulty_values()
	_test_map_size_data()
	_test_constants()


func _test_game_state_values() -> void:
	assert_equal(Enums.GameState.MENU, 0, "GameState.MENU == 0")
	assert_equal(Enums.GameState.CHARACTER_SELECT, 1, "GameState.CHARACTER_SELECT == 1")
	assert_equal(Enums.GameState.NEW_GAME, 2, "GameState.NEW_GAME == 2")
	assert_equal(Enums.GameState.IN_GAME, 3, "GameState.IN_GAME == 3")
	assert_equal(Enums.GameState.PAUSED, 4, "GameState.PAUSED == 4")
	assert_equal(Enums.GameState.GAME_OVER, 5, "GameState.GAME_OVER == 5")
	assert_equal(Enums.GameState.LOAD_GAME, 6, "GameState.LOAD_GAME == 6")


func _test_map_size_values() -> void:
	assert_equal(Enums.MapSize.SMALL, 0, "MapSize.SMALL == 0")
	assert_equal(Enums.MapSize.MEDIUM, 1, "MapSize.MEDIUM == 1")
	assert_equal(Enums.MapSize.LARGE, 2, "MapSize.LARGE == 2")


func _test_difficulty_values() -> void:
	assert_equal(Enums.Difficulty.EASY, 0, "Difficulty.EASY == 0")
	assert_equal(Enums.Difficulty.MEDIUM, 1, "Difficulty.MEDIUM == 1")
	assert_equal(Enums.Difficulty.HARD, 2, "Difficulty.HARD == 2")


func _test_map_size_data() -> void:
	var small: Dictionary = Enums.MAP_SIZE_DATA[Enums.MapSize.SMALL]
	assert_equal(small["grid_width"], 15, "SMALL grid_width == 15")
	assert_equal(small["grid_height"], 15, "SMALL grid_height == 15")
	assert_equal(small["location_count"], 4, "SMALL location_count == 4")
	assert_equal(small["max_opponents"], 2, "SMALL max_opponents == 2")
	assert_equal(small["cell_px"], 64, "SMALL cell_px == 64")

	var medium: Dictionary = Enums.MAP_SIZE_DATA[Enums.MapSize.MEDIUM]
	assert_equal(medium["grid_width"], 25, "MEDIUM grid_width == 25")
	assert_equal(medium["grid_height"], 25, "MEDIUM grid_height == 25")
	assert_equal(medium["location_count"], 8, "MEDIUM location_count == 8")
	assert_equal(medium["max_opponents"], 4, "MEDIUM max_opponents == 4")
	assert_equal(medium["cell_px"], 48, "MEDIUM cell_px == 48")

	var large: Dictionary = Enums.MAP_SIZE_DATA[Enums.MapSize.LARGE]
	assert_equal(large["grid_width"], 40, "LARGE grid_width == 40")
	assert_equal(large["grid_height"], 40, "LARGE grid_height == 40")
	assert_equal(large["location_count"], 14, "LARGE location_count == 14")
	assert_equal(large["max_opponents"], 6, "LARGE max_opponents == 6")
	assert_equal(large["cell_px"], 32, "LARGE cell_px == 32")


func _test_constants() -> void:
	assert_equal(Enums.MIN_SIZE, 1, "MIN_SIZE == 1")
	assert_equal(Enums.MAX_SIZE, 10, "MAX_SIZE == 10")
	assert_equal(Enums.CREATOR_BUDGET, 3, "CREATOR_BUDGET == 3")
	assert_equal(Enums.STARTING_ENERGY, 100.0, "STARTING_ENERGY == 100.0")
	assert_equal(Enums.ENERGY_DRAIN, 1.0, "ENERGY_DRAIN == 1.0")
	assert_equal(Enums.ENERGY_REGEN, 2.0, "ENERGY_REGEN == 2.0")
	assert_equal(Enums.FULL_SPEED, 150.0, "FULL_SPEED == 150.0")
	assert_equal(Enums.HALF_SPEED, 75.0, "HALF_SPEED == 75.0")
	assert_gt(Enums.FULL_SPEED, Enums.HALF_SPEED, "FULL_SPEED > HALF_SPEED")
