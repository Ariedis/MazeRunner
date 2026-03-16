extends Node2D

var _maze_data: MazeData
var _renderer: MazeRenderer
var _player: Player
var _fog: FogOfWar
var _fog_renderer: FogRenderer
var _last_grid_cell := Vector2i(-1, -1)
var _location_manager: LocationManager
var _location_markers: Dictionary = {}
var _task_overlay: TaskOverlay
var _win_condition: WinConditionManager
var _results_screen: ResultsScreen
var _start_time_msec: int = 0
var _match_over: bool = false
var _label_rejection: Label


func _ready() -> void:
	var map_size = GameState.config.get("map_size", Enums.MapSize.SMALL)
	var seed_cfg: int = GameState.config.get("seed", 0)
	var seed_val = seed_cfg if seed_cfg != 0 else -1

	var gen = MazeGenerator.new()
	_maze_data = gen.generate(map_size, seed_val)

	var size_data = Enums.MAP_SIZE_DATA[map_size]
	_renderer = MazeRenderer.new()
	_renderer.name = "MazeRenderer"
	add_child(_renderer)
	_renderer.render(_maze_data, size_data["cell_px"])

	var player_scene: PackedScene = load("res://scenes/player/Player.tscn")
	_player = player_scene.instantiate()
	_player.name = "Player"
	add_child(_player)

	var tile_size: int = size_data["cell_px"] / 2
	_player.setup(tile_size)
	_player.position = _renderer.get_world_position(_maze_data.player_spawn)

	_fog = FogOfWar.new()
	_fog_renderer = FogRenderer.new()
	_fog_renderer.name = "FogRenderer"
	_fog_renderer.initialize(_maze_data.width, _maze_data.height, tile_size)

	# Set up task system
	var task_loader := TaskLoader.new()
	var tasks := task_loader.load_all_tasks()
	var loc_rng := RandomNumberGenerator.new()
	loc_rng.seed = _maze_data.seed_val + 1

	_location_manager = LocationManager.new()
	_location_manager.setup(_maze_data, tasks, loc_rng)

	# Spawn location markers and exit marker (above maze, below fog)
	_spawn_location_markers(tile_size)
	_spawn_exit_marker(tile_size)

	add_child(_fog_renderer)

	# Task overlay (CanvasLayer — renders above everything)
	_task_overlay = TaskOverlay.new()
	_task_overlay.name = "TaskOverlay"
	add_child(_task_overlay)
	_task_overlay.task_completed.connect(_on_task_completed)

	# Results screen
	_results_screen = ResultsScreen.new()
	_results_screen.name = "ResultsScreen"
	add_child(_results_screen)
	_results_screen.play_again_requested.connect(_on_play_again)
	_results_screen.main_menu_requested.connect(SceneManager.go_to_main_menu)

	# Win condition manager
	_win_condition = WinConditionManager.new()
	SignalBus.match_ended.connect(_on_match_ended)

	var cam := Camera2D.new()
	cam.name = "Camera2D"
	cam.enabled = true
	_player.add_child(cam)

	$UI/LabelSeed.text = "Seed: %d" % _maze_data.seed_val
	$UI/LabelSize.text = "Size: %s" % ["SMALL", "MEDIUM", "LARGE"][map_size]
	$UI/LabelEnergy.text = "Energy: 100%%"
	$UI/BtnMainMenu.pressed.connect(SceneManager.go_to_main_menu)

	# Rejection message label (created in code — not in scene)
	_label_rejection = Label.new()
	_label_rejection.name = "LabelRejection"
	_label_rejection.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label_rejection.add_theme_color_override("font_color", Color(1.0, 0.3, 0.2))
	_label_rejection.add_theme_font_size_override("font_size", 20)
	_label_rejection.visible = false
	$UI.add_child(_label_rejection)
	_label_rejection.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_label_rejection.offset_top = 60
	_label_rejection.offset_bottom = 100

	SignalBus.player_energy_changed.connect(_on_player_energy_changed)
	SignalBus.player_item_collected.connect(_on_player_item_collected)
	GameState.current_state = Enums.GameState.IN_GAME

	_start_time_msec = Time.get_ticks_msec()


func _process(_delta: float) -> void:
	if _match_over:
		return
	if GameState.match_state.get("is_paused", false):
		return

	var cell := _renderer.world_to_grid(_player.global_position)
	if cell == _last_grid_cell:
		return
	_last_grid_cell = cell
	var revealed := _fog.reveal(cell, _maze_data.width, _maze_data.height)
	if revealed.size() > 0:
		_fog_renderer.reveal_cells(revealed)
		GameState.player["explored_cells"] = _fog.get_explored_array()

	# Exit check
	if cell == _maze_data.exit:
		_handle_exit_interaction()
		return

	# Location trigger
	if _location_manager.has_uncompleted_at(cell) and not _task_overlay.visible:
		var loc := _location_manager.get_location_at(cell)
		GameState.match_state["is_paused"] = true
		_task_overlay.show_task(loc.task, loc.id, loc.item_type)


