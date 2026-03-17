class_name ClashOverlay
extends CanvasLayer

## Emitted when the player won and dismisses the resolution screen.
signal clash_resolved()

## Emitted when the player's penalty timer completes and they click "Done".
signal penalty_completed()

# --- Phase constants ---
const _PHASE_RESOLUTION := 0  # Dice roll result screen.
const _PHASE_PENALTY    := 1  # Penalty task screen (player lost).

var _phase: int = _PHASE_RESOLUTION
var _player_won: bool = false

# Transition delay (seconds) from resolution screen to penalty screen.
const _TRANSITION_DELAY: float = 1.5
var _transition_timer: float = 0.0
var _awaiting_transition: bool = false

# Penalty countdown.
var _penalty_timer: float = 0.0
var _penalty_active: bool = false

# --- UI nodes ---
var _overlay: ColorRect
var _panel: Panel
var _vbox: VBoxContainer

# Resolution screen labels.
var _lbl_title: Label
var _lbl_player_col: Label
var _lbl_vs: Label
var _lbl_opp_col: Label
var _lbl_rerolls: Label
var _lbl_outcome: Label
var _btn_continue: Button

# Penalty screen nodes (hidden initially).
var _penalty_panel: Panel
var _lbl_pen_title: Label
var _lbl_pen_exercise: Label
var _lbl_pen_reps: Label
var _lbl_pen_weight: Label
var _lbl_pen_speed: Label
var _lbl_pen_media: Label
var _lbl_pen_timer: Label
var _btn_pen_done: Button


func _ready() -> void:
	layer = 15
	visible = false

	_overlay = UIHelpers.create_dim_overlay(0.6)
	add_child(_overlay)

	_build_resolution_panel()
	_build_penalty_panel()


func _build_resolution_panel() -> void:
	_panel = Panel.new()
	_panel.name = "ClashPanel"
	_panel.custom_minimum_size = Vector2(620, 460)
	_panel.set_anchors_preset(Control.PRESET_CENTER)
	_panel.offset_left = -310
	_panel.offset_top = -230
	_panel.offset_right = 310
	_panel.offset_bottom = 230
	add_child(_panel)

	_vbox = VBoxContainer.new()
	_vbox.name = "VBox"
	_vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	_vbox.add_theme_constant_override("separation", 10)
	_panel.add_child(_vbox)

	var title_container := UIHelpers.create_title("⚔  CLASH!  ⚔", 28)
	_vbox.add_child(title_container)
	_lbl_title = title_container.get_meta("label")

	# Side-by-side comparison row.
	var hbox := HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 40)
	_vbox.add_child(hbox)

	_lbl_player_col = Label.new()
	_lbl_player_col.name = "PlayerCol"
	_lbl_player_col.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lbl_player_col.add_theme_font_size_override("font_size", 16)
	hbox.add_child(_lbl_player_col)

	_lbl_vs = Label.new()
	_lbl_vs.text = "VS"
	_lbl_vs.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lbl_vs.add_theme_font_size_override("font_size", 20)
	if UITheme.font_title:
		_lbl_vs.add_theme_font_override("font", UITheme.font_title)
	hbox.add_child(_lbl_vs)

	_lbl_opp_col = Label.new()
	_lbl_opp_col.name = "OppCol"
	_lbl_opp_col.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lbl_opp_col.add_theme_font_size_override("font_size", 16)
	hbox.add_child(_lbl_opp_col)

	_lbl_rerolls = Label.new()
	_lbl_rerolls.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lbl_rerolls.add_theme_font_size_override("font_size", 13)
	_lbl_rerolls.add_theme_color_override("font_color", UITheme.REROLL_GRAY)
	_vbox.add_child(_lbl_rerolls)

	_lbl_outcome = Label.new()
	_lbl_outcome.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lbl_outcome.add_theme_font_size_override("font_size", 26)
	if UITheme.font_title:
		_lbl_outcome.add_theme_font_override("font", UITheme.font_title)
	_vbox.add_child(_lbl_outcome)

	_btn_continue = Button.new()
	_btn_continue.text = "Continue"
	_btn_continue.visible = false
	ButtonFX.apply(_btn_continue)
	_vbox.add_child(_btn_continue)
	_btn_continue.pressed.connect(_on_continue_pressed)


func _build_penalty_panel() -> void:
	_penalty_panel = Panel.new()
	_penalty_panel.name = "PenaltyPanel"
	_penalty_panel.custom_minimum_size = Vector2(620, 460)
	_penalty_panel.set_anchors_preset(Control.PRESET_CENTER)
	_penalty_panel.offset_left = -310
	_penalty_panel.offset_top = -230
	_penalty_panel.offset_right = 310
	_penalty_panel.offset_bottom = 230
	_penalty_panel.visible = false
	add_child(_penalty_panel)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 14)
	_penalty_panel.add_child(vbox)

	var pen_title_container := UIHelpers.create_title("PENALTY TASK", 26, UITheme.PENALTY_RED)
	vbox.add_child(pen_title_container)
	_lbl_pen_title = pen_title_container.get_meta("label")

	_lbl_pen_exercise = Label.new()
	_lbl_pen_exercise.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lbl_pen_exercise.add_theme_font_size_override("font_size", 22)
	vbox.add_child(_lbl_pen_exercise)

	_lbl_pen_reps = Label.new()
	_lbl_pen_reps.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lbl_pen_reps.add_theme_font_size_override("font_size", 18)
	vbox.add_child(_lbl_pen_reps)

	_lbl_pen_weight = Label.new()
	_lbl_pen_weight.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lbl_pen_weight.add_theme_font_size_override("font_size", 18)
	vbox.add_child(_lbl_pen_weight)

	_lbl_pen_speed = Label.new()
	_lbl_pen_speed.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lbl_pen_speed.add_theme_font_size_override("font_size", 18)
	vbox.add_child(_lbl_pen_speed)

	_lbl_pen_media = Label.new()
	_lbl_pen_media.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lbl_pen_media.add_theme_font_size_override("font_size", 14)
	_lbl_pen_media.add_theme_color_override("font_color", UITheme.INFO)
	_lbl_pen_media.visible = false
	vbox.add_child(_lbl_pen_media)

	_lbl_pen_timer = Label.new()
	_lbl_pen_timer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lbl_pen_timer.add_theme_font_size_override("font_size", 22)
	if UITheme.font_title:
		_lbl_pen_timer.add_theme_font_override("font", UITheme.font_title)
	vbox.add_child(_lbl_pen_timer)

	_btn_pen_done = Button.new()
	_btn_pen_done.text = "Done"
	_btn_pen_done.disabled = true
	ButtonFX.apply(_btn_pen_done)
	vbox.add_child(_btn_pen_done)
	_btn_pen_done.pressed.connect(_on_penalty_done_pressed)


