extends Node

const TEST_CLASSES: Array[String] = [
	"res://tests/test_enums.gd",
	"res://tests/test_game_state.gd",
	"res://tests/test_signal_bus.gd",
	"res://tests/test_scene_manager.gd",
	"res://tests/test_maze_generator.gd",
]


func _ready() -> void:
	call_deferred("_run_all_tests")


func _run_all_tests() -> void:
	print("=== Maze Battle Test Runner ===")
	var total_pass := 0
	var total_fail := 0

	for path in TEST_CLASSES:
		var script: GDScript = load(path)
		if script == null:
			push_error("TestRunner: Could not load test script: " + path)
			total_fail += 1
			continue

		var instance: TestBase = script.new()
		add_child(instance)
		instance.run_tests()

		for line in instance.get_results():
			print(line)
		print(instance.get_summary())
		print("")

		total_pass += instance.get_pass_count()
		total_fail += instance.get_fail_count()

		instance.queue_free()

	print("=== TOTAL: PASS %d  FAIL %d ===" % [total_pass, total_fail])

	if total_fail > 0:
		get_tree().quit(1)
	else:
		get_tree().quit(0)
