extends Control

var _content_manager: CustomContentManager
var _tab_container: TabContainer
var _error_label: Label

# Display settings widgets
var _resolution_option: OptionButton
var _fullscreen_check: CheckButton
var _master_slider: HSlider
var _music_slider: HSlider
var _sfx_slider: HSlider

# Custom content list containers
var _task_list: VBoxContainer
var _item_list: VBoxContainer
var _penalty_list: VBoxContainer


func _ready() -> void:
	_content_manager = CustomContentManager.new()
	_build_ui()
	_refresh_all()


func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = UITheme.BG_DARK
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	var panel := Panel.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left = -380
	panel.offset_top = -300
	panel.offset_right = 380
	panel.offset_bottom = 300
	add_child(panel)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	margin.add_child(vbox)

	var title_container := UIHelpers.create_title("SETTINGS", 26)
	vbox.add_child(title_container)

	_tab_container = TabContainer.new()
	_tab_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(_tab_container)

	# Tab 1: Display
	_build_display_tab()
	# Tab 2: Custom Tasks
	_build_tasks_tab()
	# Tab 3: Custom Items
	_build_items_tab()
	# Tab 4: Custom Penalties
	_build_penalties_tab()

	# Error label
	_error_label = Label.new()
	_error_label.add_theme_color_override("font_color", UITheme.ERROR)
	_error_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_error_label.visible = false
	vbox.add_child(_error_label)

	# Bottom buttons
	var btn_row := HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row.add_theme_constant_override("separation", 16)
	vbox.add_child(btn_row)

	var btn_back := Button.new()
	btn_back.text = "Back"
	btn_back.custom_minimum_size = Vector2(110, 0)
	btn_back.pressed.connect(_on_back)
	ButtonFX.apply(btn_back)
	btn_row.add_child(btn_back)


# ========================
# DISPLAY TAB
# ========================

func _build_display_tab() -> void:
	var scroll := ScrollContainer.new()
	scroll.name = "Display"
	_tab_container.add_child(scroll)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	vbox.custom_minimum_size = Vector2(700, 0)
	scroll.add_child(vbox)

	# Resolution
	vbox.add_child(_section_label("Resolution:"))
	_resolution_option = OptionButton.new()
	for lbl in SettingsManager.RESOLUTION_LABELS:
		_resolution_option.add_item(lbl)
	_resolution_option.selected = SettingsManager.get_setting("resolution")
	_resolution_option.item_selected.connect(_on_resolution_changed)
	vbox.add_child(_resolution_option)

	# Fullscreen
	_fullscreen_check = CheckButton.new()
	_fullscreen_check.text = "Fullscreen"
	_fullscreen_check.button_pressed = SettingsManager.get_setting("fullscreen")
	_fullscreen_check.toggled.connect(_on_fullscreen_toggled)
	vbox.add_child(_fullscreen_check)

	vbox.add_child(HSeparator.new())

	# Sound (placeholders)
	vbox.add_child(_section_label("Sound (coming soon):"))

	var master_row := _slider_row("Master Volume:", SettingsManager.get_setting("master_volume"))
	_master_slider = master_row[1]
	_master_slider.value_changed.connect(_on_master_changed)
	vbox.add_child(master_row[0])

	var music_row := _slider_row("Music Volume:", SettingsManager.get_setting("music_volume"))
	_music_slider = music_row[1]
	_music_slider.value_changed.connect(_on_music_changed)
	vbox.add_child(music_row[0])

	var sfx_row := _slider_row("SFX Volume:", SettingsManager.get_setting("sfx_volume"))
	_sfx_slider = sfx_row[1]
	_sfx_slider.value_changed.connect(_on_sfx_changed)
	vbox.add_child(sfx_row[0])

	vbox.add_child(HSeparator.new())

	var btn_reset := Button.new()
	btn_reset.text = "Reset to Defaults"
	btn_reset.pressed.connect(_on_reset_defaults)
	vbox.add_child(btn_reset)


