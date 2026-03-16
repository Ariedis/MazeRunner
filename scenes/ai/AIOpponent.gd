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

## Cooldown timer (seconds) to prevent immediate re-clash after a clash resolves.
var _clash_cooldown: float = 0.0

## Dedicated RNG for clash dice rolls, seeded independently of the navigation RNG.
var _clash_rng: RandomNumberGenerator

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

	# Layer 4: AI body. Mask 1: collide with walls only — player (layer 2) and
	# other AIs (layer 4) are not in this mask, so they phase through freely.
	collision_layer = 4
	collision_mask = 1

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

	_clash_rng = RandomNumberGenerator.new()
	_clash_rng.seed = maze_data.seed_val + ai_idx + 9999

	# position must already be set by the caller before setup() is invoked,
	# so world_to_grid gives the correct spawn grid cell.
	var spawn_grid := renderer.world_to_grid(global_position)
	brain.explored[spawn_grid] = true

	SignalBus.match_ended.connect(_on_match_ended)
	SignalBus.location_completed.connect(_on_location_completed)


func _physics_process(delta: float) -> void:
	if _clash_cooldown > 0.0:
		_clash_cooldown -= delta

	if _match_over:
		velocity = Vector2.ZERO
		return

	if GameState.match_state.get("is_paused", false):
		velocity = Vector2.ZERO
		move_and_slide()
		return

	# PENALTY: stand still, no energy regen, wait for timer.
	if brain.is_in_penalty():
		velocity = Vector2.ZERO
		brain.tick(delta, _renderer.world_to_grid(global_position), _maze_data, stats.energy)
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


## Resolves a clash between this AI and another AI opponent instantly (no overlay).
## Called by GameScene when proximity detection fires for an AI-AI pair.
func resolve_ai_ai_clash(other: AIOpponent) -> void:
	var result := ClashResolver.resolve(stats.size, other.stats.size, _clash_rng)
	var winner: AIOpponent = self if result["winner"] == "a" else other
	var loser: AIOpponent = other if result["winner"] == "a" else self
	var winner_energy: float = winner.stats.energy
	var duration: float = ClashResolver.get_penalty_duration(winner_energy)
	loser.brain.start_penalty(duration)

	# Apply cooldown: base buffer + full penalty duration so neither AI
	# can re-clash until the loser's penalty has expired.
	var total_cooldown := Enums.CLASH_COOLDOWN_SECONDS + duration
	_clash_cooldown = total_cooldown
	other._clash_cooldown = total_cooldown

	# Push apart to separate them.
	var sep_dir := (global_position - other.global_position).normalized()
	if sep_dir == Vector2.ZERO:
		sep_dir = Vector2.RIGHT
	global_position += sep_dir * float(_tile_size) * 0.6
	other.global_position -= sep_dir * float(_tile_size) * 0.6


func _update_visual() -> void:
	if _visual == null:
		return
	var base_color: Color = _STATE_COLORS.get(brain.state, Color(1.0, 0.5, 0.15))
	if brain.state == AIBrain.State.PENALTY:
		base_color = Color(0.6, 0.0, 0.8)  # Purple for penalty state.
	_visual.color = base_color
	if brain.state == AIBrain.State.DO_TASK:
		_visual.modulate.a = 0.6 + 0.4 * sin(Time.get_ticks_msec() * 0.005)
	elif brain.state == AIBrain.State.RESTING:
		_visual.modulate.a = 0.5 + 0.5 * sin(Time.get_ticks_msec() * 0.003)
	elif brain.state == AIBrain.State.PENALTY:
		_visual.modulate.a = 0.4 + 0.6 * sin(Time.get_ticks_msec() * 0.008)
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
