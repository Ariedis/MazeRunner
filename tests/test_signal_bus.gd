extends TestBase


func _init() -> void:
	_test_name = "test_signal_bus"


func run_tests() -> void:
	_test_scene_change_requested()
	_test_scene_transition_started()
	_test_game_state_changed()


func _test_scene_change_requested() -> void:
	var received_path: String = ""
	var callable := func(scene_path: String) -> void:
		received_path = scene_path

	SignalBus.scene_change_requested.connect(callable)
	SignalBus.scene_change_requested.emit("res://test/path.tscn")
	SignalBus.scene_change_requested.disconnect(callable)

	assert_equal(received_path, "res://test/path.tscn", "scene_change_requested emits correct path")


func _test_scene_transition_started() -> void:
	var received_path: String = ""
	var callable := func(target_path: String) -> void:
		received_path = target_path

	SignalBus.scene_transition_started.connect(callable)
	SignalBus.scene_transition_started.emit("res://scenes/test.tscn")
	SignalBus.scene_transition_started.disconnect(callable)

	assert_equal(received_path, "res://scenes/test.tscn", "scene_transition_started emits and receives")


func _test_game_state_changed() -> void:
	var captured_old: int = -1
	var captured_new: int = -1
	var callable := func(old_state: int, new_state: int) -> void:
		captured_old = old_state
		captured_new = new_state

	SignalBus.game_state_changed.connect(callable)
	SignalBus.game_state_changed.emit(0, 3)
	SignalBus.game_state_changed.disconnect(callable)

	assert_equal(captured_old, 0, "game_state_changed: old_state == 0")
	assert_equal(captured_new, 3, "game_state_changed: new_state == 3")