# ========================
# CUSTOM TASKS TAB
# ========================

func _build_tasks_tab() -> void:
	var scroll := ScrollContainer.new()
	scroll.name = "Custom Tasks"
	_tab_container.add_child(scroll)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	vbox.custom_minimum_size = Vector2(700, 0)
	scroll.add_child(vbox)

	var btn_add := Button.new()
	btn_add.text = "+ Add Task"
	btn_add.pressed.connect(_on_add_task)
	vbox.add_child(btn_add)

	_task_list = VBoxContainer.new()
	_task_list.add_theme_constant_override("separation", 4)
	vbox.add_child(_task_list)


# ========================
# CUSTOM ITEMS TAB
# ========================

func _build_items_tab() -> void:
	var scroll := ScrollContainer.new()
	scroll.name = "Custom Items"
	_tab_container.add_child(scroll)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	vbox.custom_minimum_size = Vector2(700, 0)
	scroll.add_child(vbox)

	var btn_add := Button.new()
	btn_add.text = "+ Add Item"
	btn_add.pressed.connect(_on_add_item)
	vbox.add_child(btn_add)

	_item_list = VBoxContainer.new()
	_item_list.add_theme_constant_override("separation", 4)
	vbox.add_child(_item_list)


# ========================
# CUSTOM PENALTIES TAB
# ========================

func _build_penalties_tab() -> void:
	var scroll := ScrollContainer.new()
	scroll.name = "Clash Penalties"
	_tab_container.add_child(scroll)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	vbox.custom_minimum_size = Vector2(700, 0)
	scroll.add_child(vbox)

	var btn_add := Button.new()
	btn_add.text = "+ Add Penalty"
	btn_add.pressed.connect(_on_add_penalty)
	vbox.add_child(btn_add)

	_penalty_list = VBoxContainer.new()
	_penalty_list.add_theme_constant_override("separation", 4)
	vbox.add_child(_penalty_list)


# ========================
# REFRESH LISTS
# ========================

func _refresh_all() -> void:
	_refresh_task_list()
	_refresh_item_list()
	_refresh_penalty_list()


func _refresh_task_list() -> void:
	_clear_children(_task_list)
	var tasks := _content_manager.get_custom_tasks()
	if tasks.is_empty():
		_task_list.add_child(_info_label("No custom tasks. Default tasks are always available."))
		return
	for task in tasks:
		var row := _content_row(
			"%s (%.0fs)" % [task.get("title", "?"), task.get("duration_seconds", 0)],
			task.get("id", ""),
			_on_edit_task,
			_on_delete_task
		)
		_task_list.add_child(row)


func _refresh_item_list() -> void:
	_clear_children(_item_list)
	var items := _content_manager.get_custom_items()
	if items.is_empty():
		_item_list.add_child(_info_label("No custom items. Default items are always available."))
		return
	for item in items:
		var row := _content_row(
			item.get("name", "?"),
			item.get("id", ""),
			_on_edit_item,
			_on_delete_item
		)
		_item_list.add_child(row)


func _refresh_penalty_list() -> void:
	_clear_children(_penalty_list)
	var penalties := _content_manager.get_custom_penalties()
	if penalties.is_empty():
		_penalty_list.add_child(_info_label("No custom penalties. Default penalty (Bicep Curls x10) always available."))
		return
	for penalty in penalties:
		var row := _content_row(
			"%s x%d" % [penalty.get("exercise", "?"), penalty.get("reps", 0)],
			penalty.get("id", ""),
			_on_edit_penalty,
			_on_delete_penalty
		)
		_penalty_list.add_child(row)


# ========================
# DISPLAY EVENT HANDLERS
# ========================

func _on_resolution_changed(idx: int) -> void:
	SettingsManager.set_setting("resolution", idx)
	SettingsManager.apply_settings()
	SettingsManager.save_settings()


