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
var _lbl_pen_timer: Label
var _btn_pen_done: Button


func _ready() -> void:
	layer = 15
	visible = false

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

	_lbl_title = Label.new()
	_lbl_title.text = "⚔  CLASH!  ⚔"
	_lbl_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lbl_title.add_theme_font_size_override("font_size", 28)
	_vbox.add_child(_lbl_title)

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
	hbox.add_child(_lbl_vs)

	_lbl_opp_col = Label.new()
	_lbl_opp_col.name = "OppCol"
	_lbl_opp_col.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lbl_opp_col.add_theme_font_size_override("font_size", 16)
	hbox.add_child(_lbl_opp_col)

	_lbl_rerolls = Label.new()
	_lbl_rerolls.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lbl_rerolls.add_theme_font_size_override("font_size", 13)
	_lbl_rerolls.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	_vbox.add_child(_lbl_rerolls)

	_lbl_outcome = Label.new()
	_lbl_outcome.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lbl_outcome.add_theme_font_size_override("font_size", 26)
	_vbox.add_child(_lbl_outcome)

	_btn_continue = Button.new()
	_btn_continue.text = "Continue"
	_btn_continue.visible = false
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

	_lbl_pen_title = Label.new()
	_lbl_pen_title.text = "PENALTY TASK"
	_lbl_pen_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lbl_pen_title.add_theme_font_size_override("font_size", 26)
	_lbl_pen_title.add_theme_color_override("font_color", Color(1.0, 0.3, 0.2))
	vbox.add_child(_lbl_pen_title)

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

	_lbl_pen_timer = Label.new()
	_lbl_pen_timer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lbl_pen_timer.add_theme_font_size_override("font_size", 22)
	vbox.add_child(_lbl_pen_timer)

	_btn_pen_done = Button.new()
	_btn_pen_done.text = "Done"
	_btn_pen_done.disabled = true
	vbox.add_child(_btn_pen_done)
	_btn_pen_done.pressed.connect(_on_penalty_done_pressed)


## Displays the clash resolution screen with dice results.
## data keys: player_won, player_roll, player_size, player_total,
##            opp_roll, opp_size, opp_total, rerolls,
##            weight, speed, duration, exercise, reps
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
		_lbl_outcome.add_theme_color_override("font_color", Color(0.2, 1.0, 0.3))
		_btn_continue.visible = true
	else:
		_lbl_outcome.text = "✗  YOU LOSE  ✗"
		_lbl_outcome.add_theme_color_override("font_color", Color(1.0, 0.2, 0.2))
		_btn_continue.visible = false
		# Prepare penalty data for later.
		_penalty_timer = data.get("duration", 25.0)
		_lbl_pen_exercise.text = str(data.get("exercise", "Bicep Curls"))
		_lbl_pen_reps.text = "%d reps" % data.get("reps", 10)
		_lbl_pen_weight.text = "Weight: %s" % data.get("weight", "2kg")
		_lbl_pen_speed.text = "Do them %s" % data.get("speed", "normal speed")
		_lbl_pen_timer.text = "%.0f" % _penalty_timer
		_btn_pen_done.disabled = true
		_awaiting_transition = true
		_transition_timer = _TRANSITION_DELAY

	_panel.visible = true
	_penalty_panel.visible = false
	visible = true


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
	_panel.visible = false
	_penalty_panel.visible = true
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
