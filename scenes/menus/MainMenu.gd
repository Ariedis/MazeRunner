extends Control


func _ready() -> void:
	GameState.current_state = Enums.GameState.MENU
	$VBoxContainer/BtnNewGame.pressed.connect(_on_new_game)
	$VBoxContainer/BtnContinue.pressed.connect(_on_continue)
	$VBoxContainer/BtnQuit.pressed.connect(_on_quit)

	# Continue is only enabled when a save exists (Phase 10 will implement saves).
	$VBoxContainer/BtnContinue.disabled = not GameState.has_save_data()


func _on_new_game() -> void:
	SceneManager.go_to_new_game_screen()


func _on_continue() -> void:
	# Phase 10: load most recent save and go to game scene
	pass


func _on_quit() -> void:
	get_tree().quit()