func _on_fullscreen_toggled(pressed: bool) -> void:
	SettingsManager.set_setting("fullscreen", pressed)
	SettingsManager.apply_settings()
	SettingsManager.save_settings()


func _on_master_changed(value: float) -> void:
	SettingsManager.set_setting("master_volume", int(value))
	SettingsManager.save_settings()


func _on_music_changed(value: float) -> void:
	SettingsManager.set_setting("music_volume", int(value))
	SettingsManager.save_settings()


func _on_sfx_changed(value: float) -> void:
	SettingsManager.set_setting("sfx_volume", int(value))
	SettingsManager.save_settings()


func _on_reset_defaults() -> void:
	SettingsManager.reset_to_defaults()
	_resolution_option.selected = SettingsManager.get_setting("resolution")
	_fullscreen_check.button_pressed = SettingsManager.get_setting("fullscreen")
	_master_slider.value = SettingsManager.get_setting("master_volume")
	_music_slider.value = SettingsManager.get_setting("music_volume")
	_sfx_slider.value = SettingsManager.get_setting("sfx_volume")


# ========================
# CUSTOM TASK HANDLERS
# ========================

func _on_add_task() -> void:
	_show_task_editor("", "", "", 30.0, "")


func _on_edit_task(id: String) -> void:
	var tasks := _content_manager.get_custom_tasks()
	for task in tasks:
		if task.get("id", "") == id:
			_show_task_editor(id, task.get("title", ""), task.get("description", ""),
				task.get("duration_seconds", 30.0), task.get("media_path", ""))
			return


func _on_delete_task(id: String) -> void:
	_content_manager.remove_custom_task(id)
	_refresh_task_list()


func _show_task_editor(id: String, title: String, desc: String, duration: float, media: String) -> void:
	var dialog := _create_editor_overlay()
	var vbox: VBoxContainer = dialog.get_meta("vbox")

	var header := Label.new()
	header.text = "Edit Task" if id != "" else "Add Task"
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.add_theme_font_size_override("font_size", 20)
	vbox.add_child(header)

	var title_input := LineEdit.new()
	title_input.placeholder_text = "Title"
	title_input.text = title
	title_input.max_length = CustomContentManager.MAX_TITLE_LENGTH
	vbox.add_child(title_input)

	var desc_input := LineEdit.new()
	desc_input.placeholder_text = "Description"
	desc_input.text = desc
	desc_input.max_length = CustomContentManager.MAX_DESCRIPTION_LENGTH
	vbox.add_child(desc_input)

	var dur_row := HBoxContainer.new()
	dur_row.add_theme_constant_override("separation", 8)
	var dur_lbl := Label.new()
	dur_lbl.text = "Duration (s):"
	dur_row.add_child(dur_lbl)
	var dur_input := SpinBox.new()
	dur_input.min_value = CustomContentManager.MIN_DURATION
	dur_input.max_value = CustomContentManager.MAX_DURATION
	dur_input.step = 1.0
	dur_input.value = duration
	dur_row.add_child(dur_input)
	vbox.add_child(dur_row)

	var media_input := LineEdit.new()
	media_input.placeholder_text = "Media path (gif/mp4/webm) — optional"
	media_input.text = media
	vbox.add_child(media_input)

	var err_lbl := Label.new()
	err_lbl.add_theme_color_override("font_color", UITheme.ERROR)
	err_lbl.visible = false
	vbox.add_child(err_lbl)

	var btn_row := HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row.add_theme_constant_override("separation", 12)
	vbox.add_child(btn_row)

	var btn_save := Button.new()
	btn_save.text = "Save"
	btn_save.pressed.connect(func():
		var result: String
		if id != "":
			result = _content_manager.update_custom_task(id, title_input.text, desc_input.text, dur_input.value, media_input.text)
		else:
			result = _content_manager.add_custom_task(title_input.text, desc_input.text, dur_input.value, media_input.text)
		if result != "":
			err_lbl.text = result
			err_lbl.visible = true
		else:
			dialog.queue_free()
			_refresh_task_list()
	)
	btn_row.add_child(btn_save)

	var btn_cancel := Button.new()
	btn_cancel.text = "Cancel"
	btn_cancel.pressed.connect(func(): dialog.queue_free())
	btn_row.add_child(btn_cancel)


