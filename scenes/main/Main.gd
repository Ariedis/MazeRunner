extends Node


func _ready() -> void:
	SceneManager.set_scene_container($SceneContainer)
	SceneManager.go_to_main_menu()
