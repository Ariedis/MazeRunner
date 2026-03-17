class_name Player
extends CharacterBody2D

var stats: PlayerStats = PlayerStats.new()

## True while the player is involved in a clash (immobilized).
var _is_frozen: bool = false

## Cooldown timer (seconds) to prevent immediate re-clash after separation.
var _clash_cooldown: float = 0.0

## Speed multiplier from power-ups (1.8x) or traps (0.4x). Reverts to 1.0 when timer expires.
var _speed_multiplier: float = 1.0
var _speed_timer: float = 0.0

## Freeze timer from maze hazards (dead-end traps). Counts down to 0.
var _hazard_freeze_timer: float = 0.0


func setup(tile_size: int) -> void:
	var shape := CircleShape2D.new()
	shape.radius = tile_size * 0.4
	$CollisionShape2D.shape = shape

	# Layer 2: player body. Mask 1: collide with walls only — AI opponents are on
	# layer 4 and are not in this mask, so they phase through the player.
	collision_layer = 2
	collision_mask = 1

	stats.size = GameState.player.get("size", 1)
	stats.energy = GameState.player.get("energy", 100.0)


func freeze() -> void:
	_is_frozen = true


func unfreeze() -> void:
	_is_frozen = false


func _physics_process(delta: float) -> void:
	if _clash_cooldown > 0.0:
		_clash_cooldown -= delta

	# Tick speed effect timer.
	if _speed_timer > 0.0:
		_speed_timer -= delta
		if _speed_timer <= 0.0:
			_speed_multiplier = 1.0

	# Tick hazard freeze timer.
	if _hazard_freeze_timer > 0.0:
		_hazard_freeze_timer -= delta
		velocity = Vector2.ZERO
		move_and_slide()
		return

	if GameState.match_state.get("is_paused", false) or _is_frozen:
		velocity = Vector2.ZERO
		# Energy does not drain or regen while paused or during a clash penalty.
		return

	var input_dir := Vector2.ZERO
	if Input.is_action_pressed("move_up"):    input_dir.y -= 1.0
	if Input.is_action_pressed("move_down"):  input_dir.y += 1.0
	if Input.is_action_pressed("move_left"):  input_dir.x -= 1.0
	if Input.is_action_pressed("move_right"): input_dir.x += 1.0

	var moving := input_dir != Vector2.ZERO

	if moving:
		velocity = input_dir.normalized() * stats.current_speed() * _speed_multiplier
		stats.drain(delta)
	else:
		velocity = Vector2.ZERO
		stats.regen(delta)

	move_and_slide()

	GameState.player["energy"] = stats.energy
	GameState.player["size"] = stats.size
	GameState.player["position"] = global_position
	SignalBus.player_energy_changed.emit(stats.energy)
