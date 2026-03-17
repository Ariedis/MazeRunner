class_name PauseMenu
extends CanvasLayer

signal resume_requested()
signal save_requested()
signal quit_to_menu_requested()

var _overlay: ColorRect
var _panel: Panel


func _ready() -> void:
	layer = 10
	visible = false
	_build_ui()


func _build_ui() -> void:
	_overlay = UIHelpers.create_dim_overlay(0.55)
	add_child(_overlay)

	_panel = Panel.new()
	_panel.custom_minimum_size = Vector2(300, 230)
	_panel.set_anchors_preset(Control.PRESET_CENTER)
	_panel.offset_left = -150
	_panel.offset_top = -115
	_panel.offset_right = 150
	_panel.offset_bottom = 115
	add_child(_panel)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 14)
	_panel.add_child(vbox)

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

	var title_container := UIHelpers.create_title("PAUSED", 28)
	inner.add_child(title_container)

	var btn_resume := Button.new()
	btn_resume.text = "Resume"
	btn_resume.pressed.connect(_on_resume)
	ButtonFX.apply(btn_resume)
	inner.add_child(btn_resume)

	var btn_save := Button.new()
	btn_save.text = "Save Game"
	btn_save.pressed.connect(_on_save)
	ButtonFX.apply(btn_save)
	inner.add_child(btn_save)

	var btn_quit := Button.new()
	btn_quit.text = "Quit to Menu"
	btn_quit.pressed.connect(_on_quit)
	ButtonFX.apply(btn_quit)
	inner.add_child(btn_quit)


func show_menu() -> void:
	visible = true
	_overlay.modulate.a = 0.0
	_panel.scale = Vector2(0.9, 0.9)
	_panel.modulate.a = 0.0
	_panel.pivot_offset = _panel.size / 2.0

	var tw := create_tween().set_parallel(true)
	tw.tween_property(_overlay, "modulate:a", 1.0, 0.2)
	tw.tween_property(_panel, "modulate:a", 1.0, 0.2)
	tw.tween_property(_panel, "scale", Vector2.ONE, 0.25).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)


func hide_menu() -> void:
	var tw := create_tween().set_parallel(true)
	tw.tween_property(_overlay, "modulate:a", 0.0, 0.15)
	tw.tween_property(_panel, "modulate:a", 0.0, 0.15)
	tw.tween_property(_panel, "scale", Vector2(0.9, 0.9), 0.15)
	await tw.finished
	visible = false


func _on_resume() -> void:
	emit_signal("resume_requested")


func _on_save() -> void:
	emit_signal("save_requested")


func _on_quit() -> void:
	emit_signal("quit_to_menu_requested")
