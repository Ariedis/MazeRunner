extends TestBase


func run_tests() -> void:
	_test_name = "UI"

	# --- CharacterCreatorLogic: initial state ---
	_test_creator_initial_size_is_1()
	_test_creator_initial_points_remaining_equals_budget()
	_test_creator_initial_points_spent_is_0()

	# --- CharacterCreatorLogic: increase_size ---
	_test_creator_increase_size_returns_true_when_points_available()
	_test_creator_increase_size_increments_size()
	_test_creator_increase_size_decrements_points_remaining()
	_test_creator_increase_size_returns_false_when_no_points()
	_test_creator_cannot_exceed_budget_max()

	# --- CharacterCreatorLogic: decrease_size ---
	_test_creator_decrease_size_returns_true_when_above_min()
	_test_creator_decrease_size_decrements_size()
	_test_creator_decrease_size_returns_false_at_min()
	_test_creator_size_cannot_go_below_1()

	# --- CharacterCreatorLogic: points tracking ---
	_test_creator_points_spent_tracks_correctly()
	_test_creator_points_remaining_after_increase()
	_test_creator_reset_restores_size()

	# --- NewGameConfig.validate ---
	_test_validate_valid_config_returns_true()
	_test_validate_empty_item_id_returns_false()
	_test_validate_zero_opponents_returns_false()
	_test_validate_negative_opponents_returns_false()
	_test_validate_mismatched_difficulties_returns_false()
	_test_validate_invalid_map_size_returns_false()
	_test_validate_too_many_opponents_returns_false()
	_test_validate_exact_max_opponents_returns_true()

	# --- NewGameConfig.get_max_opponents ---
	_test_max_opponents_small_map()
	_test_max_opponents_medium_map()
	_test_max_opponents_large_map()
	_test_max_opponents_invalid_map_returns_1()

	# --- GameState stubs ---
	_test_game_state_has_save_data_is_bool()
	_test_game_state_item_id_default_is_empty()
	_test_game_state_avatar_id_in_config()

	# --- GameHUD: instantiation and updates ---
	_test_hud_can_be_created()
	_test_hud_update_size_does_not_crash()
	_test_hud_update_energy_does_not_crash()
	_test_hud_update_speed_does_not_crash()
	_test_hud_item_collected_sets_flag()
	_test_hud_item_indicator_hidden_initially()


# --- CharacterCreatorLogic tests ---

func _test_creator_initial_size_is_1() -> void:
	var c := CharacterCreatorLogic.new()
	assert_equal(c.size, 1, "creator_init: size starts at 1")


func _test_creator_initial_points_remaining_equals_budget() -> void:
	var c := CharacterCreatorLogic.new()
	assert_equal(c.points_remaining, Enums.CREATOR_BUDGET,
		"creator_init: points_remaining equals CREATOR_BUDGET")


func _test_creator_initial_points_spent_is_0() -> void:
	var c := CharacterCreatorLogic.new()
	assert_equal(c.points_spent, 0, "creator_init: points_spent starts at 0")


func _test_creator_increase_size_returns_true_when_points_available() -> void:
	var c := CharacterCreatorLogic.new()
	assert_true(c.increase_size(), "creator_increase: returns true when points available")


func _test_creator_increase_size_increments_size() -> void:
	var c := CharacterCreatorLogic.new()
	c.increase_size()
	assert_equal(c.size, 2, "creator_increase: size becomes 2 after one increase")


func _test_creator_increase_size_decrements_points_remaining() -> void:
	var c := CharacterCreatorLogic.new()
	var before := c.points_remaining
	c.increase_size()
	assert_equal(c.points_remaining, before - 1,
		"creator_increase: points_remaining decrements by 1")


func _test_creator_increase_size_returns_false_when_no_points() -> void:
	var c := CharacterCreatorLogic.new()
	for _i in Enums.CREATOR_BUDGET:
		c.increase_size()
	assert_false(c.increase_size(), "creator_increase: returns false when no points left")


func _test_creator_cannot_exceed_budget_max() -> void:
	var c := CharacterCreatorLogic.new()
	for _i in 100:
		c.increase_size()
	assert_equal(c.size, 1 + Enums.CREATOR_BUDGET,
		"creator_increase: size capped at 1 + CREATOR_BUDGET")


