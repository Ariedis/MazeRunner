extends Node2D

const Y_SCALE := 0.8
const Y_SCALE_INV := 1.25

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
var _ai_last_grid_cells: Array = []  # Tracks each AI's last grid cell for trap/hazard checks.
var _tile_size: int = 0
var _clash_overlay: ClashOverlay
var _clash_active: bool = false
var _clash_rng: RandomNumberGenerator
var _pending_ai_clashes: Array = []  # AI-AI clashes deferred while player clash is active.
var _hud: GameHUD
var _pause_menu: PauseMenu
var _save_slot_panel: SaveSlotPanel
var _game_world: Node2D

# --- Feature managers (null when feature is disabled) ---
var _powerup_manager: PowerupManager = null
var _trap_manager: TrapManager = null
var _hazard_manager: HazardManager = null


func _ready() -> void:
	var map_size = GameState.config.get("map_size", Enums.MapSize.SMALL)
	var seed_cfg: int = GameState.config.get("seed", 0)
	var seed_val = seed_cfg if seed_cfg != 0 else -1

	var gen = MazeGenerator.new()
	_maze_data = gen.generate(map_size, seed_val)

	# Create scaled game world container for oblique/fake-isometric view.
	_game_world = Node2D.new()
	_game_world.name = "GameWorld"
	_game_world.scale = Vector2(1.0, Y_SCALE)
	add_child(_game_world)

	var size_data = Enums.MAP_SIZE_DATA[map_size]
	_renderer = MazeRenderer.new()
	_renderer.name = "MazeRenderer"
	_game_world.add_child(_renderer)
	_renderer.render(_maze_data, size_data["cell_px"])

	var player_scene: PackedScene = load("res://scenes/player/Player.tscn")
	_player = player_scene.instantiate()
	_player.name = "Player"
	_player.z_index = 5
	_game_world.add_child(_player)

	_tile_size = size_data["cell_px"] / 2
	var tile_size: int = _tile_size
	_player.setup(tile_size)
	_player.position = _renderer.get_world_position(_maze_data.player_spawn)

	_fog = FogOfWar.new()
	_fog_renderer = FogRenderer.new()
	_fog_renderer.name = "FogRenderer"
	_fog_renderer.z_index = 10
	_fog_renderer.initialize(_maze_data.width, _maze_data.height, tile_size)

	# Set up task system
	var task_loader := TaskLoader.new()
	var task_category: String = GameState.config.get("task_category", "")
	var tasks := task_loader.load_all_tasks(task_category)
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
		ai.z_index = 5
		_game_world.add_child(ai)
		ai.position = _renderer.get_world_position(_maze_data.ai_spawns[i])
		var diff: int = ai_difficulties[i] if i < ai_difficulties.size() else Enums.Difficulty.EASY
		ai.setup(tile_size, diff, i, _maze_data, _location_manager, _renderer)
		ai.reached_exit_with_item.connect(_on_ai_reached_exit_with_item)
		_ai_opponents.append(ai)
		_ai_last_grid_cells.append(Vector2i(-1, -1))

	# --- Feature: Maze Hazards (generates first so visuals appear under other features) ---
	if GameState.config.get("enable_hazards", false):
		_hazard_manager = HazardManager.new()
		_hazard_manager.name = "HazardManager"
		_hazard_manager.z_index = 3
		_game_world.add_child(_hazard_manager)
		_hazard_manager.setup(_maze_data, tile_size, _renderer)
		# Hard AI knows all dead-end trap positions up front.
		var trap_positions := _hazard_manager.get_active_dead_end_trap_positions()
		for ai in _ai_opponents:
			if ai.brain.difficulty == Enums.Difficulty.HARD:
				ai.brain.forbidden_cells = trap_positions.duplicate()
			ai.brain.teleporter_pairs = _maze_data.teleporter_pairs

	# --- Feature: Power-ups ---
	if GameState.config.get("enable_powerups", false):
		_powerup_manager = PowerupManager.new()
		_powerup_manager.name = "PowerupManager"
		_powerup_manager.z_index = 3
		_game_world.add_child(_powerup_manager)
		_powerup_manager.setup(_maze_data, tile_size, _renderer)
		var powerup_positions := _powerup_manager.get_all_positions()
		for ai in _ai_opponents:
			if ai.brain.difficulty == Enums.Difficulty.HARD:
				ai.brain.powerup_positions = powerup_positions.duplicate()

	# --- Feature: Traps ---
	if GameState.config.get("enable_traps", false):
		_trap_manager = TrapManager.new()
		_trap_manager.name = "TrapManager"
		_trap_manager.z_index = 3
		_game_world.add_child(_trap_manager)
		var map_size_val: int = GameState.config.get("map_size", Enums.MapSize.SMALL)
		_trap_manager.setup(map_size_val, tile_size, _renderer)

	_game_world.add_child(_fog_renderer)

	# Reveal fog around player spawn immediately so the player is visible from frame 1.
	var spawn_cell := _renderer.world_to_grid(_player.position)
	var initial_revealed := _fog.reveal(spawn_cell, _maze_data.width, _maze_data.height)
	if initial_revealed.size() > 0:
		_fog_renderer.reveal_cells(initial_revealed)
		GameState.player["explored_cells"] = _fog.get_explored_array()
	_last_grid_cell = spawn_cell

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
	_results_screen.view_leaderboard_requested.connect(_on_view_leaderboard)

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
	if _trap_manager != null:
		_hud.show_trap_count(_trap_manager.get_player_supply())

	# Pause menu (CanvasLayer z=10)
	_pause_menu = PauseMenu.new()
	_pause_menu.name = "PauseMenu"
	add_child(_pause_menu)
	_pause_menu.resume_requested.connect(_on_pause_resume)
	_pause_menu.save_requested.connect(_on_pause_save)
	_pause_menu.quit_to_menu_requested.connect(SceneManager.go_to_main_menu)

	# Save slot panel (shared for save UI)
	_save_slot_panel = SaveSlotPanel.new(SaveSlotPanel.Mode.SAVE)
	_save_slot_panel.name = "SaveSlotPanel"
	add_child(_save_slot_panel)
	_save_slot_panel.slot_selected.connect(_on_save_slot_selected)

	SignalBus.player_energy_changed.connect(_on_player_energy_changed)
	SignalBus.player_item_collected.connect(_on_player_item_collected)
	GameState.current_state = Enums.GameState.IN_GAME

	_start_time_msec = Time.get_ticks_msec()

	# If loading from a save, apply saved state now.
	var save_data = GameState.take_pending_save_data()
	if save_data != null:
		_apply_save_data(save_data)


