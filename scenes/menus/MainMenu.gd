extends Control


func _ready() -> void:
	GameState.current_state = Enums.GameState.MENU
	$VBoxContainer/BtnStartGame.pressed.connect(_on_start_game_pressed)
	$VBoxContainer/BtnPlaceholderA.pressed.connect(_on_placeholder_a_pressed)
	$VBoxContainer/BtnPlaceholderB.pressed.connect(_on_placeholder_b_pressed)
	$VBoxContainer/BtnQuit.pressed.connect(_on_quit_pressed)


func _on_start_game_pressed() -> void:
	GameState.config["map_size"] = Enums.MapSize.SMALL
	GameState.config["seed"] = 0
	SceneManager.go_to_game_scene()


func _on_placeholder_a_pressed() -> void:
	SceneManager.go_to_placeholder_a()


func _on_placeholder_b_pressed() -> void:
	SceneManager.go_to_placeholder_b()


func _on_quit_pressed() -> void:
	get_tree().quit()
