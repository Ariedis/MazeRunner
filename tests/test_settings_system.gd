extends TestBase


func _init() -> void:
	_test_name = "test_settings_system"


func run_tests() -> void:
	# SettingsManager
	_test_settings_default_values()
	_test_settings_set_and_get()
	_test_settings_persist_across_save_load()
	_test_settings_reset_to_defaults()
	_test_settings_resolution_index_valid()
	_test_settings_fullscreen_toggle()
	_test_settings_corrupt_file_uses_defaults()
	_test_settings_missing_keys_get_defaults()

	# CustomContentManager — Tasks
	_test_custom_task_add_and_retrieve()
	_test_custom_task_validation_title_required()
	_test_custom_task_validation_title_too_long()
	_test_custom_task_validation_description_required()
	_test_custom_task_validation_description_too_long()
	_test_custom_task_validation_duration_min()
	_test_custom_task_validation_duration_max()
	_test_custom_task_validation_media_extension()
	_test_custom_task_update()
	_test_custom_task_remove()
	_test_custom_task_remove_nonexistent()

	# CustomContentManager — Items
	_test_custom_item_add_and_retrieve()
	_test_custom_item_validation_name_required()
	_test_custom_item_validation_icon_extension()
	_test_custom_item_update()
	_test_custom_item_remove()
	_test_custom_item_unique_ids()

	# CustomContentManager — Penalties
	_test_custom_penalty_add_and_retrieve()
	_test_custom_penalty_validation_exercise_required()
	_test_custom_penalty_validation_reps_min()
	_test_custom_penalty_validation_reps_max()
	_test_custom_penalty_update()
	_test_custom_penalty_remove()

	# Integration: custom tasks in TaskLoader
	_test_custom_tasks_appear_in_task_loader()

	# Integration: custom items in ItemRegistry
	_test_custom_items_appear_in_item_registry()

	# Integration: custom penalties in ClashTaskLoader
	_test_custom_penalties_appear_in_clash_loader()

	# Default content always available
	_test_default_tasks_always_available()
	_test_default_items_always_available()
	_test_default_penalty_always_available()

	# Removing custom content doesn't break
	_test_remove_all_custom_content_safe()

	# Settings constants
	_test_resolution_labels_match_count()


func _cleanup_custom() -> void:
	var mgr := CustomContentManager.new()
	# Remove all custom tasks
	var tasks := mgr.get_custom_tasks()
	for t in tasks:
		mgr.remove_custom_task(t.get("id", ""))
	# Remove all custom items
	var items := mgr.get_custom_items()
	for i in items:
		mgr.remove_custom_item(i.get("id", ""))
	# Remove all custom penalties
	var penalties := mgr.get_custom_penalties()
	for p in penalties:
		mgr.remove_custom_penalty(p.get("id", ""))


# ========================
# SETTINGS MANAGER TESTS
# ========================

func _test_settings_default_values() -> void:
	var defaults := SettingsManager.DEFAULT_SETTINGS
	assert_true(defaults.has("resolution"), "defaults has resolution")
	assert_true(defaults.has("fullscreen"), "defaults has fullscreen")
	assert_true(defaults.has("master_volume"), "defaults has master_volume")
	assert_true(defaults.has("music_volume"), "defaults has music_volume")
	assert_true(defaults.has("sfx_volume"), "defaults has sfx_volume")
	assert_equal(defaults["fullscreen"], false, "default fullscreen is false")


func _test_settings_set_and_get() -> void:
	var original := SettingsManager.get_setting("master_volume")
	SettingsManager.set_setting("master_volume", 42)
	assert_equal(SettingsManager.get_setting("master_volume"), 42, "set_setting persists in memory")
	SettingsManager.set_setting("master_volume", original)


func _test_settings_persist_across_save_load() -> void:
	var original := SettingsManager.get_setting("sfx_volume")
	SettingsManager.set_setting("sfx_volume", 33)
	SettingsManager.save_settings()
	# Simulate reload by re-loading
	SettingsManager.set_setting("sfx_volume", 99)  # Change in memory
	SettingsManager.load_settings()  # Should restore 33
	assert_equal(SettingsManager.get_setting("sfx_volume"), 33, "settings persist after save/load")
	# Restore original
	SettingsManager.set_setting("sfx_volume", original)
	SettingsManager.save_settings()


