extends TestBase


func run_tests() -> void:
	_test_name = "ClashSystem"

	# --- ClashResolver: dice roll ---
	_test_roll_d6_range()
	_test_roll_d6_returns_int()

	# --- ClashResolver: resolve ---
	_test_resolve_higher_total_wins()
	_test_resolve_winner_a_when_a_higher()
	_test_resolve_winner_b_when_b_higher()
	_test_resolve_tie_causes_reroll()
	_test_resolve_returns_reroll_count()
	_test_resolve_total_equals_roll_plus_size()

	# --- ClashResolver: penalty weight ---
	_test_weight_size_1_is_1kg()
	_test_weight_size_3_is_1kg()
	_test_weight_size_4_is_2kg()
	_test_weight_size_7_is_2kg()
	_test_weight_size_8_is_3kg()
	_test_weight_size_10_is_3kg()

	# --- ClashResolver: penalty speed ---
	_test_speed_above_80_is_quickly()
	_test_speed_exactly_80_is_normal()
	_test_speed_at_50_is_normal()
	_test_speed_below_50_is_slowly()

	# --- ClashResolver: penalty duration ---
	_test_duration_above_80_is_15s()
	_test_duration_exactly_80_is_25s()
	_test_duration_at_50_is_25s()
	_test_duration_below_50_is_40s()

	# --- ClashTaskLoader: default task ---
	_test_default_task_has_exercise()
	_test_default_task_has_reps()
	_test_default_task_exercise_is_bicep_curls()
	_test_default_task_reps_is_10()
	_test_custom_task_loads_from_file()

	# --- AIBrain: PENALTY state ---
	_test_penalty_state_value_unique()
	_test_start_penalty_sets_state()
	_test_start_penalty_sets_timer()
	_test_is_in_penalty_true_when_penalty()
	_test_is_in_penalty_false_when_not_penalty()
	_test_penalty_tick_counts_down()
	_test_penalty_tick_not_below_zero()
	_test_penalty_restores_state_after_expiry()
	_test_penalty_clears_path()
	_test_penalty_no_energy_regen_during_task()
	_test_multiple_clashes_sequence()


# --- Helpers ---

func _make_rng(seed_val: int = 1) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_val
	return rng


func _make_small_maze() -> MazeData:
	var gen := MazeGenerator.new()
	return gen.generate(Enums.MapSize.SMALL, 42)


func _make_brain(diff: int = Enums.Difficulty.MEDIUM) -> AIBrain:
	var maze := _make_small_maze()
	var rng := _make_rng(7)
	var brain := AIBrain.new()
	brain.setup(diff, maze, rng)
	return brain


# --- Dice roll tests ---

func _test_roll_d6_range() -> void:
	var rng := _make_rng(12345)
	var all_in_range := true
	for i in 200:
		var v := ClashResolver.roll_d6(rng)
		if v < 1 or v > 6:
			all_in_range = false
			break
	assert_true(all_in_range, "roll_d6: all results in 1-6 range")


func _test_roll_d6_returns_int() -> void:
	var rng := _make_rng(1)
	var v := ClashResolver.roll_d6(rng)
	assert_true(v is int, "roll_d6: result is int")


# --- Resolve tests ---

func _test_resolve_higher_total_wins() -> void:
	# Force deterministic outcome: size_a = 10, size_b = 1.
	# Even a roll of 1 for A (total=11) beats roll of 6 for B (total=7) consistently.
	var rng := _make_rng(999)
	var result := ClashResolver.resolve(10, 1, rng)
	assert_equal(result["winner"], "a", "resolve: large size_a always wins over tiny size_b")


func _test_resolve_winner_a_when_a_higher() -> void:
	var rng := _make_rng(1)
	var result := ClashResolver.resolve(10, 1, rng)
	assert_equal(result["winner"], "a", "resolve_winner_a: a wins with size 10 vs 1")
	assert_true(result["total_a"] > result["total_b"],
		"resolve_winner_a: total_a > total_b when a wins")


func _test_resolve_winner_b_when_b_higher() -> void:
	var rng := _make_rng(1)
	var result := ClashResolver.resolve(1, 10, rng)
	assert_equal(result["winner"], "b", "resolve_winner_b: b wins with size 10 vs 1")
	assert_true(result["total_b"] > result["total_a"],
		"resolve_winner_b: total_b > total_a when b wins")


func _test_resolve_tie_causes_reroll() -> void:
	# With equal sizes, ties are possible. Run many iterations to find at least one reroll.
	# This test verifies the function eventually returns even under tie conditions.
	var rng := _make_rng(7)
	var found_reroll := false
	for _i in 500:
		var result := ClashResolver.resolve(3, 3, rng)
		if result["rerolls"] > 0:
			found_reroll = true
			break
	# With equal sizes ties happen ~1/6 of the time, so 500 trials should encounter one.
	assert_true(found_reroll, "resolve_tie: rerolls > 0 occurs with equal sizes")


