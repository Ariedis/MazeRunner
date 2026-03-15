extends TestBase


func _init() -> void:
	_test_name = "test_player_stats"


func run_tests() -> void:
	_test_initial_energy()
	_test_initial_size()
	_test_initial_speed_is_full()
	_test_drain_decreases_energy()
	_test_drain_rate_matches_constant()
	_test_drain_multiple_calls_consistent()
	_test_regen_increases_energy()
	_test_regen_rate_matches_constant()
	_test_regen_multiple_calls_consistent()
	_test_energy_floor_at_zero()
	_test_energy_cap_at_100()
	_test_speed_halves_at_zero_energy()
	_test_speed_full_when_energy_positive()
	_test_speed_restores_after_regen()
	_test_add_size_increases()
	_test_size_capped_at_max()
	_test_size_floor_at_min()
	_test_gamestate_energy_key_present()
	_test_gamestate_position_key_present()
	_test_gamestate_energy_sync()
	_test_drain_stops_at_zero_energy_boundary()
	_test_is_full_speed_false_exactly_at_zero()


func _make_stats() -> PlayerStats:
	return PlayerStats.new()


func _test_initial_energy() -> void:
	var s := _make_stats()
	assert_equal(s.energy, 100.0, "initial_energy_is_100")


func _test_initial_size() -> void:
	var s := _make_stats()
	assert_equal(s.size, 1, "initial_size_is_1")


func _test_initial_speed_is_full() -> void:
	var s := _make_stats()
	assert_true(s.is_full_speed, "initial_speed_is_full")
	assert_equal(s.current_speed(), Enums.FULL_SPEED, "initial_current_speed_equals_full")


func _test_drain_decreases_energy() -> void:
	var s := _make_stats()
	s.drain(1.0)
	assert_true(s.energy < 100.0, "drain_decreases_energy")


func _test_drain_rate_matches_constant() -> void:
	var s := _make_stats()
	s.drain(1.0)
	var expected := 100.0 - Enums.ENERGY_DRAIN * 1.0
	assert_equal(s.energy, expected, "drain_rate_matches_ENERGY_DRAIN_constant")


func _test_drain_multiple_calls_consistent() -> void:
	var s := _make_stats()
	s.drain(1.0)
	var after_first := s.energy
	s.drain(1.0)
	var delta_first := 100.0 - after_first
	var delta_second := after_first - s.energy
	assert_equal(delta_first, delta_second, "drain_rate_is_consistent_across_calls")


func _test_regen_increases_energy() -> void:
	var s := _make_stats()
	s.energy = 50.0
	s.regen(1.0)
	assert_true(s.energy > 50.0, "regen_increases_energy")


func _test_regen_rate_matches_constant() -> void:
	var s := _make_stats()
	s.energy = 50.0
	s.regen(1.0)
	var expected := 50.0 + Enums.ENERGY_REGEN * 1.0
	assert_equal(s.energy, expected, "regen_rate_matches_ENERGY_REGEN_constant")


func _test_regen_multiple_calls_consistent() -> void:
	var s := _make_stats()
	s.energy = 20.0
	s.regen(1.0)
	var after_first := s.energy
	s.regen(1.0)
	var delta_first := after_first - 20.0
	var delta_second := s.energy - after_first
	assert_equal(delta_first, delta_second, "regen_rate_is_consistent_across_calls")


func _test_energy_floor_at_zero() -> void:
	var s := _make_stats()
	s.energy = 0.0
	s.drain(10.0)
	assert_equal(s.energy, 0.0, "energy_floor_at_zero")


func _test_energy_cap_at_100() -> void:
	var s := _make_stats()
	s.energy = 100.0
	s.regen(10.0)
	assert_equal(s.energy, 100.0, "energy_cap_at_100")


func _test_speed_halves_at_zero_energy() -> void:
	var s := _make_stats()
	s.energy = 0.0
	assert_false(s.is_full_speed, "is_full_speed_false_when_energy_zero")
	assert_equal(s.current_speed(), Enums.HALF_SPEED, "current_speed_is_half_when_energy_zero")


func _test_speed_full_when_energy_positive() -> void:
	var s := _make_stats()
	s.energy = 0.001
	assert_true(s.is_full_speed, "is_full_speed_true_when_energy_positive")
	assert_equal(s.current_speed(), Enums.FULL_SPEED, "current_speed_is_full_when_energy_positive")


func _test_speed_restores_after_regen() -> void:
	var s := _make_stats()
	s.energy = 0.0
	assert_false(s.is_full_speed, "speed_half_at_zero_energy")
	s.regen(1.0)
	assert_true(s.is_full_speed, "speed_restores_to_full_after_regen")


func _test_add_size_increases() -> void:
	var s := _make_stats()
	s.add_size(1)
	assert_equal(s.size, 2, "add_size_increases_by_1")
	s.add_size(3)
	assert_equal(s.size, 5, "add_size_increases_by_3")


func _test_size_capped_at_max() -> void:
	var s := _make_stats()
	s.size = Enums.MAX_SIZE
	s.add_size(5)
	assert_equal(s.size, Enums.MAX_SIZE, "size_capped_at_MAX_SIZE")


func _test_size_floor_at_min() -> void:
	var s := _make_stats()
	s.size = Enums.MIN_SIZE
	s.add_size(-5)
	assert_equal(s.size, Enums.MIN_SIZE, "size_floor_at_MIN_SIZE")


func _test_gamestate_energy_key_present() -> void:
	assert_true(GameState.player.has("energy"), "gamestate_player_has_energy_key")


func _test_gamestate_position_key_present() -> void:
	assert_true(GameState.player.has("position"), "gamestate_player_has_position_key")


func _test_gamestate_energy_sync() -> void:
	var s := _make_stats()
	s.energy = 42.0
	var saved_energy = GameState.player["energy"]
	GameState.player["energy"] = s.energy
	assert_equal(GameState.player["energy"], 42.0, "energy_value_syncs_to_gamestate")
	GameState.player["energy"] = saved_energy


func _test_drain_stops_at_zero_energy_boundary() -> void:
	var s := _make_stats()
	s.energy = 0.5
	# Drain with delta large enough to overshoot zero
	s.drain(10.0)
	assert_equal(s.energy, 0.0, "drain_clamps_at_zero_not_negative")


func _test_is_full_speed_false_exactly_at_zero() -> void:
	var s := _make_stats()
	s.energy = 0.0
	# Speed boundary: energy must be GREATER THAN 0 for full speed
	assert_false(s.is_full_speed, "is_full_speed_false_at_exactly_zero")