func _test_settings_reset_to_defaults() -> void:
	SettingsManager.set_setting("master_volume", 5)
	SettingsManager.set_setting("fullscreen", true)
	SettingsManager.reset_to_defaults()
	assert_equal(SettingsManager.get_setting("master_volume"),
		SettingsManager.DEFAULT_SETTINGS["master_volume"],
		"reset restores master_volume to default")
	assert_equal(SettingsManager.get_setting("fullscreen"),
		SettingsManager.DEFAULT_SETTINGS["fullscreen"],
		"reset restores fullscreen to default")


func _test_settings_resolution_index_valid() -> void:
	var idx: int = SettingsManager.get_setting("resolution")
	assert_true(idx >= 0, "resolution index >= 0")
	assert_true(idx < SettingsManager.RESOLUTIONS.size(), "resolution index < RESOLUTIONS count")


func _test_settings_fullscreen_toggle() -> void:
	SettingsManager.set_setting("fullscreen", true)
	assert_equal(SettingsManager.get_setting("fullscreen"), true, "fullscreen set to true")
	SettingsManager.set_setting("fullscreen", false)
	assert_equal(SettingsManager.get_setting("fullscreen"), false, "fullscreen set to false")
	SettingsManager.save_settings()


func _test_settings_corrupt_file_uses_defaults() -> void:
	# Write corrupt data to settings file
	var file := FileAccess.open(SettingsManager.SETTINGS_PATH, FileAccess.WRITE)
	if file == null:
		_pass("corrupt_settings: skipped (cannot write)")
		return
	file.store_string("{not valid json!!!")
	file.close()

	SettingsManager.load_settings()
	# Should still have valid defaults
	assert_true(SettingsManager.get_setting("resolution") is int or SettingsManager.get_setting("resolution") is float,
		"corrupt file: resolution is still numeric")

	# Cleanup
	SettingsManager.reset_to_defaults()


func _test_settings_missing_keys_get_defaults() -> void:
	# Write partial settings
	var file := FileAccess.open(SettingsManager.SETTINGS_PATH, FileAccess.WRITE)
	if file == null:
		_pass("missing_keys: skipped (cannot write)")
		return
	file.store_string('{"resolution": 0}')
	file.close()

	SettingsManager.load_settings()
	assert_equal(SettingsManager.get_setting("resolution"), 0, "partial file: resolution loaded")
	assert_equal(SettingsManager.get_setting("fullscreen"),
		SettingsManager.DEFAULT_SETTINGS["fullscreen"],
		"partial file: missing fullscreen gets default")

	SettingsManager.reset_to_defaults()


# ========================
# CUSTOM TASKS TESTS
# ========================

func _test_custom_task_add_and_retrieve() -> void:
	_cleanup_custom()
	var mgr := CustomContentManager.new()
	var err := mgr.add_custom_task("Jump Rope", "Jump rope for 20 seconds", 20.0)
	assert_equal(err, "", "add task: no error")
	var tasks := mgr.get_custom_tasks()
	assert_equal(tasks.size(), 1, "add task: 1 task in list")
	assert_equal(tasks[0]["title"], "Jump Rope", "add task: title correct")
	assert_equal(tasks[0]["duration_seconds"], 20.0, "add task: duration correct")
	_cleanup_custom()


func _test_custom_task_validation_title_required() -> void:
	var mgr := CustomContentManager.new()
	var err := mgr.validate_task("", "Some desc", 10.0)
	assert_not_equal(err, "", "validate task: empty title rejected")
	err = mgr.validate_task("   ", "Some desc", 10.0)
	assert_not_equal(err, "", "validate task: whitespace title rejected")


func _test_custom_task_validation_title_too_long() -> void:
	var mgr := CustomContentManager.new()
	var long_title := ""
	for _i in 101:
		long_title += "x"
	var err := mgr.validate_task(long_title, "desc", 10.0)
	assert_not_equal(err, "", "validate task: title > 100 chars rejected")


func _test_custom_task_validation_description_required() -> void:
	var mgr := CustomContentManager.new()
	var err := mgr.validate_task("Title", "", 10.0)
	assert_not_equal(err, "", "validate task: empty description rejected")