# ========================
# CUSTOM ITEM HANDLERS
# ========================

func _on_add_item() -> void:
	_show_item_editor("", "", "")


func _on_edit_item(id: String) -> void:
	var items := _content_manager.get_custom_items()
	for item in items:
		if item.get("id", "") == id:
			_show_item_editor(id, item.get("name", ""), item.get("icon_path", ""))
			return


func _on_delete_item(id: String) -> void:
	_content_manager.remove_custom_item(id)
	_refresh_item_list()


func _show_item_editor(id: String, item_name: String, icon: String) -> void:
	var dialog := _create_editor_overlay()
	var vbox: VBoxContainer = dialog.get_meta("vbox")

	var header := Label.new()
	header.text = "Edit Item" if id != "" else "Add Item"
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.add_theme_font_size_override("font_size", 20)
	vbox.add_child(header)

	var name_input := LineEdit.new()
	name_input.placeholder_text = "Item Name"
	name_input.text = item_name
	name_input.max_length = CustomContentManager.MAX_TITLE_LENGTH
	vbox.add_child(name_input)

	var icon_input := LineEdit.new()
	icon_input.placeholder_text = "Icon path (png/jpg) — optional"
	icon_input.text = icon
	vbox.add_child(icon_input)

	var err_lbl := Label.new()
	err_lbl.add_theme_color_override("font_color", UITheme.ERROR)
	err_lbl.visible = false
	vbox.add_child(err_lbl)

	var btn_row := HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row.add_theme_constant_override("separation", 12)
	vbox.add_child(btn_row)

	var btn_save := Button.new()
	btn_save.text = "Save"
	btn_save.pressed.connect(func():
		var result: String
		if id != "":
			result = _content_manager.update_custom_item(id, name_input.text, icon_input.text)
		else:
			result = _content_manager.add_custom_item(name_input.text, icon_input.text)
		if result != "":
			err_lbl.text = result
			err_lbl.visible = true
		else:
			dialog.queue_free()
			_refresh_item_list()
	)
	btn_row.add_child(btn_save)

	var btn_cancel := Button.new()
	btn_cancel.text = "Cancel"
	btn_cancel.pressed.connect(func(): dialog.queue_free())
	btn_row.add_child(btn_cancel)


# ========================
# CUSTOM PENALTY HANDLERS
# ========================

func _on_add_penalty() -> void:
	_show_penalty_editor("", "", 10)


func _on_edit_penalty(id: String) -> void:
	var penalties := _content_manager.get_custom_penalties()
	for penalty in penalties:
		if penalty.get("id", "") == id:
			_show_penalty_editor(id, penalty.get("exercise", ""), int(penalty.get("reps", 10)))
			return


func _on_delete_penalty(id: String) -> void:
	_content_manager.remove_custom_penalty(id)
	_refresh_penalty_list()