func _process(_delta: float) -> void:
	if _match_over:
		return
	if GameState.match_state.get("is_paused", false):
		return

	_check_clashes()
	_check_ai_grid_cells()

	var cell := _renderer.world_to_grid(_player.position)
	if cell == _last_grid_cell:
		return
	_last_grid_cell = cell

	var revealed := _fog.reveal(cell, _maze_data.width, _maze_data.height)
	if revealed.size() > 0:
		_fog_renderer.reveal_cells(revealed)
		GameState.player["explored_cells"] = _fog.get_explored_array()

	# Power-up pickup (player).
	if _powerup_manager != null and _powerup_manager.has_powerup_at(cell):
		_apply_player_powerup(cell)

	# Hazard check (player). Player is immune to own traps.
	if _hazard_manager != null:
		_check_player_hazard(cell)

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

	if event.is_action_pressed("place_trap") and not _match_over and _trap_manager != null:
		if not GameState.match_state.get("is_paused", false) and not _clash_active and not _task_overlay.visible:
			_try_place_trap()


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
	layer.z_index = 4
	_game_world.add_child(layer)
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
	layer.z_index = 4
	_game_world.add_child(layer)

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


## Checks all AI opponents for grid cell transitions and applies feature effects.
func _check_ai_grid_cells() -> void:
	for i in _ai_opponents.size():
		if i >= _ai_last_grid_cells.size():
			continue
		var ai: AIOpponent = _ai_opponents[i]
		if ai._match_over:
			continue
		var ai_cell := _renderer.world_to_grid(ai.position)
		if ai_cell == _ai_last_grid_cells[i]:
			continue
		_ai_last_grid_cells[i] = ai_cell

		# Power-up: Easy ignores, Medium and Hard pick up if on cell.
		if _powerup_manager != null and _powerup_manager.has_powerup_at(ai_cell):
			if ai.brain.difficulty != Enums.Difficulty.EASY:
				_apply_ai_powerup(ai, ai_cell)

		# Trap: player is immune (player placed all traps), AIs are victims.
		if _trap_manager != null and _trap_manager.has_trap_at(ai_cell):
			_trap_manager.trigger_trap(ai_cell)
			ai._speed_multiplier = Enums.TRAP_SLOW_MULTIPLIER
			ai._speed_timer = Enums.TRAP_SLOW_DURATION
			ai._flash_timer = 0.35
			ai._flash_color = Color(1.0, 0.1, 0.1)

		# Hazard.
		if _hazard_manager != null:
			_check_ai_hazard(ai, ai_cell)


