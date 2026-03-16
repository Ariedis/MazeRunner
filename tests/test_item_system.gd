extends TestBase


func run_tests() -> void:
	_test_name = "ItemSystem"
	# ItemData
	_test_item_data_defaults()
	# ItemRegistry
	_test_item_registry_default_count()
	_test_item_registry_all_have_ids()
	_test_item_registry_all_have_names()
	_test_item_registry_none_are_custom()
	_test_item_registry_get_item_valid()
	_test_item_registry_get_item_invalid_returns_null()
	_test_item_registry_add_custom_increments_count()
	_test_item_registry_add_custom_is_custom_flag()
	_test_item_registry_add_custom_retrievable()
	_test_item_registry_get_all_returns_copy()
	# WinConditionManager
	_test_win_player_with_item()
	_test_win_player_without_item()
	_test_win_ai_with_item()
	_test_win_ai_without_item()


# --- ItemData ---

func _test_item_data_defaults() -> void:
	var item := ItemData.new()
	assert_equal(item.id, "", "_test_item_data_defaults: id")
	assert_equal(item.name, "", "_test_item_data_defaults: name")
	assert_false(item.is_custom, "_test_item_data_defaults: is_custom")


# --- ItemRegistry ---

func _test_item_registry_default_count() -> void:
	var reg := ItemRegistry.new()
	assert_equal(reg.count(), 5, "_test_item_registry_default_count")


func _test_item_registry_all_have_ids() -> void:
	var reg := ItemRegistry.new()
	var all_ok := true
	for item in reg.get_all():
		if item.id == "":
			all_ok = false
	assert_true(all_ok, "_test_item_registry_all_have_ids")


func _test_item_registry_all_have_names() -> void:
	var reg := ItemRegistry.new()
	var all_ok := true
	for item in reg.get_all():
		if item.name == "":
			all_ok = false
	assert_true(all_ok, "_test_item_registry_all_have_names")


func _test_item_registry_none_are_custom() -> void:
	var reg := ItemRegistry.new()
	var none_custom := true
	for item in reg.get_all():
		if item.is_custom:
			none_custom = false
	assert_true(none_custom, "_test_item_registry_none_are_custom")


func _test_item_registry_get_item_valid() -> void:
	var reg := ItemRegistry.new()
	var item := reg.get_item("golden_key")
	assert_true(item != null, "_test_item_registry_get_item_valid: not null")
	assert_equal(item.name, "Golden Key", "_test_item_registry_get_item_valid: name")


func _test_item_registry_get_item_invalid_returns_null() -> void:
	var reg := ItemRegistry.new()
	var item := reg.get_item("nonexistent_item")
	assert_equal(item, null, "_test_item_registry_get_item_invalid_returns_null")


func _test_item_registry_add_custom_increments_count() -> void:
	var reg := ItemRegistry.new()
	var before := reg.count()
	reg.add_custom("test_item", "Test Item")
	assert_equal(reg.count(), before + 1, "_test_item_registry_add_custom_increments_count")


func _test_item_registry_add_custom_is_custom_flag() -> void:
	var reg := ItemRegistry.new()
	reg.add_custom("my_trophy", "My Trophy")
	var item := reg.get_item("my_trophy")
	assert_true(item != null, "_test_item_registry_add_custom_is_custom_flag: not null")
	assert_true(item.is_custom, "_test_item_registry_add_custom_is_custom_flag: is_custom")


func _test_item_registry_add_custom_retrievable() -> void:
	var reg := ItemRegistry.new()
	reg.add_custom("rare_gem", "Rare Gem")
	var item := reg.get_item("rare_gem")
	assert_true(item != null, "_test_item_registry_add_custom_retrievable: not null")
	assert_equal(item.id, "rare_gem", "_test_item_registry_add_custom_retrievable: id")
	assert_equal(item.name, "Rare Gem", "_test_item_registry_add_custom_retrievable: name")


func _test_item_registry_get_all_returns_copy() -> void:
	var reg := ItemRegistry.new()
	var all1 := reg.get_all()
	all1.clear()
	assert_equal(reg.count(), 5, "_test_item_registry_get_all_returns_copy")


# --- WinConditionManager ---
# Note: check_player_at_exit and check_ai_at_exit emit SignalBus.match_ended when
# returning a win result. Tests only verify return values; signal side effects are
# acceptable in the test environment.

func _test_win_player_with_item() -> void:
	var mgr := WinConditionManager.new()
	var result := mgr.check_player_at_exit(true)
	assert_equal(result, WinConditionManager.Result.PLAYER_WIN, "_test_win_player_with_item")


func _test_win_player_without_item() -> void:
	var mgr := WinConditionManager.new()
	var result := mgr.check_player_at_exit(false)
	assert_equal(result, WinConditionManager.Result.NONE, "_test_win_player_without_item")


func _test_win_ai_with_item() -> void:
	var mgr := WinConditionManager.new()
	var result := mgr.check_ai_at_exit(true)
	assert_equal(result, WinConditionManager.Result.AI_WIN, "_test_win_ai_with_item")


func _test_win_ai_without_item() -> void:
	var mgr := WinConditionManager.new()
	var result := mgr.check_ai_at_exit(false)
	assert_equal(result, WinConditionManager.Result.NONE, "_test_win_ai_without_item")
