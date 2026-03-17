extends Control

var _load_panel: SaveSlotPanel = null
var _leaderboard_overlay: LeaderboardOverlay = null
var _title_label: Label = null


func _ready() -> void:
	GameState.current_state = Enums.GameState.MENU

	# Add dark background
	var bg := ColorRect.new()
	bg.color = UITheme.BG_DARK
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	move_child(bg, 0)

	$VBoxContainer/BtnNewGame.pressed.connect(_on_new_game)
	$VBoxContainer/BtnContinue.pressed.connect(_on_continue)
	$VBoxContainer/BtnLoadGame.pressed.connect(_on_load_game)
	$VBoxContainer/BtnSettings.pressed.connect(_on_settings)
	$VBoxContainer/BtnQuit.pressed.connect(_on_quit)

	# Continue is only enabled when a save exists.
	$VBoxContainer/BtnContinue.disabled = not GameState.has_save_data()
	$VBoxContainer/BtnLoadGame.disabled = not GameState.has_save_data()

	# Style the title with display font
	_title_label = $VBoxContainer/LabelTitle
	if UITheme.font_title:
		_title_label.add_theme_font_override("font", UITheme.font_title)
	_start_title_color_cycle()

	# Add Leaderboard button before Quit.
	var btn_leaderboard := Button.new()
	btn_leaderboard.name = "BtnLeaderboard"
	btn_leaderboard.text = "Leaderboard"
	btn_leaderboard.pressed.connect(_on_leaderboard)
	var vbox := $VBoxContainer
	vbox.add_child(btn_leaderboard)
	vbox.move_child(btn_leaderboard, $VBoxContainer/BtnQuit.get_index())

	# Apply button micro-interactions
	for child in vbox.get_children():
		if child is Button:
			ButtonFX.apply(child)


func _start_title_color_cycle() -> void:
	var colors: Array[Color] = [
		UITheme.ACCENT,
		Color(0.6, 0.4, 1.0),
		UITheme.GOLD,
		Color(0.3, 0.8, 1.0),
		UITheme.ACCENT,
	]
	# Set the initial color so the first tween has a valid start value.
	_title_label.add_theme_color_override("font_color", colors[0])
	var tw := create_tween().set_loops()
	tw.tween_property(_title_label, "theme_override_colors/font_color", colors[1], 2.0)
	tw.tween_property(_title_label, "theme_override_colors/font_color", colors[2], 2.0)
	tw.tween_property(_title_label, "theme_override_colors/font_color", colors[3], 2.0)
	tw.tween_property(_title_label, "theme_override_colors/font_color", colors[4], 2.0)


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
