class_name Player
extends CharacterBody2D

var stats: PlayerStats = PlayerStats.new()


func setup(tile_size: int) -> void:
	var shape := CircleShape2D.new()
	shape.radius = tile_size * 0.4
	$CollisionShape2D.shape = shape

	stats.size = GameState.player.get("size", 1)
	stats.energy = GameState.player.get("energy", 100.0)


func _physics_process(delta: float) -> void:
	if GameState.match_state.get("is_paused", false):
		velocity = Vector2.ZERO
		return

	var input_dir := Vector2.ZERO
	if Input.is_action_pressed("move_up"):    input_dir.y -= 1.0
	if Input.is_action_pressed("move_down"):  input_dir.y += 1.0
	if Input.is_action_pressed("move_left"):  input_dir.x -= 1.0
	if Input.is_action_pressed("move_right"): input_dir.x += 1.0

	var moving := input_dir != Vector2.ZERO

	if moving:
		velocity = input_dir.normalized() * stats.current_speed()
		stats.drain(delta)
	else:
		velocity = Vector2.ZERO
		stats.regen(delta)

	move_and_slide()

	GameState.player["energy"] = stats.energy
	GameState.player["size"] = stats.size
	GameState.player["position"] = global_position
	SignalBus.player_energy_changed.emit(stats.energy)
