extends TestBase


func run_tests() -> void:
	_test_name = "AIBrain"
	_test_initial_state_explore()
	_test_initial_has_item_false()
	_test_hard_knows_all_locations()
	_test_easy_knows_no_locations()
	_test_medium_knows_no_locations()
	_test_hard_knows_exit()
	_test_easy_exit_unknown()
	_test_item_loc_assigned_from_maze()
	_test_tick_do_task_counts_down()
	_test_tick_do_task_not_below_zero()
	_test_on_step_marks_explored()
	_test_easy_discovers_location_on_step()
	_test_hard_does_not_need_step_to_know_location()
	_test_easy_discovers_exit_on_step()
	_test_start_task_state_do_task()
	_test_easy_task_timer_longer_than_hard()
	_test_on_task_complete_got_item_has_item_true()
	_test_on_task_complete_got_item_state_go_to_exit()
	_test_on_task_complete_not_item_state_explore()
	_test_on_task_complete_removes_from_known()
	_test_on_step_at_exit_with_item_returns_true()
	_test_on_step_at_exit_without_item_returns_false()
	_test_get_next_step_empty_returns_invalid()
	_test_is_doing_task_true_in_do_task()
	_test_tick_explore_transitions_to_go_to_loc()
	_test_tick_go_to_exit_when_has_item_and_exit_known()
	_test_speed_multiplier_values_exist()
	_test_speed_multiplier_easy_lt_medium_lt_hard()
	_test_rest_enters_resting_when_low_energy()
	_test_rest_restores_previous_state()
	_test_rest_threshold_per_difficulty()
	_test_rest_skipped_when_going_to_exit()
	_test_location_completed_externally_clears_path()
	_test_location_completed_externally_preserves_other_path()
	_test_location_completed_externally_removes_from_known()


# --- Helpers ---

func _make_small_maze() -> MazeData:
	var gen := MazeGenerator.new()
	return gen.generate(Enums.MapSize.SMALL, 42)


func _make_rng(seed_val: int = 1) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_val
	return rng


func _make_brain(diff: int, maze: MazeData, seed_val: int = 1) -> AIBrain:
	var brain := AIBrain.new()
	brain.setup(diff, maze, _make_rng(seed_val))
	return brain


# --- Tests ---

func _test_initial_state_explore() -> void:
	var maze := _make_small_maze()
	var brain := _make_brain(Enums.Difficulty.EASY, maze)
	assert_equal(brain.state, AIBrain.State.EXPLORE, "initial_state: EXPLORE for EASY")


func _test_initial_has_item_false() -> void:
	var maze := _make_small_maze()
	var brain := _make_brain(Enums.Difficulty.MEDIUM, maze)
	assert_false(brain.has_item, "initial_has_item: false")


func _test_hard_knows_all_locations() -> void:
	var maze := _make_small_maze()
	var brain := _make_brain(Enums.Difficulty.HARD, maze)
	assert_equal(brain.known_uncompleted_locs.size(), maze.locations.size(),
		"hard_locations: pre-populated with all maze locations")


func _test_easy_knows_no_locations() -> void:
	var maze := _make_small_maze()
	var brain := _make_brain(Enums.Difficulty.EASY, maze)
	assert_equal(brain.known_uncompleted_locs.size(), 0, "easy_locations: empty at start")


func _test_medium_knows_no_locations() -> void:
	var maze := _make_small_maze()
	var brain := _make_brain(Enums.Difficulty.MEDIUM, maze)
	assert_equal(brain.known_uncompleted_locs.size(), 0, "medium_locations: empty at start")


func _test_hard_knows_exit() -> void:
	var maze := _make_small_maze()
	var brain := _make_brain(Enums.Difficulty.HARD, maze)
	assert_true(brain.exit_known, "hard_exit: exit_known = true")
	assert_equal(brain.exit_pos, maze.exit, "hard_exit: exit_pos matches maze exit")


func _test_easy_exit_unknown() -> void:
	var maze := _make_small_maze()
	var brain := _make_brain(Enums.Difficulty.EASY, maze)
	assert_false(brain.exit_known, "easy_exit: exit_known = false at start")


func _test_item_loc_assigned_from_maze() -> void:
	var maze := _make_small_maze()
	var brain := _make_brain(Enums.Difficulty.MEDIUM, maze)
	assert_true(maze.locations.has(brain._item_loc_pos),
		"item_loc: assigned from maze locations array")


