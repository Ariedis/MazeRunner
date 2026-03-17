extends Control

const AVATAR_COLORS: Array = [
	Color(0.3, 0.5, 0.9),
	Color(0.9, 0.3, 0.3),
	Color(0.3, 0.8, 0.4),
	Color(0.7, 0.3, 0.9),
	Color(0.9, 0.6, 0.2),
]
const AVATAR_COUNT: int = 5

var _creator: CharacterCreatorLogic
var _item_registry: ItemRegistry

var _selected_map_size: int = Enums.MapSize.SMALL
var _selected_avatar: int = 0
var _num_opponents: int = 1
var _selected_item_id: String = ""

var _enable_powerups: bool = false
var _enable_traps: bool = false
var _enable_leaderboard: bool = false
var _enable_hazards: bool = false

var _map_size_buttons: Array = []
var _avatar_buttons: Array = []
var _label_size_value: Label
var _label_points: Label
var _label_opponents: Label
var _difficulty_container: VBoxContainer
var _difficulty_dropdowns: Array = []
var _item_option: OptionButton
var _label_error: Label
var _btn_start: Button


func _ready() -> void:
	_creator = CharacterCreatorLogic.new()
	_item_registry = ItemRegistry.new()
	_build_ui()
	_refresh_map_size_buttons()
	_refresh_avatar_buttons()
	_refresh_size_display()
	_refresh_opponents()


