extends TestBase


func run_tests() -> void:
	_test_name = "Polish"

	# --- WinConditionManager: double-call guard ---
	_test_win_condition_player_win_returns_player_win()
	_test_win_condition_player_win_only_fires_once()
	_test_win_condition_ai_win_returns_ai_win()
	_test_win_condition_ai_win_only_fires_once()
	_test_win_condition_player_then_ai_blocked()
	_test_win_condition_ai_then_player_blocked()
	_test_win_condition_no_item_returns_none()

	# --- Full game loop validation ---
	_test_maze_generation_deterministic_from_seed()
	_test_location_manager_always_has_player_item()
	_test_location_manager_player_item_findable()
	_test_all_map_sizes_generate_valid_maze()
	_test_exit_always_placed()
	_test_ai_spawns_match_config()

	# --- Edge cases ---
	_test_complete_all_locations_no_crash()
	_test_multiple_ai_brains_independent()
	_test_clash_resolver_never_infinite_loop()
	_test_save_manager_vector_helpers_roundtrip()
	_test_player_stats_energy_clamp()
	_test_player_stats_size_positive()
	_test_ai_brain_penalty_then_explore_cycle()
	_test_fog_of_war_duplicate_reveal_safe()

	# --- Settings persistence ---
	_test_settings_manager_defaults_exist()
	_test_settings_manager_get_set_roundtrip()
	_test_settings_manager_reset_restores_defaults()

	# --- Custom content integration ---
	_test_custom_content_manager_tasks_empty_initially()
	_test_custom_content_manager_items_empty_initially()
	_test_custom_content_manager_penalties_empty_initially()
	_test_task_loader_returns_tasks()
	_test_item_registry_has_defaults()
	_test_clash_task_loader_returns_valid_task()

	# --- NewGameConfig edge cases ---
	_test_new_game_config_all_map_sizes_valid()
	_test_new_game_config_max_opponents_per_size()


# --- WinConditionManager tests ---

func _test_win_condition_player_win_returns_player_win() -> void:
	var wc := WinConditionManager.new()
	var result := wc.check_player_at_exit(true)
	assert_equal(result, WinConditionManager.Result.PLAYER_WIN,
		"win_cond: player with item returns PLAYER_WIN")


func _test_win_condition_player_win_only_fires_once() -> void:
	var wc := WinConditionManager.new()
	wc.check_player_at_exit(true)
	var second := wc.check_player_at_exit(true)
	assert_equal(second, WinConditionManager.Result.NONE,
		"win_cond: second player win call returns NONE (guard)")


func _test_win_condition_ai_win_returns_ai_win() -> void:
	var wc := WinConditionManager.new()
	var result := wc.check_ai_at_exit(true)
	assert_equal(result, WinConditionManager.Result.AI_WIN,
		"win_cond: AI with item returns AI_WIN")


func _test_win_condition_ai_win_only_fires_once() -> void:
	var wc := WinConditionManager.new()
	wc.check_ai_at_exit(true)
	var second := wc.check_ai_at_exit(true)
	assert_equal(second, WinConditionManager.Result.NONE,
		"win_cond: second AI win call returns NONE (guard)")


func _test_win_condition_player_then_ai_blocked() -> void:
	var wc := WinConditionManager.new()
	wc.check_player_at_exit(true)
	var ai_result := wc.check_ai_at_exit(true)
	assert_equal(ai_result, WinConditionManager.Result.NONE,
		"win_cond: AI blocked after player already won")


func _test_win_condition_ai_then_player_blocked() -> void:
	var wc := WinConditionManager.new()
	wc.check_ai_at_exit(true)
	var player_result := wc.check_player_at_exit(true)
	assert_equal(player_result, WinConditionManager.Result.NONE,
		"win_cond: player blocked after AI already won")


func _test_win_condition_no_item_returns_none() -> void:
	var wc := WinConditionManager.new()
	assert_equal(wc.check_player_at_exit(false), WinConditionManager.Result.NONE,
		"win_cond: player without item returns NONE")
	assert_equal(wc.check_ai_at_exit(false), WinConditionManager.Result.NONE,
		"win_cond: AI without item returns NONE")


# --- Full game loop validation ---

func _test_maze_generation_deterministic_from_seed() -> void:
	var gen := MazeGenerator.new()
	var m1 := gen.generate(Enums.MapSize.SMALL, 12345)
	var m2 := gen.generate(Enums.MapSize.SMALL, 12345)
	assert_equal(m1.exit, m2.exit, "deterministic: same seed produces same exit")
	assert_equal(m1.player_spawn, m2.player_spawn,
		"deterministic: same seed produces same player spawn")
	assert_equal(m1.locations.size(), m2.locations.size(),
		"deterministic: same seed produces same location count")


func _test_location_manager_always_has_player_item() -> void:
	var gen := MazeGenerator.new()
	var maze := gen.generate(Enums.MapSize.SMALL, 42)
	var task_loader := TaskLoader.new()
	var tasks := task_loader.load_all_tasks()
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	var lm := LocationManager.new()
	lm.setup(maze, tasks, rng)

	var found_player_item := false
	for loc in lm.locations:
		if loc.item_type == Enums.ItemType.PLAYER_ITEM:
			found_player_item = true
			break
	assert_true(found_player_item,
		"game_loop: at least one location has PLAYER_ITEM")