func _test_custom_task_validation_description_too_long() -> void:
	var mgr := CustomContentManager.new()
	var long_desc := ""
	for _i in 501:
		long_desc += "x"
	var err := mgr.validate_task("Title", long_desc, 10.0)
	assert_not_equal(err, "", "validate task: description > 500 chars rejected")


func _test_custom_task_validation_duration_min() -> void:
	var mgr := CustomContentManager.new()
	var err := mgr.validate_task("Title", "Desc", 2.0)
	assert_not_equal(err, "", "validate task: duration < 5 rejected")
	err = mgr.validate_task("Title", "Desc", 5.0)
	assert_equal(err, "", "validate task: duration = 5 accepted")


func _test_custom_task_validation_duration_max() -> void:
	var mgr := CustomContentManager.new()
	var err := mgr.validate_task("Title", "Desc", 301.0)
	assert_not_equal(err, "", "validate task: duration > 300 rejected")
	err = mgr.validate_task("Title", "Desc", 300.0)
	assert_equal(err, "", "validate task: duration = 300 accepted")


func _test_custom_task_validation_media_extension() -> void:
	var mgr := CustomContentManager.new()
	var err := mgr.validate_task("Title", "Desc", 10.0, "image.png")
	assert_not_equal(err, "", "validate task: png media rejected")
	err = mgr.validate_task("Title", "Desc", 10.0, "video.mp4")
	assert_equal(err, "", "validate task: mp4 media accepted")
	err = mgr.validate_task("Title", "Desc", 10.0, "anim.gif")
	assert_equal(err, "", "validate task: gif media accepted")
	err = mgr.validate_task("Title", "Desc", 10.0, "clip.webm")
	assert_equal(err, "", "validate task: webm media accepted")


func _test_custom_task_update() -> void:
	_cleanup_custom()
	var mgr := CustomContentManager.new()
	mgr.add_custom_task("Original", "Original desc", 10.0)
	var tasks := mgr.get_custom_tasks()
	var id: String = tasks[0]["id"]
	var err := mgr.update_custom_task(id, "Updated", "New desc", 25.0)
	assert_equal(err, "", "update task: no error")
	tasks = mgr.get_custom_tasks()
	assert_equal(tasks[0]["title"], "Updated", "update task: title updated")
	assert_equal(tasks[0]["duration_seconds"], 25.0, "update task: duration updated")
	_cleanup_custom()


func _test_custom_task_remove() -> void:
	_cleanup_custom()
	var mgr := CustomContentManager.new()
	mgr.add_custom_task("ToRemove", "Will be removed", 10.0)
	var tasks := mgr.get_custom_tasks()
	assert_equal(tasks.size(), 1, "remove task: starts with 1")
	var removed := mgr.remove_custom_task(tasks[0]["id"])
	assert_true(removed, "remove task: returns true")
	tasks = mgr.get_custom_tasks()
	assert_equal(tasks.size(), 0, "remove task: list empty after removal")
	_cleanup_custom()


func _test_custom_task_remove_nonexistent() -> void:
	var mgr := CustomContentManager.new()
	var removed := mgr.remove_custom_task("nonexistent_id_xyz")
	assert_false(removed, "remove nonexistent task: returns false")


# ========================
# CUSTOM ITEMS TESTS
# ========================

func _test_custom_item_add_and_retrieve() -> void:
	_cleanup_custom()
	var mgr := CustomContentManager.new()
	var err := mgr.add_custom_item("Rubber Duck")
	assert_equal(err, "", "add item: no error")
	var items := mgr.get_custom_items()
	assert_equal(items.size(), 1, "add item: 1 item in list")
	assert_equal(items[0]["name"], "Rubber Duck", "add item: name correct")
	assert_true(items[0]["id"].begins_with("custom_"), "add item: id starts with custom_")
	_cleanup_custom()


func _test_custom_item_validation_name_required() -> void:
	var mgr := CustomContentManager.new()
	var err := mgr.validate_item("")
	assert_not_equal(err, "", "validate item: empty name rejected")
	err = mgr.validate_item("  ")
	assert_not_equal(err, "", "validate item: whitespace name rejected")


func _test_custom_item_validation_icon_extension() -> void:
	var mgr := CustomContentManager.new()
	var err := mgr.validate_item("Test", "icon.bmp")
	assert_not_equal(err, "", "validate item: bmp icon rejected")
	err = mgr.validate_item("Test", "icon.png")
	assert_equal(err, "", "validate item: png icon accepted")
	err = mgr.validate_item("Test", "icon.jpg")
	assert_equal(err, "", "validate item: jpg icon accepted")