func _test_resolve_returns_reroll_count() -> void:
	var rng := _make_rng(1)
	var result := ClashResolver.resolve(5, 5, rng)
	assert_true(result.has("rerolls"), "resolve_rerolls_key: result has rerolls key")
	assert_true(result["rerolls"] >= 0, "resolve_rerolls_non_neg: rerolls >= 0")


func _test_resolve_total_equals_roll_plus_size() -> void:
	var rng := _make_rng(42)
	var result := ClashResolver.resolve(4, 6, rng)
	assert_equal(result["total_a"], result["roll_a"] + 4, "resolve_total_a: total_a = roll_a + size_a")
	assert_equal(result["total_b"], result["roll_b"] + 6, "resolve_total_b: total_b = roll_b + size_b")


# --- Penalty weight tests ---

func _test_weight_size_1_is_1kg() -> void:
	assert_equal(ClashResolver.get_penalty_weight(1), "1kg", "weight: size=1 → 1kg")


func _test_weight_size_3_is_1kg() -> void:
	assert_equal(ClashResolver.get_penalty_weight(3), "1kg", "weight: size=3 (boundary) → 1kg")


func _test_weight_size_4_is_2kg() -> void:
	assert_equal(ClashResolver.get_penalty_weight(4), "2kg", "weight: size=4 (boundary) → 2kg")


func _test_weight_size_7_is_2kg() -> void:
	assert_equal(ClashResolver.get_penalty_weight(7), "2kg", "weight: size=7 (boundary) → 2kg")


func _test_weight_size_8_is_3kg() -> void:
	assert_equal(ClashResolver.get_penalty_weight(8), "3kg", "weight: size=8 (boundary) → 3kg")


func _test_weight_size_10_is_3kg() -> void:
	assert_equal(ClashResolver.get_penalty_weight(10), "3kg", "weight: size=10 → 3kg")


# --- Penalty speed tests ---

func _test_speed_above_80_is_quickly() -> void:
	assert_equal(ClashResolver.get_penalty_speed(100.0), "QUICKLY", "speed: energy=100 → QUICKLY")
	assert_equal(ClashResolver.get_penalty_speed(80.1), "QUICKLY", "speed: energy=80.1 → QUICKLY")


func _test_speed_exactly_80_is_normal() -> void:
	assert_equal(ClashResolver.get_penalty_speed(80.0), "normal speed",
		"speed: energy=80 (boundary) → normal speed")


func _test_speed_at_50_is_normal() -> void:
	assert_equal(ClashResolver.get_penalty_speed(50.0), "normal speed",
		"speed: energy=50 (boundary) → normal speed")


func _test_speed_below_50_is_slowly() -> void:
	assert_equal(ClashResolver.get_penalty_speed(49.9), "SLOWLY", "speed: energy=49.9 → SLOWLY")
	assert_equal(ClashResolver.get_penalty_speed(0.0), "SLOWLY", "speed: energy=0 → SLOWLY")


# --- Penalty duration tests ---

func _test_duration_above_80_is_15s() -> void:
	assert_equal(ClashResolver.get_penalty_duration(100.0), 15.0, "duration: energy=100 → 15s")
	assert_equal(ClashResolver.get_penalty_duration(80.1), 15.0, "duration: energy=80.1 → 15s")


func _test_duration_exactly_80_is_25s() -> void:
	assert_equal(ClashResolver.get_penalty_duration(80.0), 25.0,
		"duration: energy=80 (boundary) → 25s")


func _test_duration_at_50_is_25s() -> void:
	assert_equal(ClashResolver.get_penalty_duration(50.0), 25.0,
		"duration: energy=50 (boundary) → 25s")


func _test_duration_below_50_is_40s() -> void:
	assert_equal(ClashResolver.get_penalty_duration(49.9), 40.0, "duration: energy=49.9 → 40s")
	assert_equal(ClashResolver.get_penalty_duration(0.0), 40.0, "duration: energy=0 → 40s")


# --- ClashTaskLoader tests ---

func _test_default_task_has_exercise() -> void:
	var task := ClashTaskLoader.load_active_task()
	assert_true(task.has("exercise"), "task_loader: result has 'exercise' key")


func _test_default_task_has_reps() -> void:
	var task := ClashTaskLoader.load_active_task()
	assert_true(task.has("reps"), "task_loader: result has 'reps' key")


func _test_default_task_exercise_is_bicep_curls() -> void:
	# Assumes no custom file exists in the test environment.
	if not FileAccess.file_exists("user://clash_tasks.json"):
		var task := ClashTaskLoader.load_active_task()
		assert_equal(task["exercise"], "Bicep Curls",
			"task_loader_default: exercise is Bicep Curls")


func _test_default_task_reps_is_10() -> void:
	if not FileAccess.file_exists("user://clash_tasks.json"):
		var task := ClashTaskLoader.load_active_task()
		assert_equal(task["reps"], 10, "task_loader_default: reps = 10")