func _test_tick_do_task_counts_down() -> void:
	var maze := _make_small_maze()
	var brain := _make_brain(Enums.Difficulty.MEDIUM, maze)
	var loc_pos := maze.locations[0]
	brain.start_task(10.0, loc_pos)  # 10.0 * 1.0 = 10.0
	assert_equal(brain.task_timer, 10.0, "tick_countdown: timer starts at 10.0")
	brain.tick(1.0, Vector2i(0, 0), maze)
	assert_equal(brain.task_timer, 9.0, "tick_countdown: timer at 9.0 after 1s tick")


func _test_tick_do_task_not_below_zero() -> void:
	var maze := _make_small_maze()
	var brain := _make_brain(Enums.Difficulty.MEDIUM, maze)
	brain.start_task(0.5, maze.locations[0])
	brain.tick(10.0, Vector2i(0, 0), maze)
	assert_equal(brain.task_timer, 0.0, "tick_floor: timer does not go below 0")


func _test_on_step_marks_explored() -> void:
	var maze := _make_small_maze()
	var brain := _make_brain(Enums.Difficulty.EASY, maze)
	var pos := Vector2i(1, 1)
	assert_false(brain.explored.has(pos), "explored: pos not explored before step")
	brain.on_step_reached(pos, maze)
	assert_true(brain.explored.has(pos), "explored: pos marked after on_step_reached")


func _test_easy_discovers_location_on_step() -> void:
	var maze := _make_small_maze()
	var brain := _make_brain(Enums.Difficulty.EASY, maze)
	var loc_pos := maze.locations[0]
	assert_false(brain.known_uncompleted_locs.has(loc_pos), "discover_loc: not known before")
	brain.on_step_reached(loc_pos, maze)
	assert_true(brain.known_uncompleted_locs.has(loc_pos),
		"discover_loc: added after stepping on location cell")


func _test_hard_does_not_need_step_to_know_location() -> void:
	var maze := _make_small_maze()
	var brain := _make_brain(Enums.Difficulty.HARD, maze)
	# Hard AI already knows all locations from setup — no step needed.
	for pos in maze.locations:
		assert_true(brain.known_uncompleted_locs.has(pos),
			"hard_preknown: loc %s already in known list" % str(pos))


func _test_easy_discovers_exit_on_step() -> void:
	var maze := _make_small_maze()
	var brain := _make_brain(Enums.Difficulty.EASY, maze)
	assert_false(brain.exit_known, "exit_discover: not known before step")
	brain.on_step_reached(maze.exit, maze)
	assert_true(brain.exit_known, "exit_discover: known after stepping on exit cell")
	assert_equal(brain.exit_pos, maze.exit, "exit_discover: exit_pos set correctly")


func _test_start_task_state_do_task() -> void:
	var maze := _make_small_maze()
	var brain := _make_brain(Enums.Difficulty.MEDIUM, maze)
	brain.start_task(20.0, maze.locations[0])
	assert_equal(brain.state, AIBrain.State.DO_TASK, "start_task: state = DO_TASK")
	assert_true(brain.is_doing_task(), "start_task: is_doing_task() = true")
	assert_equal(brain.task_timer, 20.0, "start_task: medium timer = 20 * 1.0")


func _test_easy_task_timer_longer_than_hard() -> void:
	var maze := _make_small_maze()
	var easy_brain := _make_brain(Enums.Difficulty.EASY, maze, 1)
	var hard_brain := _make_brain(Enums.Difficulty.HARD, maze, 1)
	var loc := maze.locations[0]
	easy_brain.start_task(20.0, loc)
	hard_brain.start_task(20.0, loc)
	assert_gt(easy_brain.task_timer, hard_brain.task_timer,
		"difficulty_timer: easy timer > hard timer")


func _test_on_task_complete_got_item_has_item_true() -> void:
	var maze := _make_small_maze()
	var brain := _make_brain(Enums.Difficulty.MEDIUM, maze)
	# Force _item_loc_pos to a known location.
	var loc_pos := maze.locations[0]
	brain._item_loc_pos = loc_pos
	brain.known_uncompleted_locs.append(loc_pos)
	brain.start_task(20.0, loc_pos)
	brain.on_task_complete()
	assert_true(brain.has_item, "got_item: has_item = true after completing item location")


