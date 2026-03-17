class_name PauseMenu
extends CanvasLayer

signal resume_requested()
signal save_requested()
signal quit_to_menu_requested()


func _ready() -> void:
	layer = 10
	visible = false
	_build_ui()


func _build_ui() -> void:
	var overlay := ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.55)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(overlay)

	var panel := Panel.new()
	panel.custom_minimum_size = Vector2(300, 230)
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left = -150
	panel.offset_top = -115
	panel.offset_right = 150
	panel.offset_bottom = 115
	add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 14)
	panel.add_child(vbox)

	# Margin so content doesn't touch panel edges
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	vbox.add_child(margin)

	var inner := VBoxContainer.new()
	inner.add_theme_constant_override("separation", 14)
	inner.alignment = BoxContainer.ALIGNMENT_CENTER
	margin.add_child(inner)

	var title := Label.new()
	title.text = "PAUSED"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	inner.add_child(title)

	var btn_resume := Button.new()
	btn_resume.text = "Resume"
	btn_resume.pressed.connect(_on_resume)
	inner.add_child(btn_resume)

	var btn_save := Button.new()
	btn_save.text = "Save Game"
	btn_save.pressed.connect(_on_save)
	inner.add_child(btn_save)

	var btn_quit := Button.new()
	btn_quit.text = "Quit to Menu"
	btn_quit.pressed.connect(_on_quit)
	inner.add_child(btn_quit)


func show_menu() -> void:
	visible = true


func hide_menu() -> void:
	visible = false


func _on_resume() -> void:
	emit_signal("resume_requested")


func _on_save() -> void:
	emit_signal("save_requested")


func _on_quit() -> void:
	emit_signal("quit_to_menu_requested")