func _spawn_location_markers(tile_size: int) -> void:
	var layer := Node2D.new()
	layer.name = "LocationLayer"
	add_child(layer)
	for loc in _location_manager.locations:
		var marker := _make_marker(tile_size)
		marker.position = _renderer.get_world_position(loc.grid_pos)
		layer.add_child(marker)
		_location_markers[loc.id] = marker


func _make_marker(tile_size: int) -> Node2D:
	var n := Node2D.new()
	var poly := Polygon2D.new()
	var r := tile_size * 0.35
	var pts: PackedVector2Array
	for i in 8:
		var a := i * TAU / 8
		pts.append(Vector2(cos(a), sin(a)) * r)
	poly.polygon = pts
	poly.color = Color(1.0, 0.9, 0.0)
	n.add_child(poly)
	return n


func _spawn_exit_marker(tile_size: int) -> void:
	var layer := Node2D.new()
	layer.name = "ExitLayer"
	add_child(layer)

	var marker := Node2D.new()
	var poly := Polygon2D.new()
	var r := tile_size * 0.45
	var pts: PackedVector2Array
	# Star shape (8-pointed)
	for i in 8:
		var a := i * TAU / 8
		var inner_r := r * 0.5 if i % 2 == 1 else r
		pts.append(Vector2(cos(a), sin(a)) * inner_r)
	poly.polygon = pts
	poly.color = Color(0.4, 0.9, 1.0)
	marker.add_child(poly)
	marker.position = _renderer.get_world_position(_maze_data.exit)
	layer.add_child(marker)


func _handle_exit_interaction() -> void:
	var has_item: bool = GameState.player.get("has_item", false)
	var result := _win_condition.check_player_at_exit(has_item)
	if result == WinConditionManager.Result.PLAYER_WIN:
		# match_ended signal already emitted by WinConditionManager
		pass
	else:
		_show_rejection_message("You need your item to exit!")


func _show_rejection_message(msg: String) -> void:
	_label_rejection.text = msg
	_label_rejection.visible = true
	var timer := get_tree().create_timer(2.5)
	timer.timeout.connect(func(): _label_rejection.visible = false)


func _on_task_completed(location_id: int) -> void:
	_location_manager.complete_location(location_id)
	GameState.match_state["locations_completed"].append(location_id)
	GameState.match_state["is_paused"] = false

	var loc := _location_manager.get_location_by_id(location_id)
	if loc.item_type == Enums.ItemType.SIZE_INCREASER:
		_player.stats.add_size(1)
		SignalBus.player_size_changed.emit(_player.stats.size)
		GameState.player["size"] = _player.stats.size
		$UI/LabelSize.text = "Size: %d" % _player.stats.size
	elif loc.item_type == Enums.ItemType.PLAYER_ITEM:
		GameState.player["has_item"] = true
		GameState.player["item_id"] = GameState.config.get("item_id", 0)
		SignalBus.player_item_collected.emit()

	# Update marker to green
	if _location_markers.has(location_id):
		var poly := _location_markers[location_id].get_child(0) as Polygon2D
		if poly:
			poly.color = Color(0.2, 0.9, 0.2)
	SignalBus.location_completed.emit(location_id, "player")


func _on_player_item_collected() -> void:
	$UI/LabelItem.text = "Item: Collected!"


func _on_player_energy_changed(value: float) -> void:
	$UI/LabelEnergy.text = "Energy: %d%%" % int(value)
	var speed_text := "FULL" if value > 0.0 else "HALF"
	$UI/LabelSpeed.text = "Speed: %s" % speed_text


func _on_match_ended(result: String) -> void:
	if _match_over:
		return
	_match_over = true
	GameState.current_state = Enums.GameState.GAME_OVER

	var elapsed_sec := float(Time.get_ticks_msec() - _start_time_msec) / 1000.0
	var explored := _fog.get_explored_array().size()
	var final_size: int = GameState.player.get("size", 1)

	if result == "player_win":
		_results_screen.show_win(elapsed_sec, explored, final_size)
	else:
		_results_screen.show_loss("Opponent", elapsed_sec, explored, final_size)


func _on_play_again() -> void:
	GameState.reset_for_new_game()
	SceneManager.go_to_game_scene()