func _test_on_task_complete_got_item_state_go_to_exit() -> void:
	var maze := _make_small_maze()
	var brain := _make_brain(Enums.Difficulty.MEDIUM, maze)
	var loc_pos := maze.locations[0]
	brain._item_loc_pos = loc_pos
	brain.known_uncompleted_locs.append(loc_pos)
	brain.start_task(20.0, loc_pos)
	brain.on_task_complete()
	assert_equal(brain.state, AIBrain.State.GO_TO_EXIT,
		"got_item_state: GO_TO_EXIT after collecting item")


func _test_on_task_complete_not_item_state_explore() -> void:
	var maze := _make_small_maze()
	var brain := _make_brain(Enums.Difficulty.MEDIUM, maze)
	# Complete a non-item location (known_uncompleted_locs will be empty after).
	var other_pos := maze.locations[0]
	brain._item_loc_pos = Vector2i(-99, -99)  # item is elsewhere
	brain.known_uncompleted_locs.append(other_pos)
	brain.start_task(20.0, other_pos)
	brain.on_task_complete()
	assert_false(brain.has_item, "not_item: has_item still false")
	assert_equal(brain.state, AIBrain.State.EXPLORE,
		"not_item_state: EXPLORE when no more known locations")


func _test_on_task_complete_removes_from_known() -> void:
	var maze := _make_small_maze()
	var brain := _make_brain(Enums.Difficulty.MEDIUM, maze)
	var loc_pos := maze.locations[0]
	brain.known_uncompleted_locs.append(loc_pos)
	brain.start_task(20.0, loc_pos)
	brain.on_task_complete()
	assert_false(brain.known_uncompleted_locs.has(loc_pos),
		"remove_known: location removed from known list after task")


func _test_on_step_at_exit_with_item_returns_true() -> void:
	var maze := _make_small_maze()
	var brain := _make_brain(Enums.Difficulty.EASY, maze)
	brain.has_item = true
	var result := brain.on_step_reached(maze.exit, maze)
	assert_true(result, "win_condition: returns true at exit with item")


func _test_on_step_at_exit_without_item_returns_false() -> void:
	var maze := _make_small_maze()
	var brain := _make_brain(Enums.Difficulty.EASY, maze)
	brain.has_item = false
	var result := brain.on_step_reached(maze.exit, maze)
	assert_false(result, "no_win: returns false at exit without item")


func _test_get_next_step_empty_returns_invalid() -> void:
	var maze := _make_small_maze()
	var brain := _make_brain(Enums.Difficulty.MEDIUM, maze)
	# Fresh brain has no path.
	assert_equal(brain.get_next_step(), Vector2i(-1, -1),
		"next_step_empty: returns (-1,-1) with no path")


func _test_is_doing_task_true_in_do_task() -> void:
	var maze := _make_small_maze()
	var brain := _make_brain(Enums.Difficulty.MEDIUM, maze)
	assert_false(brain.is_doing_task(), "is_doing_task: false initially")
	brain.start_task(10.0, maze.locations[0])
	assert_true(brain.is_doing_task(), "is_doing_task: true after start_task")


func _test_tick_explore_transitions_to_go_to_loc() -> void:
	var maze := _make_small_maze()
	var brain := _make_brain(Enums.Difficulty.EASY, maze)
	assert_equal(brain.state, AIBrain.State.EXPLORE, "pre_transition: state is EXPLORE")
	brain.known_uncompleted_locs.append(maze.locations[0])
	brain.tick(0.0, maze.player_spawn, maze)
	assert_equal(brain.state, AIBrain.State.GO_TO_LOC,
		"transition: EXPLORE→GO_TO_LOC when location known")


func _test_tick_go_to_exit_when_has_item_and_exit_known() -> void:
	var maze := _make_small_maze()
	var brain := _make_brain(Enums.Difficulty.EASY, maze)
	brain.has_item = true
	brain.exit_known = true
	brain.exit_pos = maze.exit
	brain.tick(0.0, maze.player_spawn, maze)
	assert_equal(brain.state, AIBrain.State.GO_TO_EXIT,
		"transition: GO_TO_EXIT when has_item and exit_known")


# --- Speed multiplier tests ---

