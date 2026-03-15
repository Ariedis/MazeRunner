extends Node2D

var _maze_data: MazeData
var _renderer: MazeRenderer
var _player: Node2D

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

	_player = Node2D.new()
	_player.name = "PlayerEntity"
	add_child(_player)
	var cam = Camera2D.new()
	cam.name = "Camera2D"
	cam.enabled = true
	_player.add_child(cam)
	_player.position = _renderer.get_world_position(_maze_data.player_spawn)

	$UI/LabelSeed.text = "Seed: %d" % _maze_data.seed_val
	$UI/LabelSize.text = "Size: %s" % ["SMALL", "MEDIUM", "LARGE"][map_size]
	$UI/BtnMainMenu.pressed.connect(SceneManager.go_to_main_menu)
	GameState.current_state = Enums.GameState.IN_GAME

func _process(delta: float) -> void:
	var vel = Vector2.ZERO
	if Input.is_action_pressed("move_up"):    vel.y -= Enums.FULL_SPEED
	if Input.is_action_pressed("move_down"):  vel.y += Enums.FULL_SPEED
	if Input.is_action_pressed("move_left"):  vel.x -= Enums.FULL_SPEED
	if Input.is_action_pressed("move_right"): vel.x += Enums.FULL_SPEED
	if _player:
		_player.position += vel * delta
