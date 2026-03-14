extends Control


func _ready() -> void:
	$VBoxContainer/BtnGoToB.pressed.connect(_on_go_to_b_pressed)
	$VBoxContainer/BtnMainMenu.pressed.connect(_on_main_menu_pressed)


func _on_go_to_b_pressed() -> void:
	SceneManager.go_to_placeholder_b()


func _on_main_menu_pressed() -> void:
	SceneManager.go_to_main_menu()
