extends TestBase


func _init() -> void:
	_test_name = "test_save_system"


func run_tests() -> void:
	_test_save_captures_complete_state()
	_test_load_restores_exact_state()
	_test_multiple_slots_independent()
	_test_continue_loads_most_recent()
	_test_corrupt_save_handled_gracefully()
	_test_save_file_size_reasonable()
	_test_delete_save()
	_test_slot_info_metadata()
	_test_vector_helpers()
	_test_invalid_slot()
	_test_has_any_save()
	_test_version_stored()
	_test_save_with_completed_locations()
	_test_save_with_ai_state()


func _build_mock_game_data() -> Dictionary:
	return {
		"config": {
			"map_size": Enums.MapSize.MEDIUM,
			"num_opponents": 2,
			"ai_difficulties": [Enums.Difficulty.EASY, Enums.Difficulty.HARD],
			"seed": 42,
			"item_id": "golden_key",
			"avatar_id": 3,
		},
		"maze": {
			"width": 25,
			"height": 25,
			"seed": 42,
			"exit": [20, 22],
			"player_spawn": [0, 0],
			"ai_spawns": [[5, 5], [10, 10]],
			"locations": [[3, 7], [8, 12], [15, 3]],
		},
		"player": {
			"position": [150.5, 220.0],
			"grid_pos": [5, 8],
			"size": 3,
			"energy": 72.5,
			"has_item": true,
			"item_id": "golden_key",
			"avatar_id": 3,
			"explored_cells": [[0, 0], [0, 1], [1, 0], [1, 1], [2, 0]],
			"clash_cooldown": 1.5,
			"is_frozen": false,
		},
		"opponents": [
			{
				"index": 0,
				"position": [300.0, 100.0],
				"grid_pos": [12, 3],
				"size": 2,
				"energy": 90.0,
				"difficulty": Enums.Difficulty.EASY,
				"has_item": false,
				"state": AIBrain.State.EXPLORE,
				"explored_cells": [[5, 5], [5, 6], [6, 5]],
				"known_uncompleted_locs": [[8, 12]],
				"exit_known": false,
				"exit_pos": [-1, -1],
				"penalty_timer": 0.0,
				"task_timer": 0.0,
				"current_path": [[6, 6], [7, 6]],
				"clash_cooldown": 0.0,
				"_item_loc_pos": [3, 7],
				"_current_task_pos": [-1, -1],
				"_current_target": [7, 6],
				"_pre_rest_state": AIBrain.State.EXPLORE,
				"_pre_penalty_state": AIBrain.State.EXPLORE,
				"_rest_threshold": 40.0,
				"_rest_target": 80.0,
			},
			{
				"index": 1,
				"position": [500.0, 400.0],
				"grid_pos": [20, 15],
				"size": 4,
				"energy": 55.0,
				"difficulty": Enums.Difficulty.HARD,
				"has_item": true,
				"state": AIBrain.State.GO_TO_EXIT,
				"explored_cells": [[10, 10], [11, 10]],
				"known_uncompleted_locs": [],
				"exit_known": true,
				"exit_pos": [20, 22],
				"penalty_timer": 0.0,
				"task_timer": 0.0,
				"current_path": [[20, 16], [20, 17]],
				"clash_cooldown": 2.0,
				"_item_loc_pos": [15, 3],
				"_current_task_pos": [-1, -1],
				"_current_target": [20, 22],
				"_pre_rest_state": AIBrain.State.EXPLORE,
				"_pre_penalty_state": AIBrain.State.EXPLORE,
				"_rest_threshold": 5.0,
				"_rest_target": 30.0,
			},
		],
		"locations": [
			{"id": 0, "grid_pos": [3, 7], "item_type": Enums.ItemType.PLAYER_ITEM, "completed": true, "completed_by": ["player"]},
			{"id": 1, "grid_pos": [8, 12], "item_type": Enums.ItemType.SIZE_INCREASER, "completed": false, "completed_by": []},
			{"id": 2, "grid_pos": [15, 3], "item_type": Enums.ItemType.SIZE_INCREASER, "completed": true, "completed_by": ["ai_1"]},
		],
		"elapsed_msec": 45000,
		"clash_active": false,
	}


func _cleanup_test_saves() -> void:
	for slot in range(1, SaveManager.MAX_SLOTS + 1):
		SaveManager.delete_save(slot)


