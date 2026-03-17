extends Node

const SCENE_MAIN_MENU: String = "res://scenes/menus/MainMenu.tscn"
const SCENE_NEW_GAME_SCREEN: String = "res://scenes/menus/NewGameScreen.tscn"
const SCENE_PLACEHOLDER_A: String = "res://scenes/placeholders/PlaceholderA.tscn"
const SCENE_PLACEHOLDER_B: String = "res://scenes/placeholders/PlaceholderB.tscn"
const SCENE_GAME_SCENE: String = "res://scenes/game/GameScene.tscn"
const SCENE_SETTINGS: String = "res://scenes/menus/SettingsScreen.tscn"

var _scene_container: Node = null


func _ready() -> void:
	SignalBus.scene_change_requested.connect(_on_scene_change_requested)


func set_scene_container(container: Node) -> void:
	_scene_container = container


func _on_scene_change_requested(scene_path: String) -> void:
	_load_scene(scene_path)


func _load_scene(path: String) -> void:
	if _scene_container == null:
		push_error("SceneManager: _scene_container is not set.")
		return

	SignalBus.scene_transition_started.emit(path)

	for child in _scene_container.get_children():
		child.queue_free()

	var packed: PackedScene = load(path)
	if packed == null:
		push_error("SceneManager: Failed to load scene: " + path)
		return

	var instance := packed.instantiate()
	_scene_container.add_child(instance)

	SignalBus.scene_changed.emit(path)


func go_to(path: String) -> void:
	_load_scene(path)


func go_to_main_menu() -> void:
	_load_scene(SCENE_MAIN_MENU)


func go_to_new_game_screen() -> void:
	_load_scene(SCENE_NEW_GAME_SCREEN)


func go_to_placeholder_a() -> void:
	_load_scene(SCENE_PLACEHOLDER_A)


func go_to_placeholder_b() -> void:
	_load_scene(SCENE_PLACEHOLDER_B)


func go_to_game_scene() -> void:
	_load_scene(SCENE_GAME_SCENE)


func go_to_settings() -> void:
	_load_scene(SCENE_SETTINGS)
