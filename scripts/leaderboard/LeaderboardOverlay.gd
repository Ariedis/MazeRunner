class_name LeaderboardOverlay
extends CanvasLayer

## Code-driven leaderboard overlay with tabs for Small / Medium / Large.

const SIZE_KEYS: Array = [Enums.MapSize.SMALL, Enums.MapSize.MEDIUM, Enums.MapSize.LARGE]
const SIZE_NAMES: Array = ["Small", "Medium", "Large"]

var _overlay: ColorRect
var _panel: Panel
var _tab_buttons: Array = []
var _tab_panels: Array = []
var _current_tab: int = 0


func _ready() -> void:
	layer = 25
	_build_ui()
	_show_tab(0)

	# Animate in
	_overlay.modulate.a = 0.0
	_panel.modulate.a = 0.0
	_panel.scale = Vector2(0.9, 0.9)
	_panel.pivot_offset = _panel.size / 2.0
	var tw := create_tween().set_parallel(true)
	tw.tween_property(_overlay, "modulate:a", 1.0, 0.2)
	tw.tween_property(_panel, "modulate:a", 1.0, 0.2)
	tw.tween_property(_panel, "scale", Vector2.ONE, 0.25).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)


func _build_ui() -> void:
	_overlay = UIHelpers.create_dim_overlay(0.7)
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_overlay)

	_panel = Panel.new()
	_panel.custom_minimum_size = Vector2(600, 440)
	_panel.set_anchors_preset(Control.PRESET_CENTER)
	_panel.offset_left  = -300
	_panel.offset_top   = -220
	_panel.offset_right =  300
	_panel.offset_bottom = 220
	add_child(_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left",   16)
	margin.add_theme_constant_override("margin_right",  16)
	margin.add_theme_constant_override("margin_top",    12)
	margin.add_theme_constant_override("margin_bottom", 12)
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	_panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	margin.add_child(vbox)

	# Title row.
	var title_row := HBoxContainer.new()
	title_row.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(title_row)

	var title := Label.new()
	title.text = "LEADERBOARD"
	title.add_theme_font_size_override("font_size", 24)
	if UITheme.font_title:
		title.add_theme_font_override("font", UITheme.font_title)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_row.add_child(title)

	var btn_close := Button.new()
	btn_close.text = "X"
	btn_close.custom_minimum_size = Vector2(32, 0)
	btn_close.pressed.connect(queue_free)
	ButtonFX.apply(btn_close)
	title_row.add_child(btn_close)

	vbox.add_child(HSeparator.new())

	# Tab buttons.
	var tab_row := HBoxContainer.new()
	tab_row.add_theme_constant_override("separation", 4)
	vbox.add_child(tab_row)

	for i in SIZE_NAMES.size():
		var btn := Button.new()
		btn.text = SIZE_NAMES[i]
		btn.custom_minimum_size = Vector2(120, 0)
		btn.pressed.connect(_show_tab.bind(i))
		ButtonFX.apply(btn)
		tab_row.add_child(btn)
		_tab_buttons.append(btn)

	vbox.add_child(HSeparator.new())

	# One panel per size.
	for i in SIZE_KEYS.size():
		var scroll := ScrollContainer.new()
		scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
		scroll.visible = false
		vbox.add_child(scroll)

		var inner := VBoxContainer.new()
		inner.add_theme_constant_override("separation", 2)
		inner.custom_minimum_size = Vector2(550, 0)
		scroll.add_child(inner)

		# Header row.
		var header := _make_row("Rank", "Time", "Date", "Size", "Opp.", true)
		inner.add_child(header)
		inner.add_child(HSeparator.new())

		var entries := LeaderboardManager.get_entries(SIZE_KEYS[i])
		if entries.is_empty():
			var empty_lbl := Label.new()
			empty_lbl.text = "No entries yet."
			empty_lbl.add_theme_color_override("font_color", UITheme.TEXT_DIM)
			inner.add_child(empty_lbl)
		else:
			for j in entries.size():
				var e: Dictionary = entries[j]
				var mins := int(e["time_sec"]) / 60
				var secs := int(e["time_sec"]) % 60
				var time_str := "%d:%02d" % [mins, secs]
				var row := _make_row(
					"#%d" % (j + 1),
					time_str,
					str(e.get("date", "—")),
					str(e.get("size", "—")),
					str(e.get("opponents", "—")),
					false
				)
				inner.add_child(row)

		_tab_panels.append(scroll)


func _show_tab(idx: int) -> void:
	_current_tab = idx
	for i in _tab_panels.size():
		_tab_panels[i].visible = (i == idx)
	for i in _tab_buttons.size():
		_tab_buttons[i].flat = (i != idx)


func _make_row(rank: String, time: String, date: String, sz: String, opp: String, bold: bool) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	var cols := [rank, time, date, sz, opp]
	var widths := [60, 80, 120, 60, 60]
	for i in cols.size():
		var lbl := Label.new()
		lbl.text = cols[i]
		lbl.custom_minimum_size = Vector2(widths[i], 0)
		if bold:
			lbl.add_theme_font_size_override("font_size", 14)
			lbl.add_theme_color_override("font_color", UITheme.HEADER_GOLD)
			if UITheme.font_title:
				lbl.add_theme_font_override("font", UITheme.font_title)
		row.add_child(lbl)
	return row