func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.08, 0.08, 0.12)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	var panel := Panel.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left = -340
	panel.offset_top = -340
	panel.offset_right = 340
	panel.offset_bottom = 340
	add_child(panel)

	var scroll := ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.add_child(scroll)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	scroll.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	vbox.custom_minimum_size = Vector2(620, 0)
	margin.add_child(vbox)

	# Title
	var title := Label.new()
	title.text = "NEW GAME"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 26)
	vbox.add_child(title)

	vbox.add_child(_hsep())

	# Map Size
	vbox.add_child(_section_label("Map Size:"))
	var map_hbox := HBoxContainer.new()
	map_hbox.add_theme_constant_override("separation", 8)
	for i in 3:
		var btn := Button.new()
		btn.text = ["Small", "Medium", "Large"][i]
		btn.custom_minimum_size = Vector2(100, 0)
		btn.pressed.connect(_on_map_size_selected.bind(i))
		map_hbox.add_child(btn)
		_map_size_buttons.append(btn)
	vbox.add_child(map_hbox)

	vbox.add_child(_hsep())

	# Character Creator
	vbox.add_child(_section_label("Character:"))
	var char_hbox := HBoxContainer.new()
	char_hbox.add_theme_constant_override("separation", 24)
	vbox.add_child(char_hbox)

	# Avatar selection
	var avatar_vbox := VBoxContainer.new()
	avatar_vbox.add_theme_constant_override("separation", 6)
	avatar_vbox.add_child(_small_label("Avatar:"))
	var avatar_hbox := HBoxContainer.new()
	avatar_hbox.add_theme_constant_override("separation", 6)
	for i in AVATAR_COUNT:
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(48, 48)
		btn.text = str(i + 1)
		_apply_avatar_style(btn, i, false)
		btn.pressed.connect(_on_avatar_selected.bind(i))
		avatar_hbox.add_child(btn)
		_avatar_buttons.append(btn)
	avatar_vbox.add_child(avatar_hbox)
	char_hbox.add_child(avatar_vbox)

	# Size allocation
	var size_vbox := VBoxContainer.new()
	size_vbox.add_theme_constant_override("separation", 6)
	size_vbox.add_child(_small_label("Starting Size:"))
	var size_hbox := HBoxContainer.new()
	size_hbox.add_theme_constant_override("separation", 8)
	var btn_minus := Button.new()
	btn_minus.text = " - "
	btn_minus.pressed.connect(_on_size_minus)
	_label_size_value = Label.new()
	_label_size_value.custom_minimum_size = Vector2(28, 0)
	_label_size_value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label_size_value.add_theme_font_size_override("font_size", 16)
	var btn_plus := Button.new()
	btn_plus.text = " + "
	btn_plus.pressed.connect(_on_size_plus)
	size_hbox.add_child(btn_minus)
	size_hbox.add_child(_label_size_value)
	size_hbox.add_child(btn_plus)
	size_vbox.add_child(size_hbox)
	_label_points = Label.new()
	_label_points.add_theme_font_size_override("font_size", 13)
	size_vbox.add_child(_label_points)
	char_hbox.add_child(size_vbox)

	vbox.add_child(_hsep())

	# Opponents
	vbox.add_child(_section_label("Opponents:"))
	var opp_hbox := HBoxContainer.new()
	opp_hbox.add_theme_constant_override("separation", 10)
	var btn_opp_minus := Button.new()
	btn_opp_minus.text = " - "
	btn_opp_minus.pressed.connect(_on_opp_minus)
	_label_opponents = Label.new()
	_label_opponents.custom_minimum_size = Vector2(28, 0)
	_label_opponents.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label_opponents.add_theme_font_size_override("font_size", 16)
	var btn_opp_plus := Button.new()
	btn_opp_plus.text = " + "
	btn_opp_plus.pressed.connect(_on_opp_plus)
	opp_hbox.add_child(btn_opp_minus)
	opp_hbox.add_child(_label_opponents)
	opp_hbox.add_child(btn_opp_plus)
	vbox.add_child(opp_hbox)

	# AI Difficulty (populated dynamically)
	_difficulty_container = VBoxContainer.new()
	_difficulty_container.add_theme_constant_override("separation", 6)
	vbox.add_child(_difficulty_container)

	vbox.add_child(_hsep())

	# Item Selector
	vbox.add_child(_section_label("Your Item:"))
	_item_option = OptionButton.new()
	_item_option.custom_minimum_size = Vector2(220, 0)
	_item_option.add_item("-- Select Item --")
	for item in _item_registry.get_all():
		_item_option.add_item(item.name)
	_item_option.selected = 0
	_item_option.item_selected.connect(_on_item_selected)
	vbox.add_child(_item_option)

	vbox.add_child(_hsep())

	# Game Options
	vbox.add_child(_section_label("Game Options:"))
	var options_grid := GridContainer.new()
	options_grid.columns = 2
	options_grid.add_theme_constant_override("h_separation", 24)
	options_grid.add_theme_constant_override("v_separation", 6)

	var chk_powerups := CheckBox.new()
	chk_powerups.text = "Power-ups"
	chk_powerups.toggled.connect(func(on: bool) -> void: _enable_powerups = on)
	options_grid.add_child(chk_powerups)

	var chk_traps := CheckBox.new()
	chk_traps.text = "Traps"
	chk_traps.toggled.connect(func(on: bool) -> void: _enable_traps = on)
	options_grid.add_child(chk_traps)

	var chk_leaderboard := CheckBox.new()
	chk_leaderboard.text = "Leaderboard"
	chk_leaderboard.toggled.connect(func(on: bool) -> void: _enable_leaderboard = on)
	options_grid.add_child(chk_leaderboard)

	var chk_hazards := CheckBox.new()
	chk_hazards.text = "Maze Hazards"
	chk_hazards.toggled.connect(func(on: bool) -> void: _enable_hazards = on)
	options_grid.add_child(chk_hazards)

	vbox.add_child(options_grid)

	vbox.add_child(_hsep())

	# Error label
	_label_error = Label.new()
	_label_error.add_theme_color_override("font_color", Color(1.0, 0.3, 0.2))
	_label_error.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label_error.visible = false
	vbox.add_child(_label_error)

	# Action buttons
	var btn_row := HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row.add_theme_constant_override("separation", 16)
	var btn_back := Button.new()
	btn_back.text = "Back"
	btn_back.custom_minimum_size = Vector2(110, 0)
	btn_back.pressed.connect(SceneManager.go_to_main_menu)
	_btn_start = Button.new()
	_btn_start.text = "Start Game"
	_btn_start.custom_minimum_size = Vector2(130, 0)
	_btn_start.pressed.connect(_on_start_game)
	btn_row.add_child(btn_back)
	btn_row.add_child(_btn_start)
	vbox.add_child(btn_row)


# --- Event Handlers ---

func _on_map_size_selected(size: int) -> void:
	_selected_map_size = size
	var max_opp := NewGameConfig.get_max_opponents(size)
	if _num_opponents > max_opp:
		_num_opponents = max_opp
	_refresh_map_size_buttons()
	_refresh_opponents()


func _on_avatar_selected(idx: int) -> void:
	_selected_avatar = idx
	_refresh_avatar_buttons()


func _on_size_plus() -> void:
	_creator.increase_size()
	_refresh_size_display()