func _test_custom_item_update() -> void:
	_cleanup_custom()
	var mgr := CustomContentManager.new()
	mgr.add_custom_item("OldName")
	var items := mgr.get_custom_items()
	var id: String = items[0]["id"]
	var err := mgr.update_custom_item(id, "NewName", "icon.png")
	assert_equal(err, "", "update item: no error")
	items = mgr.get_custom_items()
	assert_equal(items[0]["name"], "NewName", "update item: name updated")
	_cleanup_custom()


func _test_custom_item_remove() -> void:
	_cleanup_custom()
	var mgr := CustomContentManager.new()
	mgr.add_custom_item("ToRemove")
	var items := mgr.get_custom_items()
	var removed := mgr.remove_custom_item(items[0]["id"])
	assert_true(removed, "remove item: returns true")
	items = mgr.get_custom_items()
	assert_equal(items.size(), 0, "remove item: list empty")
	_cleanup_custom()


func _test_custom_item_unique_ids() -> void:
	_cleanup_custom()
	var mgr := CustomContentManager.new()
	mgr.add_custom_item("Same Name")
	mgr.add_custom_item("Same Name")
	var items := mgr.get_custom_items()
	assert_equal(items.size(), 2, "unique ids: 2 items added")
	assert_not_equal(items[0]["id"], items[1]["id"], "unique ids: different ids for same name")
	_cleanup_custom()


# ========================
# CUSTOM PENALTIES TESTS
# ========================

func _test_custom_penalty_add_and_retrieve() -> void:
	_cleanup_custom()
	var mgr := CustomContentManager.new()
	var err := mgr.add_custom_penalty("Star Jumps", 15)
	assert_equal(err, "", "add penalty: no error")
	var penalties := mgr.get_custom_penalties()
	assert_equal(penalties.size(), 1, "add penalty: 1 in list")
	assert_equal(penalties[0]["exercise"], "Star Jumps", "add penalty: exercise correct")
	assert_equal(penalties[0]["reps"], 15, "add penalty: reps correct")
	_cleanup_custom()


func _test_custom_penalty_validation_exercise_required() -> void:
	var mgr := CustomContentManager.new()
	var err := mgr.validate_penalty("", 10)
	assert_not_equal(err, "", "validate penalty: empty exercise rejected")


func _test_custom_penalty_validation_reps_min() -> void:
	var mgr := CustomContentManager.new()
	var err := mgr.validate_penalty("Squats", 0)
	assert_not_equal(err, "", "validate penalty: reps=0 rejected")
	err = mgr.validate_penalty("Squats", 1)
	assert_equal(err, "", "validate penalty: reps=1 accepted")


func _test_custom_penalty_validation_reps_max() -> void:
	var mgr := CustomContentManager.new()
	var err := mgr.validate_penalty("Squats", 1000)
	assert_not_equal(err, "", "validate penalty: reps=1000 rejected")
	err = mgr.validate_penalty("Squats", 999)
	assert_equal(err, "", "validate penalty: reps=999 accepted")


func _test_custom_penalty_update() -> void:
	_cleanup_custom()
	var mgr := CustomContentManager.new()
	mgr.add_custom_penalty("Old Exercise", 5)
	var penalties := mgr.get_custom_penalties()
	var id: String = penalties[0]["id"]
	var err := mgr.update_custom_penalty(id, "New Exercise", 20)
	assert_equal(err, "", "update penalty: no error")
	penalties = mgr.get_custom_penalties()
	assert_equal(penalties[0]["exercise"], "New Exercise", "update penalty: exercise updated")
	assert_equal(penalties[0]["reps"], 20, "update penalty: reps updated")
	_cleanup_custom()


func _test_custom_penalty_remove() -> void:
	_cleanup_custom()
	var mgr := CustomContentManager.new()
	mgr.add_custom_penalty("ToRemove", 10)
	var penalties := mgr.get_custom_penalties()
	var removed := mgr.remove_custom_penalty(penalties[0]["id"])
	assert_true(removed, "remove penalty: returns true")
	penalties = mgr.get_custom_penalties()
	assert_equal(penalties.size(), 0, "remove penalty: list empty")
	_cleanup_custom()