## Displays the clash resolution screen with dice results.
func show_clash_result(data: Dictionary) -> void:
	_player_won = data.get("player_won", false)
	_phase = _PHASE_RESOLUTION
	_awaiting_transition = false

	_lbl_player_col.text = "YOU\nDice: %d\nSize: +%d\nTotal: %d" % [
		data.get("player_roll", 0),
		data.get("player_size", 0),
		data.get("player_total", 0),
	]
	_lbl_opp_col.text = "OPPONENT\nDice: %d\nSize: +%d\nTotal: %d" % [
		data.get("opp_roll", 0),
		data.get("opp_size", 0),
		data.get("opp_total", 0),
	]

	var rerolls: int = data.get("rerolls", 0)
	_lbl_rerolls.text = "(Tied — re-rolled %d time%s)" % [rerolls, "s" if rerolls != 1 else ""] \
		if rerolls > 0 else ""

	if _player_won:
		_lbl_outcome.text = "★  YOU WIN!  ★"
		_lbl_outcome.add_theme_color_override("font_color", UITheme.SUCCESS)
		_btn_continue.visible = true
	else:
		_lbl_outcome.text = "✗  YOU LOSE  ✗"
		_lbl_outcome.add_theme_color_override("font_color", UITheme.ERROR)
		_btn_continue.visible = false
		# Prepare penalty data for later.
		_penalty_timer = data.get("duration", 25.0)
		_lbl_pen_exercise.text = str(data.get("exercise", "Bicep Curls"))
		_lbl_pen_reps.text = "%d reps" % data.get("reps", 10)
		_lbl_pen_weight.text = "Weight: %s" % data.get("weight", "2kg")
		_lbl_pen_speed.text = "Do them %s" % data.get("speed", "normal speed")
		var media_path: String = str(data.get("media_path", ""))
		if media_path != "":
			_lbl_pen_media.text = "[Media: %s]" % media_path
			_lbl_pen_media.visible = true
		else:
			_lbl_pen_media.visible = false
		_lbl_pen_timer.text = "%.0f" % _penalty_timer
		_btn_pen_done.disabled = true
		_awaiting_transition = true
		_transition_timer = _TRANSITION_DELAY

	_panel.visible = true
	_penalty_panel.visible = false
	visible = true

	# Animate in
	_overlay.modulate.a = 0.0
	_panel.modulate.a = 0.0
	_panel.scale = Vector2(0.9, 0.9)
	_panel.pivot_offset = _panel.size / 2.0
	var tw := create_tween().set_parallel(true)
	tw.tween_property(_overlay, "modulate:a", 1.0, 0.2)
	tw.tween_property(_panel, "modulate:a", 1.0, 0.2)
	tw.tween_property(_panel, "scale", Vector2.ONE, 0.25).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)


func _process(delta: float) -> void:
	if not visible:
		return

	# Auto-transition from resolution to penalty screen.
	if _awaiting_transition:
		_transition_timer -= delta
		if _transition_timer <= 0.0:
			_awaiting_transition = false
			_switch_to_penalty()
		return

	# Penalty countdown.
	if _penalty_active:
		_penalty_timer = maxf(0.0, _penalty_timer - delta)
		_lbl_pen_timer.text = "%.1f" % _penalty_timer
		if _penalty_timer <= 0.0:
			_btn_pen_done.disabled = false


func _switch_to_penalty() -> void:
	_phase = _PHASE_PENALTY

	# Crossfade panels
	_penalty_panel.visible = true
	_penalty_panel.modulate.a = 0.0
	_penalty_panel.scale = Vector2(0.9, 0.9)
	_penalty_panel.pivot_offset = _penalty_panel.size / 2.0

	var tw := create_tween().set_parallel(true)
	tw.tween_property(_panel, "modulate:a", 0.0, 0.2)
	tw.tween_property(_penalty_panel, "modulate:a", 1.0, 0.25).set_delay(0.1)
	tw.tween_property(_penalty_panel, "scale", Vector2.ONE, 0.3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK).set_delay(0.1)
	await tw.finished

	_panel.visible = false
	_penalty_active = true


func _on_continue_pressed() -> void:
	visible = false
	_btn_continue.visible = false
	clash_resolved.emit()


func _on_penalty_done_pressed() -> void:
	_penalty_active = false
	visible = false
	_penalty_panel.visible = false
	penalty_completed.emit()