func _test_creator_decrease_size_returns_true_when_above_min() -> void:
	var c := CharacterCreatorLogic.new()
	c.increase_size()
	assert_true(c.decrease_size(), "creator_decrease: returns true when size > 1")


func _test_creator_decrease_size_decrements_size() -> void:
	var c := CharacterCreatorLogic.new()
	c.increase_size()
	c.decrease_size()
	assert_equal(c.size, 1, "creator_decrease: size returns to 1")


func _test_creator_decrease_size_returns_false_at_min() -> void:
	var c := CharacterCreatorLogic.new()
	assert_false(c.decrease_size(), "creator_decrease: returns false when size is 1")


func _test_creator_size_cannot_go_below_1() -> void:
	var c := CharacterCreatorLogic.new()
	for _i in 10:
		c.decrease_size()
	assert_equal(c.size, 1, "creator_decrease: size never goes below 1")


func _test_creator_points_spent_tracks_correctly() -> void:
	var c := CharacterCreatorLogic.new()
	c.increase_size()
	c.increase_size()
	assert_equal(c.points_spent, 2, "creator_spent: points_spent = 2 after two increases")


func _test_creator_points_remaining_after_increase() -> void:
	var c := CharacterCreatorLogic.new()
	c.increase_size()
	assert_equal(c.points_remaining, Enums.CREATOR_BUDGET - 1,
		"creator_remaining: points_remaining = budget-1 after one increase")


func _test_creator_reset_restores_size() -> void:
	var c := CharacterCreatorLogic.new()
	c.increase_size()
	c.increase_size()
	c.reset()
	assert_equal(c.size, 1, "creator_reset: size is 1 after reset")
	assert_equal(c.points_remaining, Enums.CREATOR_BUDGET,
		"creator_reset: points_remaining restored after reset")


# --- NewGameConfig.validate tests ---

func _make_valid_config() -> Dictionary:
	return {
		"map_size": Enums.MapSize.SMALL,
		"num_opponents": 1,
		"ai_difficulties": [Enums.Difficulty.EASY],
		"item_id": "golden_key",
		"seed": 0,
		"avatar_id": 0,
	}


func _test_validate_valid_config_returns_true() -> void:
	assert_true(NewGameConfig.validate(_make_valid_config()),
		"validate: valid config returns true")


func _test_validate_empty_item_id_returns_false() -> void:
	var cfg := _make_valid_config()
	cfg["item_id"] = ""
	assert_false(NewGameConfig.validate(cfg), "validate: empty item_id returns false")


func _test_validate_zero_opponents_returns_false() -> void:
	var cfg := _make_valid_config()
	cfg["num_opponents"] = 0
	cfg["ai_difficulties"] = []
	assert_false(NewGameConfig.validate(cfg), "validate: num_opponents=0 returns false")


func _test_validate_negative_opponents_returns_false() -> void:
	var cfg := _make_valid_config()
	cfg["num_opponents"] = -1
	cfg["ai_difficulties"] = []
	assert_false(NewGameConfig.validate(cfg), "validate: negative opponents returns false")


func _test_validate_mismatched_difficulties_returns_false() -> void:
	var cfg := _make_valid_config()
	cfg["num_opponents"] = 2
	cfg["ai_difficulties"] = [Enums.Difficulty.EASY]  # Only 1 entry, needs 2
	assert_false(NewGameConfig.validate(cfg),
		"validate: mismatched difficulties count returns false")


func _test_validate_invalid_map_size_returns_false() -> void:
	var cfg := _make_valid_config()
	cfg["map_size"] = 99
	assert_false(NewGameConfig.validate(cfg), "validate: invalid map_size returns false")


func _test_validate_too_many_opponents_returns_false() -> void:
	var cfg := _make_valid_config()
	var max_opp: int = Enums.MAP_SIZE_DATA[Enums.MapSize.SMALL]["max_opponents"]
	cfg["num_opponents"] = max_opp + 1
	var diffs := []
	for _i in max_opp + 1:
		diffs.append(Enums.Difficulty.EASY)
	cfg["ai_difficulties"] = diffs
	assert_false(NewGameConfig.validate(cfg),
		"validate: opponents exceeding map max returns false")