func _apply_player_powerup(cell: Vector2i) -> void:
	var type := _powerup_manager.consume_powerup(cell)
	match type:
		Enums.PowerupType.SPEED_BOOST:
			_player._speed_multiplier = Enums.POWERUP_SPEED_BOOST_MULTIPLIER
			_player._speed_timer = Enums.POWERUP_SPEED_BOOST_DURATION
		Enums.PowerupType.ENERGY_REFILL:
			_player.stats.energy = minf(100.0, _player.stats.energy + Enums.POWERUP_ENERGY_REFILL_AMOUNT)
			GameState.player["energy"] = _player.stats.energy
			SignalBus.player_energy_changed.emit(_player.stats.energy)
		Enums.PowerupType.AREA_REVEAL:
			var old_radius := _fog.reveal_radius
			_fog.reveal_radius = Enums.POWERUP_AREA_REVEAL_RADIUS
			var large_reveal := _fog.reveal(_last_grid_cell, _maze_data.width, _maze_data.height)
			_fog.reveal_radius = old_radius
			if large_reveal.size() > 0:
				_fog_renderer.reveal_cells(large_reveal)
				GameState.player["explored_cells"] = _fog.get_explored_array()
	_sync_hard_ai_powerup_knowledge()


func _apply_ai_powerup(ai: AIOpponent, cell: Vector2i) -> void:
	var type := _powerup_manager.consume_powerup(cell)
	match type:
		Enums.PowerupType.SPEED_BOOST:
			ai._speed_multiplier = Enums.POWERUP_SPEED_BOOST_MULTIPLIER
			ai._speed_timer = Enums.POWERUP_SPEED_BOOST_DURATION
		Enums.PowerupType.ENERGY_REFILL:
			ai.stats.energy = minf(100.0, ai.stats.energy + Enums.POWERUP_ENERGY_REFILL_AMOUNT)
		Enums.PowerupType.AREA_REVEAL:
			pass  # No fog benefit for AI.
	_sync_hard_ai_powerup_knowledge()


func _sync_hard_ai_powerup_knowledge() -> void:
	if _powerup_manager == null:
		return
	var remaining := _powerup_manager.get_all_positions()
	for ai in _ai_opponents:
		if ai.brain.difficulty == Enums.Difficulty.HARD:
			ai.brain.powerup_positions = remaining.duplicate()


func _check_player_hazard(cell: Vector2i) -> void:
	# Dead-end trap.
	if _hazard_manager.is_dead_end_trap(cell):
		_hazard_manager.trigger_dead_end_trap(cell)
		_player.stats.energy = maxf(0.0, _player.stats.energy - Enums.HAZARD_DEAD_END_ENERGY_DRAIN)
		GameState.player["energy"] = _player.stats.energy
		SignalBus.player_energy_changed.emit(_player.stats.energy)
		_player._hazard_freeze_timer = Enums.HAZARD_DEAD_END_FREEZE_DURATION
		return
	# Teleporter.
	if _hazard_manager.has_teleporter(cell) and not _hazard_manager.is_on_cooldown(cell):
		var partner := _hazard_manager.get_teleporter_partner(cell)
		if partner != Vector2i(-1, -1):
			_hazard_manager.start_teleporter_cooldown(cell)
			_player.position = _renderer.get_world_position(partner)
			_last_grid_cell = partner


