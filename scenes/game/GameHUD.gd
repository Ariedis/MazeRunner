class_name GameHUD
extends CanvasLayer

var _portrait: ColorRect
var _item_indicator: ColorRect
var _label_size: Label
var _label_speed: Label
var _energy_fill: ColorRect
var _energy_bg: Panel
var _label_rejection: Label
var _label_traps: Label

var _energy_pulse_tween: Tween = null
var _last_energy_pct: float = 100.0

## item_collected tracks whether the indicator is visible (for testing).
var item_collected: bool = false


func _ready() -> void:
	layer = 5
	_build_ui()


func _build_ui() -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	# Portrait (top-left)
	_portrait = ColorRect.new()
	_portrait.size = Vector2(64, 64)
	_portrait.position = Vector2(10, 10)
	_portrait.color = UITheme.AVATAR_COLORS[0]
	root.add_child(_portrait)

	var avatar_label := Label.new()
	avatar_label.text = "1"
	avatar_label.add_theme_font_size_override("font_size", 22)
	avatar_label.add_theme_color_override("font_color", Color.WHITE)
	if UITheme.font_title:
		avatar_label.add_theme_font_override("font", UITheme.font_title)
	avatar_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	avatar_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	avatar_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	avatar_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_portrait.add_child(avatar_label)

	# Item indicator (top-right corner of portrait, hidden until collected)
	_item_indicator = ColorRect.new()
	_item_indicator.size = Vector2(20, 20)
	_item_indicator.position = Vector2(44, 0)
	_item_indicator.color = UITheme.GOLD
	_item_indicator.visible = false
	_portrait.add_child(_item_indicator)

	var star := Label.new()
	star.text = "★"
	star.add_theme_font_size_override("font_size", 12)
	star.add_theme_color_override("font_color", Color.WHITE)
	star.set_anchors_preset(Control.PRESET_FULL_RECT)
	star.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	star.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	star.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_item_indicator.add_child(star)

	# Stats panel below portrait
	var stats := VBoxContainer.new()
	stats.position = Vector2(10, 82)
	stats.custom_minimum_size = Vector2(160, 0)
	stats.add_theme_constant_override("separation", 4)
	root.add_child(stats)

	_label_size = Label.new()
	_label_size.text = "Size: 1"
	_label_size.add_theme_font_size_override("font_size", 14)
	stats.add_child(_label_size)

	_label_speed = Label.new()
	_label_speed.text = "Speed: Full"
	_label_speed.add_theme_font_size_override("font_size", 14)
	_label_speed.add_theme_color_override("font_color", UITheme.SUCCESS)
	stats.add_child(_label_speed)

	var energy_lbl := Label.new()
	energy_lbl.text = "Energy:"
	energy_lbl.add_theme_font_size_override("font_size", 13)
	stats.add_child(energy_lbl)

	_energy_bg = Panel.new()
	_energy_bg.custom_minimum_size = Vector2(140, 14)
	var bg_style := StyleBoxFlat.new()
	bg_style.bg_color = Color(0.05, 0.05, 0.10)
	bg_style.set_corner_radius_all(4)
	bg_style.border_color = UITheme.PANEL_BORDER.darkened(0.2)
	bg_style.set_border_width_all(1)
	_energy_bg.add_theme_stylebox_override("panel", bg_style)
	stats.add_child(_energy_bg)

	_energy_fill = ColorRect.new()
	_energy_fill.color = UITheme.SUCCESS
	_energy_fill.size = Vector2(140, 14)
	_energy_fill.position = Vector2.ZERO
	_energy_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_energy_bg.add_child(_energy_fill)

	# Trap counter (hidden until traps feature is enabled).
	_label_traps = Label.new()
	_label_traps.text = "Traps: 0"
	_label_traps.add_theme_font_size_override("font_size", 14)
	_label_traps.add_theme_color_override("font_color", UITheme.TRAP_RED)
	_label_traps.visible = false
	stats.add_child(_label_traps)

	# Rejection message (centered near top)
	_label_rejection = Label.new()
	_label_rejection.add_theme_font_size_override("font_size", 20)
	_label_rejection.add_theme_color_override("font_color", UITheme.ERROR)
	_label_rejection.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label_rejection.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_label_rejection.offset_top = 16
	_label_rejection.offset_bottom = 50
	_label_rejection.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label_rejection.visible = false
	root.add_child(_label_rejection)


## Call once after instantiation to apply avatar selection.
func setup(avatar_id: int) -> void:
	var idx := clampi(avatar_id, 0, UITheme.AVATAR_COLORS.size() - 1)
	_portrait.color = UITheme.AVATAR_COLORS[idx]
	var lbl := _portrait.get_child(0) as Label
	if lbl:
		lbl.text = str(idx + 1)


func update_size(value: int) -> void:
	_label_size.text = "Size: %d" % value
	_flash_label(_label_size)


func update_energy(value: float) -> void:
	var pct := clampf(value, 0.0, 100.0)
	var target_width := 140.0 * pct / 100.0
	var target_color: Color
	if pct > 50.0:
		target_color = UITheme.SUCCESS
	elif pct > 25.0:
		target_color = UITheme.WARNING
	else:
		target_color = UITheme.ERROR

	# Tween width and color
	var tw := create_tween().set_parallel(true)
	tw.tween_property(_energy_fill, "size:x", target_width, 0.3)
	tw.tween_property(_energy_fill, "color", target_color, 0.3)

	# Start/stop pulse for low energy
	if pct <= 25.0 and _last_energy_pct > 25.0:
		_start_energy_pulse()
	elif pct > 25.0 and _energy_pulse_tween != null:
		_stop_energy_pulse()

	_last_energy_pct = pct


func _start_energy_pulse() -> void:
	_stop_energy_pulse()
	_energy_pulse_tween = create_tween().set_loops()
	_energy_pulse_tween.tween_property(_energy_fill, "modulate:a", 0.4, 0.5)
	_energy_pulse_tween.tween_property(_energy_fill, "modulate:a", 1.0, 0.5)


func _stop_energy_pulse() -> void:
	if _energy_pulse_tween != null:
		_energy_pulse_tween.kill()
		_energy_pulse_tween = null
	_energy_fill.modulate.a = 1.0


func update_speed(is_full: bool) -> void:
	if is_full:
		_label_speed.text = "Speed: Full"
		_label_speed.add_theme_color_override("font_color", UITheme.SUCCESS)
	else:
		_label_speed.text = "Speed: Half"
		_label_speed.add_theme_color_override("font_color", UITheme.ERROR)
	_flash_label(_label_speed)


func _flash_label(label: Label) -> void:
	label.pivot_offset = label.size / 2.0
	var tw := create_tween()
	tw.tween_property(label, "scale", Vector2(1.2, 1.2), 0.08)
	tw.tween_property(label, "scale", Vector2.ONE, 0.15).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)


func show_item_collected() -> void:
	item_collected = true
	_item_indicator.visible = true


func show_trap_count(count: int) -> void:
	_label_traps.text = "Traps: %d" % count
	_label_traps.visible = true


func show_rejection_message(msg: String) -> void:
	_label_rejection.text = msg
	_label_rejection.visible = true
	get_tree().create_timer(2.5).timeout.connect(func(): _label_rejection.visible = false)