func _test_custom_task_loads_from_file() -> void:
	# Write a custom task file, load it, verify it loads correctly, then clean up.
	var path := "user://clash_tasks.json"
	var custom := '{"exercise": "Push-ups", "reps": 20}'
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		# Cannot write to user:// in this environment — skip gracefully.
		_pass("task_loader_custom: skipped (cannot write user://)")
		return
	file.store_string(custom)
	file.close()

	var task := ClashTaskLoader.load_active_task()
	assert_equal(task["exercise"], "Push-ups", "task_loader_custom: exercise from file")
	assert_equal(task["reps"], 20, "task_loader_custom: reps from file")

	# Cleanup.
	DirAccess.remove_absolute(path)


# --- AIBrain PENALTY state tests ---

func _test_penalty_state_value_unique() -> void:
	# PENALTY must not collide with other states.
	var values := [
		AIBrain.State.EXPLORE,
		AIBrain.State.GO_TO_LOC,
		AIBrain.State.DO_TASK,
		AIBrain.State.GO_TO_EXIT,
		AIBrain.State.RESTING,
	]
	assert_false(values.has(AIBrain.State.PENALTY),
		"penalty_state: PENALTY value distinct from other states")


func _test_start_penalty_sets_state() -> void:
	var brain := _make_brain()
	brain.start_penalty(25.0)
	assert_equal(brain.state, AIBrain.State.PENALTY, "start_penalty: state = PENALTY")


func _test_start_penalty_sets_timer() -> void:
	var brain := _make_brain()
	brain.start_penalty(40.0)
	assert_equal(brain.penalty_timer, 40.0, "start_penalty: penalty_timer set to duration")


func _test_is_in_penalty_true_when_penalty() -> void:
	var brain := _make_brain()
	brain.start_penalty(25.0)
	assert_true(brain.is_in_penalty(), "is_in_penalty: true when state=PENALTY")


func _test_is_in_penalty_false_when_not_penalty() -> void:
	var brain := _make_brain()
	assert_false(brain.is_in_penalty(), "is_in_penalty: false initially")


func _test_penalty_tick_counts_down() -> void:
	var brain := _make_brain()
	var maze := _make_small_maze()
	brain.start_penalty(25.0)
	brain.tick(5.0, maze.player_spawn, maze)
	assert_equal(brain.penalty_timer, 20.0, "penalty_tick: timer decrements by delta")


func _test_penalty_tick_not_below_zero() -> void:
	var brain := _make_brain()
	var maze := _make_small_maze()
	brain.start_penalty(5.0)
	brain.tick(100.0, maze.player_spawn, maze)
	assert_true(brain.penalty_timer >= 0.0, "penalty_tick_floor: timer >= 0 after large delta")


func _test_penalty_restores_state_after_expiry() -> void:
	var brain := _make_brain()
	var maze := _make_small_maze()
	brain.state = AIBrain.State.EXPLORE
	brain.start_penalty(5.0)
	assert_equal(brain.state, AIBrain.State.PENALTY, "penalty_restore: state is PENALTY")
	# Tick past expiry.
	brain.tick(10.0, maze.player_spawn, maze)
	assert_equal(brain.state, AIBrain.State.EXPLORE,
		"penalty_restore: state restored to EXPLORE after expiry")


func _test_penalty_clears_path() -> void:
	var brain := _make_brain()
	brain.current_path = [Vector2i(1, 1), Vector2i(2, 2)]
	brain.start_penalty(25.0)
	assert_true(brain.current_path.is_empty(), "penalty_clear_path: path cleared on start_penalty")


func _test_penalty_no_energy_regen_during_task() -> void:
	# Energy does not regen during penalty — this is enforced in AIOpponent._physics_process.
	# We verify the brain stays in PENALTY state (not returning early) without modifying energy.
	var brain := _make_brain()
	var maze := _make_small_maze()
	brain.start_penalty(25.0)
	brain.tick(1.0, maze.player_spawn, maze)
	# Brain should still be in PENALTY (24s remaining) — no state escape.
	assert_true(brain.is_in_penalty(), "penalty_no_regen: still in PENALTY after 1s tick")
	assert_equal(brain.penalty_timer, 24.0, "penalty_no_regen: timer at 24s after 1s tick")


func _test_multiple_clashes_sequence() -> void:
	# Verify a brain can enter and exit PENALTY multiple times cleanly.
	var brain := _make_brain()
	var maze := _make_small_maze()

	brain.start_penalty(5.0)
	assert_true(brain.is_in_penalty(), "multi_clash: in PENALTY on first clash")
	brain.tick(10.0, maze.player_spawn, maze)
	assert_false(brain.is_in_penalty(), "multi_clash: exited PENALTY after first")

	brain.start_penalty(15.0)
	assert_true(brain.is_in_penalty(), "multi_clash: in PENALTY on second clash")
	brain.tick(20.0, maze.player_spawn, maze)
	assert_false(brain.is_in_penalty(), "multi_clash: exited PENALTY after second")
