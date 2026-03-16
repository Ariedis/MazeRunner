extends TestBase


func run_tests() -> void:
	_test_name = "TaskSystem"
	_test_task_data_default_fields()
	_test_task_loader_default_count()
	_test_task_loader_default_titles_non_empty()
	_test_task_loader_default_durations_positive()
	_test_task_loader_user_tasks_returns_array_when_no_dir()
	_test_task_loader_all_includes_defaults()
	_test_task_loader_parse_valid_json()
	_test_task_loader_parse_missing_title_returns_null()
	_test_task_loader_parse_missing_duration_returns_null()
	_test_task_loader_parse_malformed_json_returns_null()
	_test_location_data_not_completed_initially()
	_test_location_manager_setup_count_matches_maze()
	_test_location_manager_exactly_one_player_item()
	_test_location_manager_remaining_are_size_increasers()
	_test_location_manager_all_have_tasks()
	_test_location_manager_get_location_at_correct()
	_test_location_manager_get_location_at_null_for_empty()
	_test_location_manager_has_uncompleted_true_before()
	_test_location_manager_has_uncompleted_false_after()
	_test_location_manager_complete_sets_flag()
	_test_location_manager_completed_count()
	_test_location_ids_unique()


# --- TaskData ---

func _test_task_data_default_fields() -> void:
	var t := TaskData.new()
	assert_equal(t.title, "", "_test_task_data_default_fields: title")
	assert_equal(t.description, "", "_test_task_data_default_fields: description")
	assert_equal(t.media_path, "", "_test_task_data_default_fields: media_path")
	assert_equal(t.duration_seconds, 30.0, "_test_task_data_default_fields: duration_seconds")


# --- TaskLoader ---

func _test_task_loader_default_count() -> void:
	var loader := TaskLoader.new()
	var tasks := loader.load_default_tasks()
	assert_equal(tasks.size(), 5, "_test_task_loader_default_count")


func _test_task_loader_default_titles_non_empty() -> void:
	var loader := TaskLoader.new()
	var tasks := loader.load_default_tasks()
	var all_non_empty := true
	for t in tasks:
		if t.title == "":
			all_non_empty = false
	assert_true(all_non_empty, "_test_task_loader_default_titles_non_empty")


func _test_task_loader_default_durations_positive() -> void:
	var loader := TaskLoader.new()
	var tasks := loader.load_default_tasks()
	var all_positive := true
	for t in tasks:
		if t.duration_seconds <= 0.0:
			all_positive = false
	assert_true(all_positive, "_test_task_loader_default_durations_positive")


func _test_task_loader_user_tasks_returns_array_when_no_dir() -> void:
	var loader := TaskLoader.new()
	var tasks := loader.load_user_tasks()
	assert_true(tasks is Array, "_test_task_loader_user_tasks_returns_array_when_no_dir")


func _test_task_loader_all_includes_defaults() -> void:
	var loader := TaskLoader.new()
	var all := loader.load_all_tasks()
	assert_true(all.size() >= 5, "_test_task_loader_all_includes_defaults")


func _test_task_loader_parse_valid_json() -> void:
	var loader := TaskLoader.new()
	var json := '{"title":"Run","description":"Run in place","duration_seconds":10.0,"media_path":"run.gif"}'
	var task := loader._parse_task_json(json)
	assert_true(task != null, "_test_task_loader_parse_valid_json: not null")
	assert_equal(task.title, "Run", "_test_task_loader_parse_valid_json: title")
	assert_equal(task.description, "Run in place", "_test_task_loader_parse_valid_json: description")
	assert_equal(task.duration_seconds, 10.0, "_test_task_loader_parse_valid_json: duration")
	assert_equal(task.media_path, "run.gif", "_test_task_loader_parse_valid_json: media_path")


func _test_task_loader_parse_missing_title_returns_null() -> void:
	var loader := TaskLoader.new()
	var json := '{"description":"Run in place","duration_seconds":10.0}'
	var task := loader._parse_task_json(json)
	assert_equal(task, null, "_test_task_loader_parse_missing_title_returns_null")


func _test_task_loader_parse_missing_duration_returns_null() -> void:
	var loader := TaskLoader.new()
	var json := '{"title":"Run","description":"Run in place"}'
	var task := loader._parse_task_json(json)
	assert_equal(task, null, "_test_task_loader_parse_missing_duration_returns_null")


func _test_task_loader_parse_malformed_json_returns_null() -> void:
	var loader := TaskLoader.new()
	var task := loader._parse_task_json("{not valid json{{")
	assert_equal(task, null, "_test_task_loader_parse_malformed_json_returns_null")


# --- LocationData ---

func _test_location_data_not_completed_initially() -> void:
	var loc := LocationData.new()
	assert_false(loc.completed, "_test_location_data_not_completed_initially")


# --- LocationManager helpers ---

func _make_test_maze(location_count: int) -> MazeData:
	var maze := MazeData.new(10, 10)
	for i in location_count:
		maze.locations.append(Vector2i(i, 0))
	return maze