func _show_penalty_editor(id: String, exercise: String, reps: int) -> void:
	var dialog := _create_editor_overlay()
	var vbox: VBoxContainer = dialog.get_meta("vbox")

	var header := Label.new()
	header.text = "Edit Penalty" if id != "" else "Add Penalty"
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.add_theme_font_size_override("font_size", 20)
	vbox.add_child(header)

	var exercise_input := LineEdit.new()
	exercise_input.placeholder_text = "Exercise Name"
	exercise_input.text = exercise
	exercise_input.max_length = CustomContentManager.MAX_TITLE_LENGTH
	vbox.add_child(exercise_input)

	var reps_row := HBoxContainer.new()
	reps_row.add_theme_constant_override("separation", 8)
	var reps_lbl := Label.new()
	reps_lbl.text = "Reps:"
	reps_row.add_child(reps_lbl)
	var reps_input := SpinBox.new()
	reps_input.min_value = CustomContentManager.MIN_REPS
	reps_input.max_value = CustomContentManager.MAX_REPS
	reps_input.step = 1
	reps_input.value = reps
	reps_row.add_child(reps_input)
	vbox.add_child(reps_row)

	var err_lbl := Label.new()
	err_lbl.add_theme_color_override("font_color", UITheme.ERROR)
	err_lbl.visible = false
	vbox.add_child(err_lbl)

	var btn_row := HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row.add_theme_constant_override("separation", 12)
	vbox.add_child(btn_row)

	var btn_save := Button.new()
	btn_save.text = "Save"
	btn_save.pressed.connect(func():
		var result: String
		if id != "":
			result = _content_manager.update_custom_penalty(id, exercise_input.text, int(reps_input.value))
		else:
			result = _content_manager.add_custom_penalty(exercise_input.text, int(reps_input.value))
		if result != "":
			err_lbl.text = result
			err_lbl.visible = true
		else:
			dialog.queue_free()
			_refresh_penalty_list()
	)
	btn_row.add_child(btn_save)

	var btn_cancel := Button.new()
	btn_cancel.text = "Cancel"
	btn_cancel.pressed.connect(func(): dialog.queue_free())
	btn_row.add_child(btn_cancel)


# ========================
# NAV
# ========================

func _on_back() -> void:
	SceneManager.go_to_main_menu()


# ========================
# UI HELPERS
# ========================

func _section_label(text: String) -> Label:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 16)
	if UITheme.font_title:
		lbl.add_theme_font_override("font", UITheme.font_title)
	return lbl


func _info_label(text: String) -> Label:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_color_override("font_color", UITheme.TEXT_DIM)
	lbl.add_theme_font_size_override("font_size", 13)
	return lbl


func _slider_row(label_text: String, initial_value: int) -> Array:
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 10)
	var lbl := Label.new()
	lbl.text = label_text
	lbl.custom_minimum_size = Vector2(140, 0)
	hbox.add_child(lbl)
	var slider := HSlider.new()
	slider.min_value = 0
	slider.max_value = 100
	slider.step = 1
	slider.value = initial_value
	slider.custom_minimum_size = Vector2(200, 0)
	hbox.add_child(slider)
	var val_lbl := Label.new()
	val_lbl.text = str(initial_value)
	val_lbl.custom_minimum_size = Vector2(32, 0)
	slider.value_changed.connect(func(v: float): val_lbl.text = str(int(v)))
	hbox.add_child(val_lbl)
	return [hbox, slider]


func _content_row(text: String, id: String, edit_cb: Callable, delete_cb: Callable) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	var lbl := Label.new()
	lbl.text = text
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(lbl)
	var btn_edit := Button.new()
	btn_edit.text = "Edit"
	btn_edit.pressed.connect(edit_cb.bind(id))
	row.add_child(btn_edit)
	var btn_del := Button.new()
	btn_del.text = "Delete"
	btn_del.pressed.connect(delete_cb.bind(id))
	row.add_child(btn_del)
	return row


func _create_editor_overlay() -> ColorRect:
	var overlay := ColorRect.new()
	overlay.color = UITheme.OVERLAY_DIM
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(overlay)

	var panel := Panel.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left = -220
	panel.offset_top = -180
	panel.offset_right = 220
	panel.offset_bottom = 180
	overlay.add_child(panel)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	margin.add_child(vbox)

	overlay.set_meta("vbox", vbox)
	return overlay


func _clear_children(container: Node) -> void:
	while container.get_child_count() > 0:
		var child := container.get_child(0)
		container.remove_child(child)
		child.queue_free()
