class_name SaveSlotPanel
extends CanvasLayer

signal slot_selected(slot: int)
signal panel_closed()

enum Mode { SAVE, LOAD }

var _mode: int = Mode.SAVE
var _slot_buttons: Array[Button] = []
var _delete_buttons: Array[Button] = []
var _inner: VBoxContainer
var _confirm_overlay: ColorRect = null
var _pending_slot: int = -1


func _init(mode: int = Mode.SAVE) -> void:
	_mode = mode


func _ready() -> void:
	layer = 30
	visible = false
	_build_ui()


func show_panel() -> void:
	_refresh_slots()
	visible = true


func hide_panel() -> void:
	visible = false
	_hide_confirm()


func _build_ui() -> void:
	var overlay := ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.6)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(overlay)

	var panel := Panel.new()
	panel.custom_minimum_size = Vector2(420, 400)
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left = -210
	panel.offset_top = -200
	panel.offset_right = 210
	panel.offset_bottom = 200
	add_child(panel)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	panel.add_child(margin)

	_inner = VBoxContainer.new()
	_inner.add_theme_constant_override("separation", 8)
	margin.add_child(_inner)

	var title := Label.new()
	title.text = "Save Game" if _mode == Mode.SAVE else "Load Game"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	_inner.add_child(title)

	for slot in range(1, SaveManager.MAX_SLOTS + 1):
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)
		_inner.add_child(row)

		var btn := Button.new()
		btn.text = "Slot %d — Empty" % slot
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.pressed.connect(_on_slot_pressed.bind(slot))
		row.add_child(btn)
		_slot_buttons.append(btn)

		var del_btn := Button.new()
		del_btn.text = "X"
		del_btn.custom_minimum_size = Vector2(36, 0)
		del_btn.pressed.connect(_on_delete_pressed.bind(slot))
		row.add_child(del_btn)
		_delete_buttons.append(del_btn)

	var btn_back := Button.new()
	btn_back.text = "Back"
	btn_back.pressed.connect(_on_back)
	_inner.add_child(btn_back)


func _refresh_slots() -> void:
	var slots := SaveManager.get_all_slot_info()
	for i in slots.size():
		var info: Dictionary = slots[i]
		var btn: Button = _slot_buttons[i]
		var del: Button = _delete_buttons[i]

		if info["corrupt"]:
			btn.text = "Slot %d — CORRUPT" % info["slot"]
			btn.disabled = (_mode == Mode.LOAD)
			del.visible = true
		elif info["exists"]:
			var ts: String = info["timestamp"]
			var display_ts := ts.substr(0, 16).replace("T", " ") if ts.length() > 16 else ts
			btn.text = "Slot %d — %s  %s (%d/%d)" % [
				info["slot"], info["map_size"], display_ts,
				info["locations_completed"], info["locations_total"]]
			btn.disabled = false
			del.visible = true
		else:
			btn.text = "Slot %d — Empty" % info["slot"]
			btn.disabled = (_mode == Mode.LOAD)
			del.visible = false


func _on_slot_pressed(slot: int) -> void:
	if _mode == Mode.SAVE:
		var slots := SaveManager.get_all_slot_info()
		var info: Dictionary = slots[slot - 1]
		if info["exists"] and not info["corrupt"]:
			_show_confirm(slot)
			return
	slot_selected.emit(slot)
	hide_panel()


func _on_delete_pressed(slot: int) -> void:
	SaveManager.delete_save(slot)
	_refresh_slots()


func _on_back() -> void:
	hide_panel()
	panel_closed.emit()


func _show_confirm(slot: int) -> void:
	_pending_slot = slot
	if _confirm_overlay != null:
		_confirm_overlay.queue_free()

	_confirm_overlay = ColorRect.new()
	_confirm_overlay.color = Color(0, 0, 0, 0.7)
	_confirm_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_confirm_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_confirm_overlay)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_CENTER)
	vbox.offset_left = -140
	vbox.offset_top = -50
	vbox.offset_right = 140
	vbox.offset_bottom = 50
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 12)
	_confirm_overlay.add_child(vbox)

	var lbl := Label.new()
	lbl.text = "Overwrite Slot %d?" % slot
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 20)
	vbox.add_child(lbl)

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 16)
	vbox.add_child(row)

	var btn_yes := Button.new()
	btn_yes.text = "Overwrite"
	btn_yes.pressed.connect(_on_confirm_yes)
	row.add_child(btn_yes)

	var btn_no := Button.new()
	btn_no.text = "Cancel"
	btn_no.pressed.connect(_on_confirm_no)
	row.add_child(btn_no)


func _hide_confirm() -> void:
	if _confirm_overlay != null:
		_confirm_overlay.queue_free()
		_confirm_overlay = null
	_pending_slot = -1


func _on_confirm_yes() -> void:
	var slot := _pending_slot
	_hide_confirm()
	slot_selected.emit(slot)
	hide_panel()


func _on_confirm_no() -> void:
	_hide_confirm()