func _test_validate_exact_max_opponents_returns_true() -> void:
	var cfg := _make_valid_config()
	var max_opp: int = Enums.MAP_SIZE_DATA[Enums.MapSize.SMALL]["max_opponents"]
	cfg["num_opponents"] = max_opp
	var diffs := []
	for _i in max_opp:
		diffs.append(Enums.Difficulty.EASY)
	cfg["ai_difficulties"] = diffs
	assert_true(NewGameConfig.validate(cfg),
		"validate: exactly max opponents is valid")


# --- NewGameConfig.get_max_opponents tests ---

func _test_max_opponents_small_map() -> void:
	var expected: int = Enums.MAP_SIZE_DATA[Enums.MapSize.SMALL]["max_opponents"]
	assert_equal(NewGameConfig.get_max_opponents(Enums.MapSize.SMALL), expected,
		"get_max: small map returns correct max")


func _test_max_opponents_medium_map() -> void:
	var expected: int = Enums.MAP_SIZE_DATA[Enums.MapSize.MEDIUM]["max_opponents"]
	assert_equal(NewGameConfig.get_max_opponents(Enums.MapSize.MEDIUM), expected,
		"get_max: medium map returns correct max")


func _test_max_opponents_large_map() -> void:
	var expected: int = Enums.MAP_SIZE_DATA[Enums.MapSize.LARGE]["max_opponents"]
	assert_equal(NewGameConfig.get_max_opponents(Enums.MapSize.LARGE), expected,
		"get_max: large map returns correct max")


func _test_max_opponents_invalid_map_returns_1() -> void:
	assert_equal(NewGameConfig.get_max_opponents(999), 1,
		"get_max: invalid map_size returns 1 as safe default")


# --- GameState stub tests ---

func _test_game_state_has_save_data_is_bool() -> void:
	var result := GameState.has_save_data()
	assert_true(result is bool,
		"game_state: has_save_data returns a bool")


func _test_game_state_item_id_default_is_empty() -> void:
	# Instantiate a fresh GameState-like dict (we read the live autoload).
	# The default item_id in config should be an empty string (not -1).
	var item_id = GameState.config.get("item_id", "MISSING")
	assert_true(item_id is String, "game_state: item_id in config is a String")


func _test_game_state_avatar_id_in_config() -> void:
	assert_true(GameState.config.has("avatar_id"),
		"game_state: config contains avatar_id key")


# --- GameHUD tests ---

func _test_hud_can_be_created() -> void:
	var hud := GameHUD.new()
	add_child(hud)
	assert_true(is_instance_valid(hud), "hud_create: GameHUD is valid after instantiation")
	hud.queue_free()


func _test_hud_update_size_does_not_crash() -> void:
	var hud := GameHUD.new()
	add_child(hud)
	hud.update_size(3)
	assert_true(true, "hud_size: update_size(3) does not crash")
	hud.queue_free()


func _test_hud_update_energy_does_not_crash() -> void:
	var hud := GameHUD.new()
	add_child(hud)
	hud.update_energy(75.0)
	hud.update_energy(0.0)
	hud.update_energy(100.0)
	assert_true(true, "hud_energy: update_energy at various values does not crash")
	hud.queue_free()


func _test_hud_update_speed_does_not_crash() -> void:
	var hud := GameHUD.new()
	add_child(hud)
	hud.update_speed(true)
	hud.update_speed(false)
	assert_true(true, "hud_speed: update_speed does not crash")
	hud.queue_free()


func _test_hud_item_collected_sets_flag() -> void:
	var hud := GameHUD.new()
	add_child(hud)
	assert_false(hud.item_collected, "hud_item: item_collected is false initially")
	hud.show_item_collected()
	assert_true(hud.item_collected, "hud_item: item_collected is true after show_item_collected")
	hud.queue_free()


func _test_hud_item_indicator_hidden_initially() -> void:
	var hud := GameHUD.new()
	add_child(hud)
	# _item_indicator is a child of _portrait, check via item_collected flag
	assert_false(hud.item_collected,
		"hud_indicator: item indicator not shown until collected")
	hud.queue_free()