func _check_ai_hazard(ai: AIOpponent, cell: Vector2i) -> void:
	# Dead-end trap.
	if _hazard_manager.is_dead_end_trap(cell):
		_hazard_manager.trigger_dead_end_trap(cell)
		ai.stats.energy = maxf(0.0, ai.stats.energy - Enums.HAZARD_DEAD_END_ENERGY_DRAIN)
		ai._hazard_freeze_timer = Enums.HAZARD_DEAD_END_FREEZE_DURATION
		# Medium AI remembers triggered dead ends to avoid revisiting.
		if ai.brain.difficulty == Enums.Difficulty.MEDIUM:
			if not ai.brain.triggered_dead_ends.has(cell):
				ai.brain.triggered_dead_ends.append(cell)
		return
	# Teleporter.
	if _hazard_manager.has_teleporter(cell) and not _hazard_manager.is_on_cooldown(cell):
		var partner := _hazard_manager.get_teleporter_partner(cell)
		if partner != Vector2i(-1, -1):
			_hazard_manager.start_teleporter_cooldown(cell)
			ai.position = _renderer.get_world_position(partner)
			var ai_idx := _ai_opponents.find(ai)
			if ai_idx >= 0:
				_ai_last_grid_cells[ai_idx] = partner


func _try_place_trap() -> void:
	var cell := _renderer.world_to_grid(_player.position)
	if _trap_manager.is_valid_placement(cell, _maze_data):
		_trap_manager.place_trap(cell)
		_hud.show_trap_count(_trap_manager.get_player_supply())
	elif _trap_manager.get_player_supply() <= 0:
		_hud.show_rejection_message("No traps remaining!")
	elif not _trap_manager.can_place():
		_hud.show_rejection_message("Trap cooldown active!")
	else:
		_hud.show_rejection_message("Cannot place trap here!")


func _on_view_leaderboard() -> void:
	var overlay := LeaderboardOverlay.new()
	overlay.name = "LeaderboardOverlay"
	add_child(overlay)


func _handle_exit_interaction() -> void:
	if _match_over:
		return
	var has_item: bool = GameState.player.get("has_item", false)
	var result := _win_condition.check_player_at_exit(has_item)
	if result == WinConditionManager.Result.PLAYER_WIN:
		_match_over = true
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
	_pending_ai_clashes.clear()
	GameState.current_state = Enums.GameState.GAME_OVER

	var elapsed_sec := float(Time.get_ticks_msec() - _start_time_msec) / 1000.0
	var explored := _fog.get_explored_array().size()
	var final_size: int = GameState.player.get("size", 1)

	if result == "player_win":
		var rank := -1
		if GameState.config.get("enable_leaderboard", false):
			rank = LeaderboardManager.add_entry(
				GameState.config.get("map_size", Enums.MapSize.SMALL),
				elapsed_sec,
				final_size,
				GameState.config.get("num_opponents", 1)
			)
		_results_screen.show_win(elapsed_sec, explored, final_size, rank)
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
	if _match_over or _clash_active or _task_overlay.visible:
		return
	_save_slot_panel.show_panel()


func _on_save_slot_selected(slot: int) -> void:
	var elapsed := Time.get_ticks_msec() - _start_time_msec
	var data := SaveManager.capture_game_state(
		_maze_data, _player, _fog, _location_manager,
		_ai_opponents, elapsed, _renderer, _clash_active,
		_powerup_manager, _trap_manager, _hazard_manager
	)
	var success := SaveManager.save_game(slot, data)
	if success:
		_hud.show_rejection_message("Game saved!")
	else:
		_hud.show_rejection_message("Save failed!")