## Test: save captures complete game state (all required fields present).
func _test_save_captures_complete_state() -> void:
	_cleanup_test_saves()
	var data := _build_mock_game_data()
	var success := SaveManager.save_game(1, data)
	assert_true(success, "save_game returns true")

	var loaded = SaveManager.load_game(1)
	assert_true(loaded != null, "load_game returns non-null")
	assert_true(loaded is Dictionary, "loaded data is Dictionary")

	var d: Dictionary = loaded.get("data", {})

	# Config fields
	assert_true(d.has("config"), "save has config")
	assert_equal(d["config"]["map_size"], Enums.MapSize.MEDIUM, "config map_size preserved")
	assert_equal(d["config"]["seed"], 42, "config seed preserved")
	assert_equal(d["config"]["num_opponents"], 2, "config num_opponents preserved")
	assert_equal(d["config"]["item_id"], "golden_key", "config item_id preserved")

	# Player fields
	assert_true(d.has("player"), "save has player")
	assert_equal(d["player"]["size"], 3, "player size preserved")
	assert_equal(d["player"]["energy"], 72.5, "player energy preserved")
	assert_equal(d["player"]["has_item"], true, "player has_item preserved")
	assert_equal(d["player"]["explored_cells"].size(), 5, "player explored_cells count preserved")

	# Opponents
	assert_true(d.has("opponents"), "save has opponents")
	assert_equal(d["opponents"].size(), 2, "two opponents saved")

	# Locations
	assert_true(d.has("locations"), "save has locations")
	assert_equal(d["locations"].size(), 3, "three locations saved")

	# Timing
	assert_true(d.has("elapsed_msec"), "save has elapsed_msec")
	assert_equal(d["elapsed_msec"], 45000, "elapsed_msec preserved")

	_cleanup_test_saves()


## Test: load restores exact game state for all fields.
func _test_load_restores_exact_state() -> void:
	_cleanup_test_saves()
	var data := _build_mock_game_data()
	SaveManager.save_game(1, data)
	var loaded: Dictionary = SaveManager.load_game(1)
	var d: Dictionary = loaded.get("data", {})

	# Player position
	var pos: Array = d["player"]["position"]
	assert_equal(pos[0], 150.5, "player x position exact")
	assert_equal(pos[1], 220.0, "player y position exact")

	# Player stats
	assert_equal(d["player"]["clash_cooldown"], 1.5, "player clash_cooldown preserved")

	# AI state
	var ai0: Dictionary = d["opponents"][0]
	assert_equal(ai0["state"], AIBrain.State.EXPLORE, "ai0 state preserved")
	assert_equal(ai0["energy"], 90.0, "ai0 energy preserved")
	assert_equal(ai0["known_uncompleted_locs"].size(), 1, "ai0 known locs preserved")

	var ai1: Dictionary = d["opponents"][1]
	assert_equal(ai1["state"], AIBrain.State.GO_TO_EXIT, "ai1 state preserved")
	assert_equal(ai1["has_item"], true, "ai1 has_item preserved")
	assert_equal(ai1["exit_known"], true, "ai1 exit_known preserved")
	assert_equal(ai1["clash_cooldown"], 2.0, "ai1 clash_cooldown preserved")

	# Location states
	assert_equal(d["locations"][0]["completed"], true, "loc0 completed preserved")
	assert_equal(d["locations"][0]["completed_by"], ["player"], "loc0 completed_by preserved")
	assert_equal(d["locations"][1]["completed"], false, "loc1 not completed preserved")
	assert_equal(d["locations"][2]["completed"], true, "loc2 completed preserved")

	# Fog of war
	assert_equal(d["player"]["explored_cells"].size(), 5, "fog explored_cells count exact")

	_cleanup_test_saves()