# ========================
# INTEGRATION TESTS
# ========================

func _test_custom_tasks_appear_in_task_loader() -> void:
	_cleanup_custom()
	var mgr := CustomContentManager.new()
	mgr.add_custom_task("Integration Task", "Test task", 10.0)

	var loader := TaskLoader.new()
	var all := loader.load_all_tasks()
	var found := false
	for task in all:
		if task.title == "Integration Task":
			found = true
			break
	assert_true(found, "custom task appears in TaskLoader.load_all_tasks()")
	_cleanup_custom()


func _test_custom_items_appear_in_item_registry() -> void:
	_cleanup_custom()
	var mgr := CustomContentManager.new()
	mgr.add_custom_item("Test Gem")

	var reg := ItemRegistry.new()
	var found := false
	for item in reg.get_all():
		if item.name == "Test Gem" and item.is_custom:
			found = true
			break
	assert_true(found, "custom item appears in ItemRegistry")
	_cleanup_custom()


func _test_custom_penalties_appear_in_clash_loader() -> void:
	_cleanup_custom()
	var mgr := CustomContentManager.new()
	mgr.add_custom_penalty("Test Penalty Exercise", 25)

	# ClashTaskLoader.load_active_task() should return our custom penalty
	# (it's the only one, so it must be selected)
	var task := ClashTaskLoader.load_active_task()
	assert_equal(task["exercise"], "Test Penalty Exercise", "custom penalty appears in ClashTaskLoader")
	assert_equal(task["reps"], 25, "custom penalty reps correct in ClashTaskLoader")
	_cleanup_custom()


func _test_default_tasks_always_available() -> void:
	_cleanup_custom()
	var loader := TaskLoader.new()
	var defaults := loader.load_default_tasks()
	assert_true(defaults.size() >= 5, "default tasks: at least 5 always available")
	var all := loader.load_all_tasks()
	assert_true(all.size() >= 5, "all tasks: at least 5 with no custom content")


func _test_default_items_always_available() -> void:
	_cleanup_custom()
	var reg := ItemRegistry.new()
	assert_true(reg.count() >= 5, "default items: at least 5 always available")
	var golden := reg.get_item("golden_key")
	assert_true(golden != null, "default item golden_key always exists")


func _test_default_penalty_always_available() -> void:
	_cleanup_custom()
	# Also remove any legacy custom task file
	if FileAccess.file_exists("user://clash_tasks.json"):
		DirAccess.remove_absolute("user://clash_tasks.json")
	var task := ClashTaskLoader.load_active_task()
	assert_equal(task["exercise"], "Bicep Curls", "default penalty: Bicep Curls when no custom")
	assert_equal(task["reps"], 10, "default penalty: 10 reps when no custom")


func _test_remove_all_custom_content_safe() -> void:
	_cleanup_custom()
	var mgr := CustomContentManager.new()
	# Add then remove custom content
	mgr.add_custom_task("Temp Task", "Temp", 10.0)
	mgr.add_custom_item("Temp Item")
	mgr.add_custom_penalty("Temp Penalty", 5)

	# Remove all
	var tasks := mgr.get_custom_tasks()
	for t in tasks:
		mgr.remove_custom_task(t["id"])
	var items := mgr.get_custom_items()
	for i in items:
		mgr.remove_custom_item(i["id"])
	var penalties := mgr.get_custom_penalties()
	for p in penalties:
		mgr.remove_custom_penalty(p["id"])

	# Everything should be empty but system still works
	assert_equal(mgr.get_custom_tasks().size(), 0, "remove all: no custom tasks")
	assert_equal(mgr.get_custom_items().size(), 0, "remove all: no custom items")
	assert_equal(mgr.get_custom_penalties().size(), 0, "remove all: no custom penalties")

	# Default systems still work
	var loader := TaskLoader.new()
	assert_true(loader.load_all_tasks().size() >= 5, "remove all: defaults still load")
	var reg := ItemRegistry.new()
	assert_true(reg.count() >= 5, "remove all: default items still load")

	_cleanup_custom()


func _test_resolution_labels_match_count() -> void:
	assert_equal(SettingsManager.RESOLUTIONS.size(), SettingsManager.RESOLUTION_LABELS.size(),
		"RESOLUTIONS and RESOLUTION_LABELS same count")
