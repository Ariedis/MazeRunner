class_name Player
extends CharacterBody2D

const Y_SCALE_INV := 1.25

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

	# Build player visual scaled to tile size: bright gold diamond with dark outline + drop shadow.
	var r := float(tile_size) * 0.4
	var diamond_pts := PackedVector2Array([
		Vector2(0, -r), Vector2(r, 0), Vector2(0, r), Vector2(-r, 0)
	])

	# Drop shadow (dark ellipse slightly below).
	var shadow := Polygon2D.new()
	shadow.name = "Shadow"
	shadow.polygon = diamond_pts
	shadow.color = Color(0.0, 0.0, 0.0, 0.3)
	shadow.position = Vector2(0, r * 0.25)
	shadow.scale = Vector2(0.9, 0.5)
	add_child(shadow)

	# Dark outline (slightly larger polygon behind).
	var outline_r := r + maxf(2.0, r * 0.15)
	var outline_pts := PackedVector2Array([
		Vector2(0, -outline_r), Vector2(outline_r, 0), Vector2(0, outline_r), Vector2(-outline_r, 0)
	])
	var outline := Polygon2D.new()
	outline.name = "Outline"
	outline.polygon = outline_pts
	outline.color = Color(0.16, 0.1, 0.0)
	add_child(outline)

	# Main player diamond.
	$Polygon2D.polygon = diamond_pts
	$Polygon2D.color = Color(1.0, 0.84, 0.2)
	# Ensure main polygon draws on top of outline.
	move_child($Polygon2D, get_child_count() - 1)

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
		var compensated := Vector2(input_dir.x, input_dir.y * Y_SCALE_INV)
		velocity = compensated.normalized() * stats.current_speed() * _speed_multiplier
		stats.drain(delta)
	else:
		velocity = Vector2.ZERO
		stats.regen(delta)

	move_and_slide()

	GameState.player["energy"] = stats.energy
	GameState.player["size"] = stats.size
	GameState.player["position"] = position
	SignalBus.player_energy_changed.emit(stats.energy)
