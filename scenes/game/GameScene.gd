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

	# Spawn location markers (above maze, below fog)
	_spawn_location_markers(tile_size)

	add_child(_fog_renderer)

	# Task overlay (CanvasLayer — renders above everything)
	_task_overlay = TaskOverlay.new()
	_task_overlay.name = "TaskOverlay"
	add_child(_task_overlay)
	_task_overlay.task_completed.connect(_on_task_completed)

	var cam := Camera2D.new()
	cam.name = "Camera2D"
	cam.enabled = true
	_player.add_child(cam)

	$UI/LabelSeed.text = "Seed: %d" % _maze_data.seed_val
	$UI/LabelSize.text = "Size: %s" % ["SMALL", "MEDIUM", "LARGE"][map_size]
	$UI/LabelEnergy.text = "Energy: 100%%"
	$UI/BtnMainMenu.pressed.connect(SceneManager.go_to_main_menu)

	SignalBus.player_energy_changed.connect(_on_player_energy_changed)
	GameState.current_state = Enums.GameState.IN_GAME


func _process(_delta: float) -> void:
	var cell := _renderer.world_to_grid(_player.global_position)
	if cell == _last_grid_cell:
		return
	_last_grid_cell = cell
	var revealed := _fog.reveal(cell, _maze_data.width, _maze_data.height)
	if revealed.size() > 0:
		_fog_renderer.reveal_cells(revealed)
		GameState.player["explored_cells"] = _fog.get_explored_array()

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


func _on_task_completed(location_id: int) -> void:
	_location_manager.complete_location(location_id)
	GameState.match_state["locations_completed"].append(location_id)
	GameState.match_state["is_paused"] = false

	var loc := _location_manager.get_location_by_id(location_id)
	if loc.item_type == Enums.ItemType.SIZE_INCREASER:
		_player.stats.add_size(1)
		SignalBus.player_size_changed.emit(_player.stats.size)
		GameState.player["size"] = _player.stats.size
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


func _on_player_energy_changed(value: float) -> void:
	$UI/LabelEnergy.text = "Energy: %d%%" % int(value)
	var speed_text := "FULL" if value > 0.0 else "HALF"
	$UI/LabelSpeed.text = "Speed: %s" % speed_text