## Restores full game state from a loaded save dictionary.
func _apply_save_data(data: Dictionary) -> void:
	# Restore elapsed time offset
	var saved_elapsed: int = data.get("elapsed_msec", 0)
	_start_time_msec = Time.get_ticks_msec() - saved_elapsed

	# Restore player position
	var player_data: Dictionary = data.get("player", {})
	if player_data.has("position"):
		_player.position = SaveManager.arr_to_v2(player_data["position"])
	_player.stats.size = player_data.get("size", 1)
	_player.stats.energy = player_data.get("energy", 100.0)
	_player._clash_cooldown = player_data.get("clash_cooldown", 0.0)
	GameState.player["size"] = _player.stats.size
	GameState.player["energy"] = _player.stats.energy
	GameState.player["has_item"] = player_data.get("has_item", false)
	GameState.player["item_id"] = player_data.get("item_id", "")
	_hud.update_size(_player.stats.size)
	_hud.update_energy(_player.stats.energy)
	if GameState.player["has_item"]:
		_hud.show_item_collected()

	# Restore fog of war from explored cells
	var explored_cells: Array = player_data.get("explored_cells", [])
	var fog_cells: Array = []
	for cell_arr in explored_cells:
		fog_cells.append(SaveManager.arr_to_v2i(cell_arr))
	_fog.load_from_array(fog_cells)
	_fog_renderer.reveal_cells(fog_cells)
	GameState.player["explored_cells"] = _fog.get_explored_array()

	# Restore location states
	var locs_data: Array = data.get("locations", [])
	for loc_save in locs_data:
		var loc_id: int = loc_save.get("id", -1)
		var loc := _location_manager.get_location_by_id(loc_id)
		if loc == null:
			continue
		loc.completed = loc_save.get("completed", false)
		loc.completed_by = loc_save.get("completed_by", [])
		if loc.completed:
			GameState.match_state["locations_completed"].append(loc_id)
			# Update marker to green
			if _location_markers.has(loc_id):
				var poly := _location_markers[loc_id].get_child(0) as Polygon2D
				if poly:
					poly.color = Color(0.2, 0.9, 0.2)

	# Restore AI opponents
	var opponents_data: Array = data.get("opponents", [])
	for i in min(opponents_data.size(), _ai_opponents.size()):
		var opp_data: Dictionary = opponents_data[i]
		var ai: AIOpponent = _ai_opponents[i]

		if opp_data.has("position"):
			ai.position = SaveManager.arr_to_v2(opp_data["position"])
		ai.stats.size = opp_data.get("size", 1)
		ai.stats.energy = opp_data.get("energy", 100.0)
		ai._clash_cooldown = opp_data.get("clash_cooldown", 0.0)

		var brain: AIBrain = ai.brain
		brain.has_item = opp_data.get("has_item", false)
		brain.state = opp_data.get("state", AIBrain.State.EXPLORE)
		brain.exit_known = opp_data.get("exit_known", false)
		if opp_data.has("exit_pos"):
			brain.exit_pos = SaveManager.arr_to_v2i(opp_data["exit_pos"])
		brain.penalty_timer = opp_data.get("penalty_timer", 0.0)
		brain.task_timer = opp_data.get("task_timer", 0.0)
		brain._pre_rest_state = opp_data.get("_pre_rest_state", AIBrain.State.EXPLORE)
		brain._pre_penalty_state = opp_data.get("_pre_penalty_state", AIBrain.State.EXPLORE)
		brain._rest_threshold = opp_data.get("_rest_threshold", 20.0)
		brain._rest_target = opp_data.get("_rest_target", 50.0)

		if opp_data.has("_item_loc_pos"):
			brain._item_loc_pos = SaveManager.arr_to_v2i(opp_data["_item_loc_pos"])
		if opp_data.has("_current_task_pos"):
			brain._current_task_pos = SaveManager.arr_to_v2i(opp_data["_current_task_pos"])
		if opp_data.has("_current_target"):
			brain._current_target = SaveManager.arr_to_v2i(opp_data["_current_target"])

		# Restore explored cells
		brain.explored.clear()
		var ai_explored: Array = opp_data.get("explored_cells", [])
		for cell_arr in ai_explored:
			brain.explored[SaveManager.arr_to_v2i(cell_arr)] = true

		# Restore known uncompleted locations
		brain.known_uncompleted_locs.clear()
		var known_locs: Array = opp_data.get("known_uncompleted_locs", [])
		for loc_arr in known_locs:
			brain.known_uncompleted_locs.append(SaveManager.arr_to_v2i(loc_arr))

		# Restore current path
		brain.current_path.clear()
		var path_arr: Array = opp_data.get("current_path", [])
		for p in path_arr:
			brain.current_path.append(SaveManager.arr_to_v2i(p))

	# Restore power-ups
	if _powerup_manager != null and data.has("powerups"):
		_powerup_manager.load_state(data["powerups"])
		var powerup_positions := _powerup_manager.get_all_positions()
		for ai in _ai_opponents:
			if ai.brain.difficulty == Enums.Difficulty.HARD:
				ai.brain.powerup_positions = powerup_positions.duplicate()

	# Restore traps
	if _trap_manager != null and data.has("traps"):
		var trap_data: Dictionary = data["traps"]
		_trap_manager.load_state(trap_data)
		_hud.show_trap_count(_trap_manager.get_player_supply())
		_player._speed_multiplier = trap_data.get("player_speed_multiplier", 1.0)
		_player._speed_timer = trap_data.get("player_speed_timer", 0.0)

	# Restore hazard triggered state
	if _hazard_manager != null and data.has("hazards"):
		var hazard_data: Dictionary = data["hazards"]
		_hazard_manager.load_triggered_traps(hazard_data.get("triggered_dead_ends", []))

	# Force grid cell recheck on next frame
	_last_grid_cell = Vector2i(-1, -1)


