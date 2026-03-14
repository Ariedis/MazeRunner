extends Control


func _ready() -> void:
	GameState.current_state = Enums.GameState.MENU
	$VBoxContainer/BtnPlaceholderA.pressed.connect(_on_placeholder_a_pressed)
	$VBoxContainer/BtnPlaceholderB.pressed.connect(_on_placeholder_b_pressed)
	$VBoxContainer/BtnQuit.pressed.connect(_on_quit_pressed)


func _on_placeholder_a_pressed() -> void:
	SceneManager.go_to_placeholder_a()


func _on_placeholder_b_pressed() -> void:
	SceneManager.go_to_placeholder_b()


func _on_quit_pressed() -> void:
	get_tree().quit()