func _on_size_minus() -> void:
	_creator.decrease_size()
	_refresh_size_display()


func _on_opp_plus() -> void:
	var max_opp := NewGameConfig.get_max_opponents(_selected_map_size)
	if _num_opponents < max_opp:
		_num_opponents += 1
	_refresh_opponents()


func _on_opp_minus() -> void:
	if _num_opponents > 1:
		_num_opponents -= 1
	_refresh_opponents()


func _on_item_selected(idx: int) -> void:
	if idx == 0:
		_selected_item_id = ""
	else:
		var items := _item_registry.get_all()
		var item_idx := idx - 1
		if item_idx < items.size():
			_selected_item_id = items[item_idx].id


func _on_start_game() -> void:
	var diffs := _get_current_difficulties()
	var config := {
		"map_size": _selected_map_size,
		"num_opponents": _num_opponents,
		"ai_difficulties": diffs,
		"item_id": _selected_item_id,
		"seed": 0,
		"avatar_id": _selected_avatar,
		"enable_powerups": _enable_powerups,
		"enable_traps": _enable_traps,
		"enable_leaderboard": _enable_leaderboard,
		"enable_hazards": _enable_hazards,
	}
	if not NewGameConfig.validate(config):
		_label_error.text = "Please select an item before starting."
		_label_error.visible = true
		return
	_label_error.visible = false
	GameState.reset_for_new_game()
	GameState.config = config
	GameState.player["avatar_id"] = _selected_avatar
	GameState.player["size"] = _creator.size
	SceneManager.go_to_game_scene()


func _get_current_difficulties() -> Array:
	var diffs := []
	for dropdown in _difficulty_dropdowns:
		var opt: OptionButton = dropdown
		diffs.append(opt.selected)
	return diffs


# --- Refresh Helpers ---

func _refresh_map_size_buttons() -> void:
	for i in _map_size_buttons.size():
		var btn: Button = _map_size_buttons[i]
		btn.flat = (i != _selected_map_size)


func _refresh_avatar_buttons() -> void:
	for i in _avatar_buttons.size():
		_apply_avatar_style(_avatar_buttons[i], i, i == _selected_avatar)


func _apply_avatar_style(btn: Button, avatar_idx: int, selected: bool) -> void:
	var color: Color = AVATAR_COLORS[avatar_idx]
	var style := StyleBoxFlat.new()
	style.bg_color = color
	if selected:
		style.border_width_top = 3
		style.border_width_bottom = 3
		style.border_width_left = 3
		style.border_width_right = 3
		style.border_color = Color.WHITE
	else:
		style.bg_color = color.darkened(0.3)
	btn.add_theme_stylebox_override("normal", style)
	var hover := style.duplicate() as StyleBoxFlat
	hover.bg_color = color.lightened(0.1)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", hover)


func _refresh_size_display() -> void:
	_label_size_value.text = str(_creator.size)
	_label_points.text = "Points remaining: %d" % _creator.points_remaining


func _refresh_opponents() -> void:
	_label_opponents.text = str(_num_opponents)
	_rebuild_difficulty_dropdowns()


func _rebuild_difficulty_dropdowns() -> void:
	while _difficulty_container.get_child_count() > 0:
		var child := _difficulty_container.get_child(0)
		_difficulty_container.remove_child(child)
		child.queue_free()
	_difficulty_dropdowns.clear()

	var header := Label.new()
	header.text = "AI Difficulty:"
	header.add_theme_font_size_override("font_size", 14)
	_difficulty_container.add_child(header)

	for i in _num_opponents:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		var lbl := Label.new()
		lbl.text = "Opponent %d:" % (i + 1)
		lbl.custom_minimum_size = Vector2(110, 0)
		var dropdown := OptionButton.new()
		dropdown.add_item("Easy", Enums.Difficulty.EASY)
		dropdown.add_item("Medium", Enums.Difficulty.MEDIUM)
		dropdown.add_item("Hard", Enums.Difficulty.HARD)
		dropdown.selected = 0
		row.add_child(lbl)
		row.add_child(dropdown)
		_difficulty_container.add_child(row)
		_difficulty_dropdowns.append(dropdown)


func _hsep() -> HSeparator:
	return HSeparator.new()


func _section_label(text: String) -> Label:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 16)
	return lbl


func _small_label(text: String) -> Label:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 13)
	return lbl