## Test: multiple save slots work independently.
func _test_multiple_slots_independent() -> void:
	_cleanup_test_saves()
	var data1 := _build_mock_game_data()
	data1["player"]["size"] = 1
	data1["player"]["energy"] = 50.0

	var data2 := _build_mock_game_data()
	data2["player"]["size"] = 5
	data2["player"]["energy"] = 80.0

	var data3 := _build_mock_game_data()
	data3["player"]["size"] = 10
	data3["player"]["energy"] = 10.0

	SaveManager.save_game(1, data1)
	SaveManager.save_game(2, data2)
	SaveManager.save_game(3, data3)

	var loaded1: Dictionary = SaveManager.load_game(1)
	var loaded2: Dictionary = SaveManager.load_game(2)
	var loaded3: Dictionary = SaveManager.load_game(3)

	assert_equal(loaded1["data"]["player"]["size"], 1, "slot 1 player size independent")
	assert_equal(loaded1["data"]["player"]["energy"], 50.0, "slot 1 player energy independent")
	assert_equal(loaded2["data"]["player"]["size"], 5, "slot 2 player size independent")
	assert_equal(loaded2["data"]["player"]["energy"], 80.0, "slot 2 player energy independent")
	assert_equal(loaded3["data"]["player"]["size"], 10, "slot 3 player size independent")
	assert_equal(loaded3["data"]["player"]["energy"], 10.0, "slot 3 player energy independent")

	# Loading one does not affect others
	var reloaded1: Dictionary = SaveManager.load_game(1)
	assert_equal(reloaded1["data"]["player"]["size"], 1, "slot 1 unaffected after loading slot 3")

	# Empty slot returns null
	var loaded4 = SaveManager.load_game(4)
	assert_true(loaded4 == null, "unused slot 4 returns null")

	_cleanup_test_saves()


## Test: continue loads the most recent save based on timestamp.
func _test_continue_loads_most_recent() -> void:
	_cleanup_test_saves()

	# Save slot 1 first (older)
	var data1 := _build_mock_game_data()
	data1["player"]["size"] = 2
	SaveManager.save_game(1, data1)

	# Brief delay to ensure different timestamps (timestamps are per-second)
	OS.delay_msec(1100)

	# Save slot 3 second (newer)
	var data3 := _build_mock_game_data()
	data3["player"]["size"] = 7
	SaveManager.save_game(3, data3)

	var most_recent = SaveManager.load_most_recent()
	assert_true(most_recent != null, "load_most_recent returns non-null")
	assert_equal(most_recent["data"]["player"]["size"], 7, "most recent has slot 3 data (size=7)")
	assert_equal(most_recent["slot"], 3, "most recent is slot 3")

	_cleanup_test_saves()


## Test: corrupt save file shows error, doesn't crash.
func _test_corrupt_save_handled_gracefully() -> void:
	_cleanup_test_saves()

	# Write invalid JSON to a save slot
	var path := "user://saves/save_slot_1.json"
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string("{invalid json content!!! not valid")
	file.close()

	# Load should return null without crashing
	var loaded = SaveManager.load_game(1)
	assert_true(loaded == null, "corrupt save returns null (no crash)")

	# Slot info should mark it as corrupt
	var slots := SaveManager.get_all_slot_info()
	assert_true(slots[0]["corrupt"], "corrupt slot marked as corrupt in metadata")
	assert_true(slots[0]["exists"], "corrupt slot still exists")

	# Other slots should be unaffected
	assert_false(slots[1]["exists"], "slot 2 unaffected by corrupt slot 1")

	# Write empty file
	file = FileAccess.open("user://saves/save_slot_2.json", FileAccess.WRITE)
	file.store_string("")
	file.close()
	var loaded2 = SaveManager.load_game(2)
	assert_true(loaded2 == null, "empty save file returns null")

	# Write non-dict JSON
	file = FileAccess.open("user://saves/save_slot_3.json", FileAccess.WRITE)
	file.store_string("[1, 2, 3]")
	file.close()
	var loaded3 = SaveManager.load_game(3)
	assert_true(loaded3 == null, "non-dict JSON returns null")

	_cleanup_test_saves()