func _make_test_tasks() -> Array[TaskData]:
	var loader := TaskLoader.new()
	return loader.load_default_tasks()


func _make_test_rng() -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	return rng


# --- LocationManager ---

func _test_location_manager_setup_count_matches_maze() -> void:
	var maze := _make_test_maze(4)
	var mgr := LocationManager.new()
	mgr.setup(maze, _make_test_tasks(), _make_test_rng())
	assert_equal(mgr.locations.size(), 4, "_test_location_manager_setup_count_matches_maze")


func _test_location_manager_exactly_one_player_item() -> void:
	var maze := _make_test_maze(4)
	var mgr := LocationManager.new()
	mgr.setup(maze, _make_test_tasks(), _make_test_rng())
	var count := 0
	for loc in mgr.locations:
		if loc.item_type == Enums.ItemType.PLAYER_ITEM:
			count += 1
	assert_equal(count, 1, "_test_location_manager_exactly_one_player_item")


func _test_location_manager_remaining_are_size_increasers() -> void:
	var maze := _make_test_maze(4)
	var mgr := LocationManager.new()
	mgr.setup(maze, _make_test_tasks(), _make_test_rng())
	var count := 0
	for loc in mgr.locations:
		if loc.item_type == Enums.ItemType.SIZE_INCREASER:
			count += 1
	assert_equal(count, 3, "_test_location_manager_remaining_are_size_increasers")


func _test_location_manager_all_have_tasks() -> void:
	var maze := _make_test_maze(4)
	var mgr := LocationManager.new()
	mgr.setup(maze, _make_test_tasks(), _make_test_rng())
	var all_have := true
	for loc in mgr.locations:
		if loc.task == null:
			all_have = false
	assert_true(all_have, "_test_location_manager_all_have_tasks")


func _test_location_manager_get_location_at_correct() -> void:
	var maze := _make_test_maze(3)
	var mgr := LocationManager.new()
	mgr.setup(maze, _make_test_tasks(), _make_test_rng())
	# At least one location must be findable by its grid_pos
	var first_loc := mgr.locations[0]
	var found := mgr.get_location_at(first_loc.grid_pos)
	assert_true(found != null, "_test_location_manager_get_location_at_correct: not null")
	assert_equal(found.grid_pos, first_loc.grid_pos, "_test_location_manager_get_location_at_correct: pos")


func _test_location_manager_get_location_at_null_for_empty() -> void:
	var maze := _make_test_maze(2)
	var mgr := LocationManager.new()
	mgr.setup(maze, _make_test_tasks(), _make_test_rng())
	var result := mgr.get_location_at(Vector2i(9, 9))
	assert_equal(result, null, "_test_location_manager_get_location_at_null_for_empty")


func _test_location_manager_has_uncompleted_true_before() -> void:
	var maze := _make_test_maze(2)
	var mgr := LocationManager.new()
	mgr.setup(maze, _make_test_tasks(), _make_test_rng())
	var first_loc := mgr.locations[0]
	assert_true(mgr.has_uncompleted_at(first_loc.grid_pos), "_test_location_manager_has_uncompleted_true_before")


func _test_location_manager_has_uncompleted_false_after() -> void:
	var maze := _make_test_maze(2)
	var mgr := LocationManager.new()
	mgr.setup(maze, _make_test_tasks(), _make_test_rng())
	var first_loc := mgr.locations[0]
	mgr.complete_location(first_loc.id)
	assert_false(mgr.has_uncompleted_at(first_loc.grid_pos), "_test_location_manager_has_uncompleted_false_after")


func _test_location_manager_complete_sets_flag() -> void:
	var maze := _make_test_maze(2)
	var mgr := LocationManager.new()
	mgr.setup(maze, _make_test_tasks(), _make_test_rng())
	var first_loc := mgr.locations[0]
	assert_false(first_loc.completed, "_test_location_manager_complete_sets_flag: before")
	mgr.complete_location(first_loc.id)
	assert_true(first_loc.completed, "_test_location_manager_complete_sets_flag: after")


func _test_location_manager_completed_count() -> void:
	var maze := _make_test_maze(3)
	var mgr := LocationManager.new()
	mgr.setup(maze, _make_test_tasks(), _make_test_rng())
	assert_equal(mgr.get_completed_count(), 0, "_test_location_manager_completed_count: start")
	mgr.complete_location(mgr.locations[0].id)
	assert_equal(mgr.get_completed_count(), 1, "_test_location_manager_completed_count: after 1")
	mgr.complete_location(mgr.locations[1].id)
	assert_equal(mgr.get_completed_count(), 2, "_test_location_manager_completed_count: after 2")


func _test_location_ids_unique() -> void:
	var maze := _make_test_maze(5)
	var mgr := LocationManager.new()
	mgr.setup(maze, _make_test_tasks(), _make_test_rng())
	var ids: Array = []
	var all_unique := true
	for loc in mgr.locations:
		if loc.id in ids:
			all_unique = false
		ids.append(loc.id)
	assert_true(all_unique, "_test_location_ids_unique")
