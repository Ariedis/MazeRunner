class_name TaskOverlay
extends CanvasLayer

signal task_completed(location_id: int)

var _location_id: int = -1
var _timer_remaining: float = 0.0
var _active: bool = false
var _item_type: int = Enums.ItemType.SIZE_INCREASER

var _overlay: ColorRect
var _panel: Panel
var _label_title: Label
var _label_media: Label
var _label_desc: Label
var _label_timer: Label
var _label_reward: Label
var _btn_done: Button

const ITEM_LABELS: Dictionary = {
	Enums.ItemType.PLAYER_ITEM: "Reward: Your Item!",
	Enums.ItemType.OPPONENT_ITEM: "Reward: Opponent Item",
	Enums.ItemType.SIZE_INCREASER: "Reward: Size +1",
}


func _ready() -> void:
	layer = 10
	visible = false

	_overlay = UIHelpers.create_dim_overlay(0.5)
	add_child(_overlay)

	_panel = Panel.new()
	_panel.name = "TaskPanel"
	_panel.custom_minimum_size = Vector2(600, 400)
	_panel.set_anchors_preset(Control.PRESET_CENTER)
	_panel.offset_left = -300
	_panel.offset_top = -200
	_panel.offset_right = 300
	_panel.offset_bottom = 200
	add_child(_panel)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	_panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.name = "VBox"
	vbox.add_theme_constant_override("separation", 12)
	margin.add_child(vbox)

	var title_container := UIHelpers.create_title("", 24)
	vbox.add_child(title_container)
	_label_title = title_container.get_meta("label")

	_label_media = Label.new()
	_label_media.name = "LabelMedia"
	_label_media.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label_media.text = "[Media Placeholder]"
	vbox.add_child(_label_media)

	_label_desc = Label.new()
	_label_desc.name = "LabelDesc"
	_label_desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(_label_desc)

	_label_timer = Label.new()
	_label_timer.name = "LabelTimer"
	_label_timer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label_timer.add_theme_font_size_override("font_size", 20)
	if UITheme.font_title:
		_label_timer.add_theme_font_override("font", UITheme.font_title)
	vbox.add_child(_label_timer)

	_label_reward = Label.new()
	_label_reward.name = "LabelReward"
	_label_reward.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label_reward.add_theme_font_size_override("font_size", 22)
	_label_reward.add_theme_color_override("font_color", UITheme.GOLD)
	_label_reward.visible = false
	vbox.add_child(_label_reward)

	_btn_done = Button.new()
	_btn_done.name = "BtnDone"
	_btn_done.text = "Collect"
	_btn_done.disabled = true
	ButtonFX.apply(_btn_done)
	vbox.add_child(_btn_done)
	_btn_done.pressed.connect(_on_done_pressed)


func show_task(task: TaskData, location_id: int, item_type: int) -> void:
	_location_id = location_id
	_item_type = item_type
	_timer_remaining = task.duration_seconds
	_label_title.text = task.title
	_label_desc.text = task.description
	if task.media_path != "":
		_label_media.text = "[Media: %s]" % task.media_path
	else:
		_label_media.text = "[Media Placeholder]"
	_label_timer.text = "%.1f" % _timer_remaining
	_label_reward.visible = false
	_btn_done.disabled = true
	_active = true
	visible = true

	# Fade in
	_overlay.modulate.a = 0.0
	_panel.modulate.a = 0.0
	_panel.scale = Vector2(0.9, 0.9)
	_panel.pivot_offset = _panel.size / 2.0
	var tw := create_tween().set_parallel(true)
	tw.tween_property(_overlay, "modulate:a", 1.0, 0.2)
	tw.tween_property(_panel, "modulate:a", 1.0, 0.2)
	tw.tween_property(_panel, "scale", Vector2.ONE, 0.25).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)


func _process(delta: float) -> void:
	if not _active:
		return
	_timer_remaining = maxf(0.0, _timer_remaining - delta)
	_label_timer.text = "%.1f" % _timer_remaining
	if _timer_remaining <= 0.0:
		if _btn_done.disabled:
			_label_reward.text = ITEM_LABELS.get(_item_type, "Reward: Unknown")
			_label_reward.visible = true
		_btn_done.disabled = false


func _on_done_pressed() -> void:
	_active = false
	visible = false
	task_completed.emit(_location_id)