## Test: save file size is reasonable for a Large map.
func _test_save_file_size_reasonable() -> void:
	_cleanup_test_saves()

	# Build a large-map-like save with many explored cells and locations
	var data := _build_mock_game_data()
	data["config"]["map_size"] = Enums.MapSize.LARGE
	data["maze"]["width"] = 40
	data["maze"]["height"] = 40

	# Simulate many explored cells (large map: 40x40 = 1600 cells, explore ~60%)
	var explored: Array = []
	for y in 40:
		for x in 24:
			explored.append([x, y])
	data["player"]["explored_cells"] = explored

	# Add 14 locations (Large map count)
	var locs: Array = []
	for i in 14:
		locs.append({
			"id": i,
			"grid_pos": [i * 2, i * 2 + 1],
			"item_type": Enums.ItemType.SIZE_INCREASER if i > 0 else Enums.ItemType.PLAYER_ITEM,
			"completed": i < 7,
			"completed_by": ["player"] if i < 7 else [],
		})
	data["locations"] = locs

	# Add 6 opponents with substantial explored data
	var opps: Array = []
	for i in 6:
		var opp_explored: Array = []
		for y in 30:
			for x in 15:
				opp_explored.append([x + i, y])
		opps.append({
			"index": i,
			"position": [float(i * 100), float(i * 80)],
			"grid_pos": [i * 5, i * 4],
			"size": i + 1,
			"energy": 50.0 + float(i * 10),
			"difficulty": i % 3,
			"has_item": i == 0,
			"state": AIBrain.State.EXPLORE,
			"explored_cells": opp_explored,
			"known_uncompleted_locs": [[i * 2, i * 2 + 1]],
			"exit_known": i > 3,
			"exit_pos": [38, 38],
			"penalty_timer": 0.0,
			"task_timer": 0.0,
			"current_path": [],
			"clash_cooldown": 0.0,
			"_item_loc_pos": [i, i],
			"_current_task_pos": [-1, -1],
			"_current_target": [-1, -1],
			"_pre_rest_state": 0,
			"_pre_penalty_state": 0,
			"_rest_threshold": 20.0,
			"_rest_target": 50.0,
		})
	data["opponents"] = opps

	SaveManager.save_game(1, data)

	# Check file size (should be under 1MB for any reasonable map)
	var path := "user://saves/save_slot_1.json"
	var file := FileAccess.open(path, FileAccess.READ)
	assert_true(file != null, "large save file exists")
	var size_bytes := file.get_length()
	file.close()

	# Should be well under 1MB. Typical large save ~200-500KB.
	assert_true(size_bytes < 1_000_000, "large map save under 1MB (actual: %d bytes)" % size_bytes)
	# Should be non-trivial (at least 1KB)
	assert_true(size_bytes > 1000, "large map save at least 1KB (actual: %d bytes)" % size_bytes)

	_cleanup_test_saves()


## Test: delete save removes the file.
func _test_delete_save() -> void:
	_cleanup_test_saves()
	var data := _build_mock_game_data()
	SaveManager.save_game(2, data)

	assert_true(SaveManager.load_game(2) != null, "slot 2 exists before delete")

	var deleted := SaveManager.delete_save(2)
	assert_true(deleted, "delete_save returns true")
	assert_true(SaveManager.load_game(2) == null, "slot 2 null after delete")

	# Deleting non-existent slot returns false
	var deleted2 := SaveManager.delete_save(2)
	assert_false(deleted2, "deleting already-deleted slot returns false")

	_cleanup_test_saves()


## Test: slot info metadata is accurate.
func _test_slot_info_metadata() -> void:
	_cleanup_test_saves()
	var data := _build_mock_game_data()
	SaveManager.save_game(1, data)

	var slots := SaveManager.get_all_slot_info()
	assert_equal(slots.size(), SaveManager.MAX_SLOTS, "slot info has MAX_SLOTS entries")

	# Slot 1 should have data
	assert_true(slots[0]["exists"], "slot 1 exists")
	assert_false(slots[0]["corrupt"], "slot 1 not corrupt")
	assert_equal(slots[0]["map_size"], "Medium", "slot 1 map size is Medium")
	assert_equal(slots[0]["locations_total"], 3, "slot 1 has 3 locations")
	assert_equal(slots[0]["locations_completed"], 2, "slot 1 has 2 completed locations")
	assert_true(slots[0]["timestamp"].length() > 0, "slot 1 has timestamp")

	# Slot 2 should be empty
	assert_false(slots[1]["exists"], "slot 2 does not exist")
	assert_equal(slots[1]["timestamp"], "", "slot 2 has empty timestamp")

	_cleanup_test_saves()


## Test: Vector2i/Vector2 helper conversion roundtrips.
func _test_vector_helpers() -> void:
	var v2i := Vector2i(15, 22)
	var arr := SaveManager._v2i_to_arr(v2i)
	assert_equal(arr, [15, 22], "v2i_to_arr correct")
	var back := SaveManager.arr_to_v2i(arr)
	assert_equal(back, v2i, "arr_to_v2i roundtrip correct")

	var v2 := Vector2(123.5, 456.75)
	var arr2 := SaveManager._v2_to_arr(v2)
	assert_equal(arr2[0], 123.5, "v2_to_arr x correct")
	assert_equal(arr2[1], 456.75, "v2_to_arr y correct")
	var back2 := SaveManager.arr_to_v2(arr2)
	assert_equal(back2, v2, "arr_to_v2 roundtrip correct")

	# Negative coordinates
	var neg := Vector2i(-1, -1)
	var neg_arr := SaveManager._v2i_to_arr(neg)
	assert_equal(SaveManager.arr_to_v2i(neg_arr), neg, "negative v2i roundtrip correct")


