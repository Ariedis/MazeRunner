extends Control


func _ready() -> void:
	$VBoxContainer/BtnGoToA.pressed.connect(_on_go_to_a_pressed)
	$VBoxContainer/BtnMainMenu.pressed.connect(_on_main_menu_pressed)


func _on_go_to_a_pressed() -> void:
	SceneManager.go_to_placeholder_a()


func _on_main_menu_pressed() -> void:
	SceneManager.go_to_main_menu()
