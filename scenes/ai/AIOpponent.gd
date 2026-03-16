class_name AIOpponent
extends CharacterBody2D

signal reached_exit_with_item()

var stats: PlayerStats
var brain: AIBrain

var _maze_data: MazeData
var _renderer: MazeRenderer
var _location_manager: LocationManager
var _tile_size: int
var _ai_index: int = 0
var _difficulty: int = Enums.Difficulty.MEDIUM
var _match_over: bool = false
var _collision_shape: CollisionShape2D
var _visual: Polygon2D

## Colors for each brain state, providing visual feedback to the player.
const _STATE_COLORS: Dictionary = {
	AIBrain.State.EXPLORE: Color(1.0, 0.5, 0.15),
	AIBrain.State.GO_TO_LOC: Color(1.0, 0.85, 0.1),
	AIBrain.State.DO_TASK: Color(0.3, 0.5, 1.0),
	AIBrain.State.GO_TO_EXIT: Color(1.0, 0.15, 0.15),
	AIBrain.State.RESTING: Color(0.4, 0.9, 0.4),
}


## All initialisation happens in setup() — do NOT use _ready() here.
## Godot defers child _ready() when nodes are added during a parent's _ready(),
## so _ready() would run AFTER setup(), leaving _collision_shape null.
func setup(tile_size: int, difficulty: int, ai_idx: int, maze_data: MazeData,
		location_manager: LocationManager, renderer: MazeRenderer) -> void:
	_tile_size = tile_size
	_ai_index = ai_idx
	_difficulty = difficulty
	_maze_data = maze_data
	_location_manager = location_manager
	_renderer = renderer

	# Must be set before move_and_slide() is ever called.
	motion_mode = MOTION_MODE_FLOATING

	# Create child nodes here (not in _ready()) to guarantee they exist.
	_collision_shape = CollisionShape2D.new()
	_collision_shape.name = "CollisionShape2D"
	add_child(_collision_shape)

	_visual = Polygon2D.new()
	_visual.name = "Visual"
	_visual.color = Color(1.0, 0.5, 0.15)
	add_child(_visual)

	var shape := CircleShape2D.new()
	shape.radius = tile_size * 0.4
	_collision_shape.shape = shape

	var r := float(tile_size) * 0.35
	var pts: PackedVector2Array
	for i in 8:
		var a := i * TAU / 8.0
		pts.append(Vector2(cos(a), sin(a)) * r)
	_visual.polygon = pts

	stats = PlayerStats.new()

	var rng := RandomNumberGenerator.new()
	rng.seed = maze_data.seed_val + ai_idx + 1

	brain = AIBrain.new()
	brain.setup(difficulty, maze_data, rng)

	# position must already be set by the caller before setup() is invoked,
	# so world_to_grid gives the correct spawn grid cell.
	var spawn_grid := renderer.world_to_grid(global_position)
	brain.explored[spawn_grid] = true

	SignalBus.match_ended.connect(_on_match_ended)
	SignalBus.location_completed.connect(_on_location_completed)


func _physics_process(delta: float) -> void:
	if _match_over:
		velocity = Vector2.ZERO
		return

	if GameState.match_state.get("is_paused", false):
		velocity = Vector2.ZERO
		move_and_slide()
		return

	# Check if we've arrived at the next path step.
	var next_step := brain.get_next_step()
	if next_step != Vector2i(-1, -1):
		var target_world := _renderer.get_world_position(next_step)
		if (target_world - global_position).length() < float(_tile_size) * 0.25:
			global_position = target_world
			var won := brain.on_step_reached(next_step, _maze_data)
			if won:
				_match_over = true
				reached_exit_with_item.emit()
				velocity = Vector2.ZERO
				return
			_handle_location_arrival(next_step)

	# Tick brain: state transitions and path planning.
	brain.tick(delta, _renderer.world_to_grid(global_position), _maze_data, stats.energy)

	# Update visual color based on current brain state.
	_update_visual()

	# Stand still while doing a task; complete it when timer expires.
	if brain.is_doing_task():
		if brain.task_timer <= 0.0:
			_complete_task()
		velocity = Vector2.ZERO
		stats.regen(delta)
		move_and_slide()
		return

	# Stand still while resting to recover energy.
	if brain.is_resting():
		velocity = Vector2.ZERO
		stats.regen(delta)
		move_and_slide()
		return

	# Move toward the next path step.
	next_step = brain.get_next_step()
	if next_step == Vector2i(-1, -1):
		velocity = Vector2.ZERO
		stats.regen(delta)
		move_and_slide()
		return

	var target := _renderer.get_world_position(next_step)
	var dir := target - global_position
	var speed_mult: float = Enums.AI_SPEED_MULTIPLIER.get(_difficulty, 1.0)
	velocity = dir.normalized() * stats.current_speed() * speed_mult
	stats.drain(delta)
	move_and_slide()


func _update_visual() -> void:
	if _visual == null:
		return
	var base_color: Color = _STATE_COLORS.get(brain.state, Color(1.0, 0.5, 0.15))
	_visual.color = base_color
	if brain.state == AIBrain.State.DO_TASK:
		_visual.modulate.a = 0.6 + 0.4 * sin(Time.get_ticks_msec() * 0.005)
	elif brain.state == AIBrain.State.RESTING:
		_visual.modulate.a = 0.5 + 0.5 * sin(Time.get_ticks_msec() * 0.003)
	else:
		_visual.modulate.a = 1.0


func _handle_location_arrival(grid_pos: Vector2i) -> void:
	if brain.is_doing_task():
		return

	if not _location_manager.has_uncompleted_at(grid_pos):
		# Location was already completed — remove from brain's known list.
		var idx := brain.known_uncompleted_locs.find(grid_pos)
		if idx >= 0:
			brain.known_uncompleted_locs.remove_at(idx)
		return

	var loc := _location_manager.get_location_at(grid_pos)
	if loc == null:
		return

	var duration := 20.0
	if loc.task != null:
		duration = loc.task.duration_seconds

	brain.start_task(duration, grid_pos)


func _complete_task() -> void:
	var grid_cell := _renderer.world_to_grid(global_position)
	var loc := _location_manager.get_location_at(grid_cell)
	if loc != null and not loc.completed:
		_location_manager.complete_location(loc.id, "ai_%d" % _ai_index)
		SignalBus.location_completed.emit(loc.id, "ai_%d" % _ai_index)
	brain.on_task_complete()


func _on_location_completed(location_id: int, completed_by: String) -> void:
	# Ignore our own completions.
	if completed_by == "ai_%d" % _ai_index:
		return
	var loc := _location_manager.get_location_by_id(location_id)
	if loc == null:
		return
	brain.on_location_completed_externally(loc.grid_pos)


func _on_match_ended(_result: String) -> void:
	_match_over = true
