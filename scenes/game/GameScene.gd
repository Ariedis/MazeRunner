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
var _ai_opponents: Array = []
var _tile_size: int = 0
var _clash_overlay: ClashOverlay
var _clash_active: bool = false
var _clash_rng: RandomNumberGenerator
var _hud: GameHUD
var _pause_menu: PauseMenu


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

	_tile_size = size_data["cell_px"] / 2
	var tile_size: int = _tile_size
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

	# Spawn AI opponents (added before fog so fog covers them in unexplored areas).
	var num_opponents: int = GameState.config.get("num_opponents", 1)
	var ai_difficulties: Array = GameState.config.get("ai_difficulties", [Enums.Difficulty.EASY])
	for i in min(num_opponents, _maze_data.ai_spawns.size()):
		var ai := AIOpponent.new()
		ai.name = "AIOpponent_%d" % i
		add_child(ai)
		ai.position = _renderer.get_world_position(_maze_data.ai_spawns[i])
		var diff: int = ai_difficulties[i] if i < ai_difficulties.size() else Enums.Difficulty.EASY
		ai.setup(tile_size, diff, i, _maze_data, _location_manager, _renderer)
		ai.reached_exit_with_item.connect(_on_ai_reached_exit_with_item)
		_ai_opponents.append(ai)

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

	# Clash overlay (CanvasLayer z=15, between task overlay and results)
	_clash_overlay = ClashOverlay.new()
	_clash_overlay.name = "ClashOverlay"
	add_child(_clash_overlay)
	_clash_overlay.clash_resolved.connect(_on_clash_resolved)
	_clash_overlay.penalty_completed.connect(_on_clash_penalty_completed)

	_clash_rng = RandomNumberGenerator.new()
	_clash_rng.seed = _maze_data.seed_val ^ 0xC1A51

	# Win condition manager
	_win_condition = WinConditionManager.new()
	SignalBus.match_ended.connect(_on_match_ended)

	var cam := Camera2D.new()
	cam.name = "Camera2D"
	cam.enabled = true
	_player.add_child(cam)

	# HUD (CanvasLayer z=5)
	_hud = GameHUD.new()
	_hud.name = "GameHUD"
	add_child(_hud)
	_hud.setup(GameState.player.get("avatar_id", 0))
	_hud.update_size(GameState.player.get("size", 1))
	_hud.update_energy(GameState.player.get("energy", 100.0))
	_hud.update_speed(true)

	# Pause menu (CanvasLayer z=10)
	_pause_menu = PauseMenu.new()
	_pause_menu.name = "PauseMenu"
	add_child(_pause_menu)
	_pause_menu.resume_requested.connect(_on_pause_resume)
	_pause_menu.save_requested.connect(_on_pause_save)
	_pause_menu.quit_to_menu_requested.connect(SceneManager.go_to_main_menu)

	SignalBus.player_energy_changed.connect(_on_player_energy_changed)
	SignalBus.player_item_collected.connect(_on_player_item_collected)
	GameState.current_state = Enums.GameState.IN_GAME

	_start_time_msec = Time.get_ticks_msec()


func _process(_delta: float) -> void:
	if _match_over:
		return
	if GameState.match_state.get("is_paused", false):
		return

	_check_clashes()

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


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and not _match_over:
		# Do not open pause menu while task overlay or clash overlay is active
		if _task_overlay.visible or _clash_overlay.visible:
			return
		_toggle_pause()


func _toggle_pause() -> void:
	var is_paused: bool = not GameState.match_state.get("is_paused", false)
	GameState.match_state["is_paused"] = is_paused
	if is_paused:
		GameState.current_state = Enums.GameState.PAUSED
		_pause_menu.show_menu()
	else:
		GameState.current_state = Enums.GameState.IN_GAME
		_pause_menu.hide_menu()


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
		pass
	else:
		_hud.show_rejection_message("You need your item to exit!")


func _on_task_completed(location_id: int) -> void:
	_location_manager.complete_location(location_id)
	GameState.match_state["locations_completed"].append(location_id)
	GameState.match_state["is_paused"] = false

	var loc := _location_manager.get_location_by_id(location_id)
	if loc.item_type == Enums.ItemType.SIZE_INCREASER:
		_player.stats.add_size(1)
		SignalBus.player_size_changed.emit(_player.stats.size)
		GameState.player["size"] = _player.stats.size
		_hud.update_size(_player.stats.size)
	elif loc.item_type == Enums.ItemType.PLAYER_ITEM:
		GameState.player["has_item"] = true
		GameState.player["item_id"] = GameState.config.get("item_id", "")
		SignalBus.player_item_collected.emit()

	# Update marker to green
	if _location_markers.has(location_id):
		var poly := _location_markers[location_id].get_child(0) as Polygon2D
		if poly:
			poly.color = Color(0.2, 0.9, 0.2)
	SignalBus.location_completed.emit(location_id, "player")