## Test: invalid slot numbers are rejected.
func _test_invalid_slot() -> void:
	var data := _build_mock_game_data()

	var r1 := SaveManager.save_game(0, data)
	assert_false(r1, "slot 0 rejected for save")

	var r2 := SaveManager.save_game(-1, data)
	assert_false(r2, "slot -1 rejected for save")

	var r3 := SaveManager.save_game(SaveManager.MAX_SLOTS + 1, data)
	assert_false(r3, "slot beyond MAX_SLOTS rejected for save")

	var l1 = SaveManager.load_game(0)
	assert_true(l1 == null, "slot 0 load returns null")

	var l2 = SaveManager.load_game(SaveManager.MAX_SLOTS + 1)
	assert_true(l2 == null, "slot beyond MAX_SLOTS load returns null")


## Test: has_any_save reflects current state.
func _test_has_any_save() -> void:
	_cleanup_test_saves()
	assert_false(SaveManager.has_any_save(), "no saves: has_any_save false")

	var data := _build_mock_game_data()
	SaveManager.save_game(3, data)
	assert_true(SaveManager.has_any_save(), "after save: has_any_save true")

	SaveManager.delete_save(3)
	assert_false(SaveManager.has_any_save(), "after delete: has_any_save false")


## Test: save file includes version string.
func _test_version_stored() -> void:
	_cleanup_test_saves()
	var data := _build_mock_game_data()
	SaveManager.save_game(1, data)

	var loaded: Dictionary = SaveManager.load_game(1)
	assert_equal(loaded["version"], SaveManager.SAVE_VERSION, "version stored correctly")
	assert_true(loaded.has("timestamp"), "timestamp stored")
	assert_equal(loaded["slot"], 1, "slot number stored")

	_cleanup_test_saves()


## Test: save correctly captures completed location states.
func _test_save_with_completed_locations() -> void:
	_cleanup_test_saves()
	var data := _build_mock_game_data()

	# Verify location completion data roundtrips
	SaveManager.save_game(1, data)
	var loaded: Dictionary = SaveManager.load_game(1)
	var locs: Array = loaded["data"]["locations"]

	var completed_count := 0
	for loc in locs:
		if loc["completed"]:
			completed_count += 1
	assert_equal(completed_count, 2, "2 of 3 locations completed in save")

	# Verify item types preserved
	assert_equal(locs[0]["item_type"], Enums.ItemType.PLAYER_ITEM, "loc 0 is PLAYER_ITEM")
	assert_equal(locs[1]["item_type"], Enums.ItemType.SIZE_INCREASER, "loc 1 is SIZE_INCREASER")

	_cleanup_test_saves()


## Test: AI opponent state is fully captured and restored.
func _test_save_with_ai_state() -> void:
	_cleanup_test_saves()
	var data := _build_mock_game_data()
	SaveManager.save_game(1, data)

	var loaded: Dictionary = SaveManager.load_game(1)
	var opps: Array = loaded["data"]["opponents"]
	assert_equal(opps.size(), 2, "two opponents in save")

	# Opponent 0: Easy, exploring
	var ai0: Dictionary = opps[0]
	assert_equal(ai0["difficulty"], Enums.Difficulty.EASY, "ai0 difficulty preserved")
	assert_equal(ai0["state"], AIBrain.State.EXPLORE, "ai0 state EXPLORE")
	assert_equal(ai0["explored_cells"].size(), 3, "ai0 explored 3 cells")
	assert_equal(ai0["_rest_threshold"], 40.0, "ai0 rest threshold preserved")
	assert_equal(ai0["current_path"].size(), 2, "ai0 path has 2 steps")

	# Opponent 1: Hard, heading to exit with item
	var ai1: Dictionary = opps[1]
	assert_equal(ai1["difficulty"], Enums.Difficulty.HARD, "ai1 difficulty preserved")
	assert_equal(ai1["state"], AIBrain.State.GO_TO_EXIT, "ai1 state GO_TO_EXIT")
	assert_equal(ai1["has_item"], true, "ai1 has_item true")
	assert_equal(ai1["exit_known"], true, "ai1 exit_known true")
	assert_equal(ai1["exit_pos"], [20, 22], "ai1 exit_pos preserved")
	assert_equal(ai1["_rest_threshold"], 5.0, "ai1 rest threshold preserved")

	_cleanup_test_saves()
