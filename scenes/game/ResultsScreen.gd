class_name ResultsScreen
extends CanvasLayer

signal play_again_requested()
signal main_menu_requested()
signal view_leaderboard_requested()

var _label_title: Label
var _label_time: Label
var _label_locations: Label
var _label_size: Label
var _label_rank: Label
var _btn_view_leaderboard: Button
var _btn_play_again: Button
var _btn_main_menu: Button


func _ready() -> void:
	layer = 20
	visible = false

	var panel := Panel.new()
	panel.name = "ResultsPanel"
	panel.custom_minimum_size = Vector2(500, 430)
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left = -250
	panel.offset_top = -215
	panel.offset_right = 250
	panel.offset_bottom = 215
	add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.name = "VBox"
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 16)
	panel.add_child(vbox)

	_label_title = Label.new()
	_label_title.name = "LabelTitle"
	_label_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label_title.add_theme_font_size_override("font_size", 32)
	vbox.add_child(_label_title)

	_label_time = Label.new()
	_label_time.name = "LabelTime"
	_label_time.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label_time.add_theme_font_size_override("font_size", 18)
	vbox.add_child(_label_time)

	_label_locations = Label.new()
	_label_locations.name = "LabelLocations"
	_label_locations.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label_locations.add_theme_font_size_override("font_size", 18)
	vbox.add_child(_label_locations)

	_label_size = Label.new()
	_label_size.name = "LabelSize"
	_label_size.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label_size.add_theme_font_size_override("font_size", 18)
	vbox.add_child(_label_size)

	_label_rank = Label.new()
	_label_rank.name = "LabelRank"
	_label_rank.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label_rank.add_theme_font_size_override("font_size", 20)
	_label_rank.visible = false
	vbox.add_child(_label_rank)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 8)
	vbox.add_child(spacer)

	_btn_view_leaderboard = Button.new()
	_btn_view_leaderboard.name = "BtnViewLeaderboard"
	_btn_view_leaderboard.text = "View Leaderboard"
	_btn_view_leaderboard.visible = false
	vbox.add_child(_btn_view_leaderboard)
	_btn_view_leaderboard.pressed.connect(func(): emit_signal("view_leaderboard_requested"))

	_btn_play_again = Button.new()
	_btn_play_again.name = "BtnPlayAgain"
	_btn_play_again.text = "Play Again"
	vbox.add_child(_btn_play_again)
	_btn_play_again.pressed.connect(_on_play_again_pressed)

	_btn_main_menu = Button.new()
	_btn_main_menu.name = "BtnMainMenu"
	_btn_main_menu.text = "Main Menu"
	vbox.add_child(_btn_main_menu)
	_btn_main_menu.pressed.connect(_on_main_menu_pressed)


## rank: 1-based leaderboard rank, or -1 if leaderboard not enabled / not placed.
func show_win(time_sec: float, locations_explored: int, final_size: int, rank: int = -1) -> void:
	_label_title.text = "You Win!"
	_label_title.add_theme_color_override("font_color", Color(0.2, 1.0, 0.3))
	_fill_stats(time_sec, locations_explored, final_size)
	if rank == 1:
		_label_rank.text = "New Record!"
		_label_rank.add_theme_color_override("font_color", Color(1.0, 0.85, 0.1))
		_label_rank.visible = true
		_btn_view_leaderboard.visible = true
	elif rank > 1:
		_label_rank.text = "Leaderboard Rank: #%d" % rank
		_label_rank.add_theme_color_override("font_color", Color(0.7, 0.9, 1.0))
		_label_rank.visible = true
		_btn_view_leaderboard.visible = true
	visible = true


func show_loss(winner_name: String, time_sec: float, locations_explored: int, final_size: int) -> void:
	_label_title.text = "%s Wins!" % winner_name
	_label_title.add_theme_color_override("font_color", Color(1.0, 0.3, 0.2))
	_fill_stats(time_sec, locations_explored, final_size)
	visible = true


func _fill_stats(time_sec: float, locations_explored: int, final_size: int) -> void:
	var minutes := int(time_sec) / 60
	var seconds := int(time_sec) % 60
	_label_time.text = "Time: %d:%02d" % [minutes, seconds]
	_label_locations.text = "Cells Explored: %d" % locations_explored
	_label_size.text = "Final Size: %d" % final_size


func _on_play_again_pressed() -> void:
	emit_signal("play_again_requested")


func _on_main_menu_pressed() -> void:
	emit_signal("main_menu_requested")