func _test_speed_multiplier_values_exist() -> void:
	assert_true(Enums.AI_SPEED_MULTIPLIER.has(0), "speed_mult: EASY key exists")
	assert_true(Enums.AI_SPEED_MULTIPLIER.has(1), "speed_mult: MEDIUM key exists")
	assert_true(Enums.AI_SPEED_MULTIPLIER.has(2), "speed_mult: HARD key exists")


func _test_speed_multiplier_easy_lt_medium_lt_hard() -> void:
	var easy: float = Enums.AI_SPEED_MULTIPLIER[0]
	var medium: float = Enums.AI_SPEED_MULTIPLIER[1]
	var hard: float = Enums.AI_SPEED_MULTIPLIER[2]
	assert_true(easy < medium, "speed_order: EASY < MEDIUM")
	assert_true(medium < hard, "speed_order: MEDIUM < HARD")


# --- Energy rest tests ---

func _test_rest_enters_resting_when_low_energy() -> void:
	var maze := _make_small_maze()
	var brain := _make_brain(Enums.Difficulty.MEDIUM, maze)
	brain.state = AIBrain.State.EXPLORE
	# Medium rest threshold is 20.0; pass energy below that.
	brain.tick(0.0, maze.player_spawn, maze, 15.0)
	assert_equal(brain.state, AIBrain.State.RESTING,
		"rest_enter: enters RESTING when energy below threshold")


func _test_rest_restores_previous_state() -> void:
	var maze := _make_small_maze()
	var brain := _make_brain(Enums.Difficulty.MEDIUM, maze)
	brain.state = AIBrain.State.EXPLORE
	# Enter resting.
	brain.tick(0.0, maze.player_spawn, maze, 15.0)
	assert_equal(brain.state, AIBrain.State.RESTING, "rest_restore: in RESTING")
	# Restore when energy reaches target (50.0 for medium).
	brain.tick(0.0, maze.player_spawn, maze, 55.0)
	assert_equal(brain.state, AIBrain.State.EXPLORE,
		"rest_restore: restored to EXPLORE after energy recovered")


func _test_rest_threshold_per_difficulty() -> void:
	var maze := _make_small_maze()
	var easy_brain := _make_brain(Enums.Difficulty.EASY, maze, 1)
	var hard_brain := _make_brain(Enums.Difficulty.HARD, maze, 1)
	assert_true(easy_brain._rest_threshold > hard_brain._rest_threshold,
		"rest_thresh: EASY threshold > HARD threshold")


func _test_rest_skipped_when_going_to_exit() -> void:
	var maze := _make_small_maze()
	var brain := _make_brain(Enums.Difficulty.MEDIUM, maze)
	brain.has_item = true
	brain.exit_known = true
	brain.exit_pos = maze.exit
	brain.state = AIBrain.State.GO_TO_EXIT
	# Even with low energy, should NOT rest when heading to exit.
	brain.tick(0.0, maze.player_spawn, maze, 5.0)
	assert_equal(brain.state, AIBrain.State.GO_TO_EXIT,
		"rest_skip_exit: stays GO_TO_EXIT even with low energy")


# --- Reactive path invalidation tests ---

func _test_location_completed_externally_clears_path() -> void:
	var maze := _make_small_maze()
	var brain := _make_brain(Enums.Difficulty.HARD, maze)
	var target := maze.locations[0]
	brain._current_target = target
	brain.current_path = [target]
	brain.on_location_completed_externally(target)
	assert_true(brain.current_path.is_empty(),
		"ext_complete_clear: path cleared when target completed externally")


func _test_location_completed_externally_preserves_other_path() -> void:
	var maze := _make_small_maze()
	var brain := _make_brain(Enums.Difficulty.HARD, maze)
	var target := maze.locations[0]
	var other := maze.locations[1] if maze.locations.size() > 1 else Vector2i(99, 99)
	brain._current_target = target
	brain.current_path = [target]
	brain.on_location_completed_externally(other)
	assert_false(brain.current_path.is_empty(),
		"ext_complete_preserve: path kept when different location completed")


func _test_location_completed_externally_removes_from_known() -> void:
	var maze := _make_small_maze()
	var brain := _make_brain(Enums.Difficulty.HARD, maze)
	var target := maze.locations[0]
	assert_true(brain.known_uncompleted_locs.has(target),
		"ext_remove_pre: target in known list")
	brain.on_location_completed_externally(target)
	assert_false(brain.known_uncompleted_locs.has(target),
		"ext_remove: target removed from known list")
