extends Control

var _load_panel: SaveSlotPanel = null
var _leaderboard_overlay: LeaderboardOverlay = null


func _ready() -> void:
	GameState.current_state = Enums.GameState.MENU
	$VBoxContainer/BtnNewGame.pressed.connect(_on_new_game)
	$VBoxContainer/BtnContinue.pressed.connect(_on_continue)
	$VBoxContainer/BtnLoadGame.pressed.connect(_on_load_game)
	$VBoxContainer/BtnSettings.pressed.connect(_on_settings)
	$VBoxContainer/BtnQuit.pressed.connect(_on_quit)

	# Continue is only enabled when a save exists.
	$VBoxContainer/BtnContinue.disabled = not GameState.has_save_data()
	$VBoxContainer/BtnLoadGame.disabled = not GameState.has_save_data()

	# Add Leaderboard button before Quit.
	var btn_leaderboard := Button.new()
	btn_leaderboard.name = "BtnLeaderboard"
	btn_leaderboard.text = "Leaderboard"
	btn_leaderboard.pressed.connect(_on_leaderboard)
	var vbox := $VBoxContainer
	vbox.add_child(btn_leaderboard)
	vbox.move_child(btn_leaderboard, $VBoxContainer/BtnQuit.get_index())


func _on_new_game() -> void:
	SceneManager.go_to_new_game_screen()


func _on_continue() -> void:
	var save = SaveManager.load_most_recent()
	if save == null:
		return
	GameState.queue_load(save)
	SceneManager.go_to_game_scene()


func _on_load_game() -> void:
	if _load_panel == null:
		_load_panel = SaveSlotPanel.new(SaveSlotPanel.Mode.LOAD)
		_load_panel.name = "LoadPanel"
		add_child(_load_panel)
		_load_panel.slot_selected.connect(_on_load_slot_selected)
	_load_panel.show_panel()


func _on_load_slot_selected(slot: int) -> void:
	var save = SaveManager.load_game(slot)
	if save == null:
		return
	GameState.queue_load(save)
	SceneManager.go_to_game_scene()


func _on_settings() -> void:
	SceneManager.go_to_settings()


func _on_leaderboard() -> void:
	if _leaderboard_overlay == null or not is_instance_valid(_leaderboard_overlay):
		_leaderboard_overlay = LeaderboardOverlay.new()
		_leaderboard_overlay.name = "LeaderboardOverlay"
		add_child(_leaderboard_overlay)
	else:
		_leaderboard_overlay.queue_free()
		_leaderboard_overlay = null


func _on_quit() -> void:
	get_tree().quit()
