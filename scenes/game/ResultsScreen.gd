class_name ResultsScreen
extends CanvasLayer

signal play_again_requested()
signal main_menu_requested()
signal view_leaderboard_requested()

var _overlay: ColorRect
var _panel: Panel
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

	_overlay = UIHelpers.create_dim_overlay(0.6)
	add_child(_overlay)

	_panel = Panel.new()
	_panel.name = "ResultsPanel"
	_panel.custom_minimum_size = Vector2(500, 430)
	_panel.set_anchors_preset(Control.PRESET_CENTER)
	_panel.offset_left = -250
	_panel.offset_top = -215
	_panel.offset_right = 250
	_panel.offset_bottom = 215
	add_child(_panel)

	var vbox := VBoxContainer.new()
	vbox.name = "VBox"
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 16)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	_panel.add_child(margin)
	margin.add_child(vbox)

	_label_title = Label.new()
	_label_title.name = "LabelTitle"
	_label_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label_title.add_theme_font_size_override("font_size", 32)
	if UITheme.font_title:
		_label_title.add_theme_font_override("font", UITheme.font_title)
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
	ButtonFX.apply(_btn_view_leaderboard)
	vbox.add_child(_btn_view_leaderboard)
	_btn_view_leaderboard.pressed.connect(func(): emit_signal("view_leaderboard_requested"))

	_btn_play_again = Button.new()
	_btn_play_again.name = "BtnPlayAgain"
	_btn_play_again.text = "Play Again"
	ButtonFX.apply(_btn_play_again)
	vbox.add_child(_btn_play_again)
	_btn_play_again.pressed.connect(_on_play_again_pressed)

	_btn_main_menu = Button.new()
	_btn_main_menu.name = "BtnMainMenu"
	_btn_main_menu.text = "Main Menu"
	ButtonFX.apply(_btn_main_menu)
	vbox.add_child(_btn_main_menu)
	_btn_main_menu.pressed.connect(_on_main_menu_pressed)


## rank: 1-based leaderboard rank, or -1 if leaderboard not enabled / not placed.
func show_win(time_sec: float, locations_explored: int, final_size: int, rank: int = -1) -> void:
	_label_title.text = "You Win!"
	_label_title.add_theme_color_override("font_color", UITheme.SUCCESS)
	_fill_stats(time_sec, locations_explored, final_size)
	if rank == 1:
		_label_rank.text = "New Record!"
		_label_rank.add_theme_color_override("font_color", UITheme.GOLD)
		_label_rank.visible = true
		_btn_view_leaderboard.visible = true
		_animate_rank_bounce()
	elif rank > 1:
		_label_rank.text = "Leaderboard Rank: #%d" % rank
		_label_rank.add_theme_color_override("font_color", UITheme.RANK_BLUE)
		_label_rank.visible = true
		_btn_view_leaderboard.visible = true
	_show_animated()


func show_loss(winner_name: String, time_sec: float, locations_explored: int, final_size: int) -> void:
	_label_title.text = "%s Wins!" % winner_name
	_label_title.add_theme_color_override("font_color", UITheme.ERROR)
	_fill_stats(time_sec, locations_explored, final_size)
	_show_animated()


func _show_animated() -> void:
	visible = true

	# Animate title bounce
	_label_title.pivot_offset = _label_title.size / 2.0
	_label_title.scale = Vector2.ZERO

	_overlay.modulate.a = 0.0
	_panel.modulate.a = 0.0
	_panel.scale = Vector2(0.9, 0.9)
	_panel.pivot_offset = _panel.size / 2.0

	var tw := create_tween().set_parallel(true)
	tw.tween_property(_overlay, "modulate:a", 1.0, 0.2)
	tw.tween_property(_panel, "modulate:a", 1.0, 0.2)
	tw.tween_property(_panel, "scale", Vector2.ONE, 0.3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tw.tween_property(_label_title, "scale", Vector2.ONE, 0.4).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK).set_delay(0.15)


func _fill_stats(time_sec: float, locations_explored: int, final_size: int) -> void:
	var minutes := int(time_sec) / 60
	var seconds := int(time_sec) % 60

	# Start at zero, then count up
	_label_time.text = "Time: 0:00"
	_label_locations.text = "Cells Explored: 0"
	_label_size.text = "Final Size: 0"

	var tw := create_tween()
	# Time count-up
	tw.tween_method(func(val: float):
		var t := int(val)
		_label_time.text = "Time: %d:%02d" % [t / 60, t % 60]
	, 0.0, time_sec, 0.6).set_delay(0.4)

	# Cells count-up
	tw.tween_method(func(val: float):
		_label_locations.text = "Cells Explored: %d" % int(val)
	, 0.0, float(locations_explored), 0.5)

	# Size count-up
	tw.tween_method(func(val: float):
		_label_size.text = "Final Size: %d" % int(val)
	, 0.0, float(final_size), 0.4)


func _animate_rank_bounce() -> void:
	# Delayed so it appears after stats count up
	var tw := create_tween()
	_label_rank.modulate.a = 0.0
	_label_rank.pivot_offset = _label_rank.size / 2.0
	_label_rank.scale = Vector2(1.5, 1.5)
	tw.set_parallel(true)
	tw.tween_property(_label_rank, "modulate:a", 1.0, 0.3).set_delay(1.8)
	tw.tween_property(_label_rank, "scale", Vector2.ONE, 0.4).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK).set_delay(1.8)


func _on_play_again_pressed() -> void:
	emit_signal("play_again_requested")


func _on_main_menu_pressed() -> void:
	emit_signal("main_menu_requested")