## Proximity-based clash detection. Called every frame from _process.
func _check_clashes() -> void:
	var clash_dist := float(_tile_size) * 1.0

	# Process any deferred AI-AI clashes from when a player clash was active.
	if not _clash_active and _pending_ai_clashes.size() > 0:
		var pending := _pending_ai_clashes.duplicate()
		_pending_ai_clashes.clear()
		for pair in pending:
			var ai_a: AIOpponent = pair[0]
			var ai_b: AIOpponent = pair[1]
			if ai_a._clash_cooldown > 0.0 or ai_a.brain.is_in_penalty():
				continue
			if ai_b._clash_cooldown > 0.0 or ai_b.brain.is_in_penalty():
				continue
			if ai_a.position.distance_to(ai_b.position) <= clash_dist:
				ai_a.resolve_ai_ai_clash(ai_b)

	# Player vs AI opponents.
	if not _clash_active and _player._clash_cooldown <= 0.0 and not _player._is_frozen:
		for ai in _ai_opponents:
			var opp: AIOpponent = ai
			if opp._clash_cooldown > 0.0 or opp.brain.is_in_penalty():
				continue
			if _player.position.distance_to(opp.position) <= clash_dist:
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
			if ai_a.position.distance_to(ai_b.position) <= clash_dist:
				if _clash_active:
					_pending_ai_clashes.append([ai_a, ai_b])
				else:
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
	var sep_dir := (_player.position - opp.position).normalized()
	if sep_dir == Vector2.ZERO:
		sep_dir = Vector2.RIGHT
	_player.position += sep_dir * float(_tile_size) * 0.6
	opp.position -= sep_dir * float(_tile_size) * 0.6

	var clash_category: String = GameState.config.get("task_category", "")
	var task := ClashTaskLoader.load_active_task(clash_category)

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
		"media_path": task.get("media_path", ""),
	})


## Player won the clash — dismiss overlay and resume.
func _on_clash_resolved() -> void:
	_player.unfreeze()
	_clash_active = false


## Player lost the clash — penalty complete, resume.
func _on_clash_penalty_completed() -> void:
	_player.unfreeze()
	_clash_active = false