func _on_player_item_collected() -> void:
	_hud.show_item_collected()


func _on_player_energy_changed(value: float) -> void:
	_hud.update_energy(value)
	_hud.update_speed(value > 0.0)


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


func _on_ai_reached_exit_with_item() -> void:
	if not _match_over:
		_win_condition.check_ai_at_exit(true)


func _on_play_again() -> void:
	GameState.reset_for_new_game()
	SceneManager.go_to_game_scene()


func _on_pause_resume() -> void:
	_toggle_pause()


func _on_pause_save() -> void:
	# Phase 10: trigger save system
	pass


## Proximity-based clash detection. Called every frame from _process.
func _check_clashes() -> void:
	var clash_dist := float(_tile_size) * 1.0

	# Player vs AI opponents.
	if not _clash_active and _player._clash_cooldown <= 0.0 and not _player._is_frozen:
		for ai in _ai_opponents:
			var opp: AIOpponent = ai
			if opp._clash_cooldown > 0.0 or opp.brain.is_in_penalty():
				continue
			if _player.global_position.distance_to(opp.global_position) <= clash_dist:
				_on_player_clash_triggered(opp)
				break

	# AI vs AI opponents (check each unordered pair once).
	for i in _ai_opponents.size():
		var ai_a: AIOpponent = _ai_opponents[i]
		if ai_a._clash_cooldown > 0.0 or ai_a.brain.is_in_penalty():
			continue
		for j in range(i + 1, _ai_opponents.size()):
			var ai_b: AIOpponent = _ai_opponents[j]
			if ai_b._clash_cooldown > 0.0 or ai_b.brain.is_in_penalty():
				continue
			if ai_a.global_position.distance_to(ai_b.global_position) <= clash_dist:
				ai_a.resolve_ai_ai_clash(ai_b)
				break


## Handles a detected player-vs-AI clash.
func _on_player_clash_triggered(opp: AIOpponent) -> void:
	if _match_over or _clash_active:
		return
	if opp.brain.is_in_penalty() or opp._clash_cooldown > 0.0:
		return

	_clash_active = true
	_player.freeze()

	var result := ClashResolver.resolve(_player.stats.size, opp.stats.size, _clash_rng)
	var player_won: bool = result["winner"] == "a"

	var winner_size: int = _player.stats.size if player_won else opp.stats.size
	var winner_energy: float = _player.stats.energy if player_won else opp.stats.energy
	var penalty_duration: float = ClashResolver.get_penalty_duration(winner_energy)

	if player_won:
		opp.brain.start_penalty(penalty_duration)

	var total_cooldown := Enums.CLASH_COOLDOWN_SECONDS + penalty_duration
	_player._clash_cooldown = total_cooldown
	opp._clash_cooldown = total_cooldown
	var sep_dir := (_player.global_position - opp.global_position).normalized()
	if sep_dir == Vector2.ZERO:
		sep_dir = Vector2.RIGHT
	_player.global_position += sep_dir * float(_tile_size) * 0.6
	opp.global_position -= sep_dir * float(_tile_size) * 0.6

	var task := ClashTaskLoader.load_active_task()

	_clash_overlay.show_clash_result({
		"player_won": player_won,
		"player_roll": result["roll_a"],
		"player_size": _player.stats.size,
		"player_total": result["total_a"],
		"opp_roll": result["roll_b"],
		"opp_size": opp.stats.size,
		"opp_total": result["total_b"],
		"rerolls": result["rerolls"],
		"weight": ClashResolver.get_penalty_weight(winner_size),
		"speed": ClashResolver.get_penalty_speed(winner_energy),
		"duration": penalty_duration,
		"exercise": task["exercise"],
		"reps": task["reps"],
	})


## Player won the clash — dismiss overlay and resume.
func _on_clash_resolved() -> void:
	_player.unfreeze()
	_clash_active = false


## Player lost the clash — penalty complete, resume.
func _on_clash_penalty_completed() -> void:
	_player.unfreeze()
	_clash_active = false
