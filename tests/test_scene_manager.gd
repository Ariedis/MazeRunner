extends TestBase


func _init() -> void:
	_test_name = "test_scene_manager"


func run_tests() -> void:
	_test_path_constants()
	_test_scene_container_set()
	_test_scene_change_connected()


func _test_path_constants() -> void:
	assert_true(SceneManager.SCENE_MAIN_MENU.length() > 0, "SCENE_MAIN_MENU is non-empty")
	assert_true(SceneManager.SCENE_PLACEHOLDER_A.length() > 0, "SCENE_PLACEHOLDER_A is non-empty")
	assert_true(SceneManager.SCENE_PLACEHOLDER_B.length() > 0, "SCENE_PLACEHOLDER_B is non-empty")


func _test_scene_container_set() -> void:
	var container = SceneManager._scene_container
	assert_true(container != null, "_scene_container is not null")
	assert_true(container is Node, "_scene_container is a Node")


func _test_scene_change_connected() -> void:
	var connection_count := SignalBus.scene_change_requested.get_connections().size()
	assert_gt(connection_count, 0, "scene_change_requested has at least one connection")
