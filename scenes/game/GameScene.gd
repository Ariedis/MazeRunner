extends Node2D

var _maze_data: MazeData
var _renderer: MazeRenderer
var _player: Player
var _fog: FogOfWar
var _fog_renderer: FogRenderer
var _last_grid_cell := Vector2i(-1, -1)


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
	add_child(_fog_renderer)
	_fog_renderer.initialize(_maze_data.width, _maze_data.height, tile_size)

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


func _on_player_energy_changed(value: float) -> void:
	$UI/LabelEnergy.text = "Energy: %d%%" % int(value)
	var speed_text := "FULL" if value > 0.0 else "HALF"
	$UI/LabelSpeed.text = "Speed: %s" % speed_text