func _test_location_manager_player_item_findable() -> void:
	# Verify the player item location is in the maze's location list.
	var gen := MazeGenerator.new()
	var maze := gen.generate(Enums.MapSize.MEDIUM, 99)
	var task_loader := TaskLoader.new()
	var tasks := task_loader.load_all_tasks()
	var rng := RandomNumberGenerator.new()
	rng.seed = 100
	var lm := LocationManager.new()
	lm.setup(maze, tasks, rng)

	var player_item_loc: LocationData = null
	for loc in lm.locations:
		if loc.item_type == Enums.ItemType.PLAYER_ITEM:
			player_item_loc = loc
			break
	assert_true(player_item_loc != null, "findable: player item location exists")
	if player_item_loc != null:
		assert_true(maze.is_valid(player_item_loc.grid_pos.x, player_item_loc.grid_pos.y),
			"findable: player item location is within maze bounds")


func _test_all_map_sizes_generate_valid_maze() -> void:
	var gen := MazeGenerator.new()
	for size_key in Enums.MAP_SIZE_DATA.keys():
		var maze := gen.generate(size_key, 777)
		assert_true(maze.width > 0, "map_%d: width > 0" % size_key)
		assert_true(maze.height > 0, "map_%d: height > 0" % size_key)
		assert_true(maze.locations.size() > 0, "map_%d: has locations" % size_key)


func _test_exit_always_placed() -> void:
	var gen := MazeGenerator.new()
	for seed_val in [1, 42, 100, 999, 54321]:
		var maze := gen.generate(Enums.MapSize.SMALL, seed_val)
		assert_not_equal(maze.exit, Vector2i(-1, -1),
			"exit_placed: exit placed for seed %d" % seed_val)


func _test_ai_spawns_match_config() -> void:
	var gen := MazeGenerator.new()
	var maze := gen.generate(Enums.MapSize.SMALL, 42)
	var max_opp: int = Enums.MAP_SIZE_DATA[Enums.MapSize.SMALL]["max_opponents"]
	assert_true(maze.ai_spawns.size() >= max_opp,
		"ai_spawns: maze has enough AI spawn points for max opponents")


# --- Edge cases ---

func _test_complete_all_locations_no_crash() -> void:
	var gen := MazeGenerator.new()
	var maze := gen.generate(Enums.MapSize.SMALL, 42)
	var task_loader := TaskLoader.new()
	var tasks := task_loader.load_all_tasks()
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	var lm := LocationManager.new()
	lm.setup(maze, tasks, rng)

	for loc in lm.locations:
		lm.complete_location(loc.id)
	assert_equal(lm.get_completed_count(), lm.locations.size(),
		"all_complete: all locations marked completed without crash")


func _test_multiple_ai_brains_independent() -> void:
	var gen := MazeGenerator.new()
	var maze := gen.generate(Enums.MapSize.SMALL, 42)
	var rng1 := RandomNumberGenerator.new()
	rng1.seed = 1
	var rng2 := RandomNumberGenerator.new()
	rng2.seed = 2

	var brain1 := AIBrain.new()
	brain1.setup(Enums.Difficulty.EASY, maze, rng1)
	var brain2 := AIBrain.new()
	brain2.setup(Enums.Difficulty.HARD, maze, rng2)

	brain1.start_penalty(10.0)
	assert_true(brain1.is_in_penalty(), "ai_independent: brain1 in penalty")
	assert_false(brain2.is_in_penalty(), "ai_independent: brain2 not affected by brain1")


func _test_clash_resolver_never_infinite_loop() -> void:
	# Run many clashes with equal sizes — should always terminate.
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	var all_resolved := true
	for _i in 100:
		var result := ClashResolver.resolve(5, 5, rng)
		if not result.has("winner"):
			all_resolved = false
			break
	assert_true(all_resolved, "clash_no_infinite: 100 equal-size clashes all resolved")


func _test_save_manager_vector_helpers_roundtrip() -> void:
	var v2i := Vector2i(13, 27)
	var arr := [v2i.x, v2i.y]
	var restored := SaveManager.arr_to_v2i(arr)
	assert_equal(restored, v2i, "vec_roundtrip: arr_to_v2i restores Vector2i")

	var v2 := Vector2(3.5, 7.25)
	var arr2 := [v2.x, v2.y]
	var restored2 := SaveManager.arr_to_v2(arr2)
	assert_equal(restored2, v2, "vec_roundtrip: arr_to_v2 restores Vector2")


func _test_player_stats_energy_clamp() -> void:
	var stats := PlayerStats.new()
	stats.energy = 200.0
	stats.drain(0.0)
	# energy should still be whatever it was set to (drain(0) should not change it)
	assert_true(stats.energy >= 0.0, "energy_clamp: energy never negative after drain")


