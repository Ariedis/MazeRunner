extends Node

const SCENE_MAIN_MENU: String = "res://scenes/menus/MainMenu.tscn"
const SCENE_NEW_GAME_SCREEN: String = "res://scenes/menus/NewGameScreen.tscn"
const SCENE_PLACEHOLDER_A: String = "res://scenes/placeholders/PlaceholderA.tscn"
const SCENE_PLACEHOLDER_B: String = "res://scenes/placeholders/PlaceholderB.tscn"
const SCENE_GAME_SCENE: String = "res://scenes/game/GameScene.tscn"
const SCENE_SETTINGS: String = "res://scenes/menus/SettingsScreen.tscn"

const FADE_DURATION: float = 0.3

var _scene_container: Node = null
var _fade_layer: CanvasLayer
var _fade_rect: ColorRect
var _transitioning: bool = false


func _ready() -> void:
	SignalBus.scene_change_requested.connect(_on_scene_change_requested)
	_setup_fade_overlay()


func _setup_fade_overlay() -> void:
	_fade_layer = CanvasLayer.new()
	_fade_layer.layer = 100
	add_child(_fade_layer)

	_fade_rect = ColorRect.new()
	_fade_rect.color = Color(0, 0, 0, 0)
	_fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade_layer.add_child(_fade_rect)


func set_scene_container(container: Node) -> void:
	_scene_container = container


func _on_scene_change_requested(scene_path: String) -> void:
	_load_scene(scene_path)


func _load_scene(path: String) -> void:
	if _scene_container == null:
		push_error("SceneManager: _scene_container is not set.")
		return

	if _transitioning:
		return

	_transitioning = true
	SignalBus.scene_transition_started.emit(path)

	# Fade out
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	var tw := create_tween()
	tw.tween_property(_fade_rect, "color:a", 1.0, FADE_DURATION)
	await tw.finished

	# Swap scene
	for child in _scene_container.get_children():
		child.queue_free()

	var packed: PackedScene = load(path)
	if packed == null:
		push_error("SceneManager: Failed to load scene: " + path)
		_transitioning = false
		_fade_rect.color.a = 0.0
		_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		return

	var instance := packed.instantiate()
	_scene_container.add_child(instance)

	SignalBus.scene_changed.emit(path)

	# Fade in
	var tw2 := create_tween()
	tw2.tween_property(_fade_rect, "color:a", 0.0, FADE_DURATION)
	await tw2.finished

	_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_transitioning = false


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