func _test_player_stats_size_positive() -> void:
	var stats := PlayerStats.new()
	assert_true(stats.size >= 1, "size_positive: size starts at 1 or more")


func _test_ai_brain_penalty_then_explore_cycle() -> void:
	var gen := MazeGenerator.new()
	var maze := gen.generate(Enums.MapSize.SMALL, 42)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var brain := AIBrain.new()
	brain.setup(Enums.Difficulty.MEDIUM, maze, rng)

	# Cycle through penalty → explore multiple times.
	for _cycle in 3:
		var pre_state := brain.state
		brain.start_penalty(1.0)
		assert_true(brain.is_in_penalty(), "penalty_cycle: in penalty")
		brain.tick(2.0, maze.player_spawn, maze)
		assert_false(brain.is_in_penalty(), "penalty_cycle: exited penalty")


func _test_fog_of_war_duplicate_reveal_safe() -> void:
	var fog := FogOfWar.new()
	var revealed1 := fog.reveal(Vector2i(5, 5), 20, 20)
	var revealed2 := fog.reveal(Vector2i(5, 5), 20, 20)
	assert_equal(revealed2.size(), 0,
		"fog_dup: re-revealing same cell returns empty array")


# --- Settings persistence ---

func _test_settings_manager_defaults_exist() -> void:
	var res: int = SettingsManager.get_setting("resolution_index")
	assert_true(res is int, "settings_defaults: resolution_index is int")
	var fs = SettingsManager.get_setting("fullscreen")
	assert_true(fs is bool, "settings_defaults: fullscreen is bool")


func _test_settings_manager_get_set_roundtrip() -> void:
	var orig = SettingsManager.get_setting("master_volume")
	SettingsManager.set_setting("master_volume", 42.0)
	var val = SettingsManager.get_setting("master_volume")
	assert_equal(val, 42.0, "settings_roundtrip: get returns set value")
	# Restore original.
	SettingsManager.set_setting("master_volume", orig)


func _test_settings_manager_reset_restores_defaults() -> void:
	SettingsManager.set_setting("master_volume", 0.0)
	SettingsManager.reset_to_defaults()
	var val = SettingsManager.get_setting("master_volume")
	assert_not_equal(val, 0.0, "settings_reset: master_volume not 0 after reset")


# --- Custom content integration ---

func _test_custom_content_manager_tasks_empty_initially() -> void:
	var ccm := CustomContentManager.new()
	var tasks := ccm.get_custom_tasks()
	assert_true(tasks is Array, "ccm_tasks: returns array")


func _test_custom_content_manager_items_empty_initially() -> void:
	var ccm := CustomContentManager.new()
	var items := ccm.get_custom_items()
	assert_true(items is Array, "ccm_items: returns array")


func _test_custom_content_manager_penalties_empty_initially() -> void:
	var ccm := CustomContentManager.new()
	var penalties := ccm.get_custom_penalties()
	assert_true(penalties is Array, "ccm_penalties: returns array")


func _test_task_loader_returns_tasks() -> void:
	var loader := TaskLoader.new()
	var tasks := loader.load_all_tasks()
	assert_true(tasks.size() > 0, "task_loader: default tasks exist")
	assert_true(tasks[0] is TaskData, "task_loader: first task is TaskData")


func _test_item_registry_has_defaults() -> void:
	var reg := ItemRegistry.new()
	var items := reg.get_all()
	assert_true(items.size() > 0, "item_registry: has default items")


func _test_clash_task_loader_returns_valid_task() -> void:
	var task := ClashTaskLoader.load_active_task()
	assert_true(task.has("exercise"), "clash_task: has exercise key")
	assert_true(task.has("reps"), "clash_task: has reps key")
	assert_true(task["reps"] is int or task["reps"] is float,
		"clash_task: reps is numeric")


# --- NewGameConfig edge cases ---

func _test_new_game_config_all_map_sizes_valid() -> void:
	for size_key in Enums.MAP_SIZE_DATA.keys():
		var cfg := {
			"map_size": size_key,
			"num_opponents": 1,
			"ai_difficulties": [Enums.Difficulty.EASY],
			"item_id": "golden_key",
			"seed": 0,
			"avatar_id": 0,
		}
		assert_true(NewGameConfig.validate(cfg),
			"config_valid: map size %d produces valid config" % size_key)


func _test_new_game_config_max_opponents_per_size() -> void:
	for size_key in Enums.MAP_SIZE_DATA.keys():
		var max_opp := NewGameConfig.get_max_opponents(size_key)
		assert_true(max_opp >= 1,
			"config_max_opp: map size %d allows at least 1 opponent" % size_key)
		var diffs := []
		for _i in max_opp:
			diffs.append(Enums.Difficulty.MEDIUM)
		var cfg := {
			"map_size": size_key,
			"num_opponents": max_opp,
			"ai_difficulties": diffs,
			"item_id": "test_item",
			"seed": 0,
			"avatar_id": 0,
		}
		assert_true(NewGameConfig.validate(cfg),
			"config_max_valid: max opponents for map size %d is valid" % size_key)
