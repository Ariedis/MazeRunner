class_name TrapManager
extends Node2D

## Manages player-placed traps. Traps are invisible to opponents until triggered.
## Only the player can place traps; all AIs are potential victims.

# Dict: Vector2i -> {visual: Node2D}
var _traps: Dictionary = {}

var _player_supply: int = 0
var _placement_cooldown: float = 0.0

var _tile_size: int
var _renderer: MazeRenderer


func setup(map_size: int, tile_size: int, renderer: MazeRenderer) -> void:
	_tile_size = tile_size
	_renderer = renderer
	_player_supply = Enums.TRAP_SUPPLY.get(map_size, 2)


func _process(delta: float) -> void:
	if _placement_cooldown > 0.0:
		_placement_cooldown -= delta


## Returns true if the player can currently place a trap.
func can_place() -> bool:
	return _player_supply > 0 and _placement_cooldown <= 0.0


## Returns true if placement is valid at [pos] (not on spawn/exit/location/existing trap).
func is_valid_placement(pos: Vector2i, maze_data: MazeData) -> bool:
	if not can_place():
		return false
	if _traps.has(pos):
		return false
	var cell := maze_data.get_cell_v(pos)
	if cell == null:
		return false
	if cell.is_spawn or cell.is_exit or cell.has_location:
		return false
	return true


## Places a trap at [pos]. Caller must have verified is_valid_placement first.
func place_trap(pos: Vector2i) -> void:
	_player_supply -= 1
	_placement_cooldown = Enums.TRAP_PLACEMENT_COOLDOWN
	var visual := _make_trap_visual()
	visual.position = _renderer.get_world_position(pos)
	visual.visible = false  # Hidden until triggered.
	add_child(visual)
	_traps[pos] = {"visual": visual}


## Returns true if a trap exists at [pos].
func has_trap_at(pos: Vector2i) -> bool:
	return _traps.has(pos)


## Triggers and removes the trap at [pos]. Returns true on success.
func trigger_trap(pos: Vector2i) -> bool:
	if not _traps.has(pos):
		return false
	var visual: Node2D = _traps[pos]["visual"]
	visual.queue_free()
	_traps.erase(pos)
	return true


func get_player_supply() -> int:
	return _player_supply


## Serialises trap state for save.
func save_state() -> Dictionary:
	var positions: Array = []
	for pos in _traps:
		positions.append([pos.x, pos.y])
	return {
		"player_supply": _player_supply,
		"placement_cooldown": _placement_cooldown,
		"positions": positions,
	}


## Restores trap state from save.
func load_state(saved: Dictionary) -> void:
	for pos in _traps.keys():
		_traps[pos]["visual"].queue_free()
	_traps.clear()
	_player_supply = saved.get("player_supply", 0)
	_placement_cooldown = saved.get("placement_cooldown", 0.0)
	for pos_arr in saved.get("positions", []):
		var pos := Vector2i(int(pos_arr[0]), int(pos_arr[1]))
		var visual := _make_trap_visual()
		visual.position = _renderer.get_world_position(pos)
		visual.visible = false
		add_child(visual)
		_traps[pos] = {"visual": visual}


# --- Internal ---

func _make_trap_visual() -> Node2D:
	var n := Node2D.new()
	var poly := Polygon2D.new()
	var r := float(_tile_size) * 0.22
	poly.polygon = PackedVector2Array([
		Vector2(-r, -r), Vector2(r, -r),
		Vector2(r,  r),  Vector2(-r, r),
	])
	poly.color = Color(0.9, 0.1, 0.1, 0.75)
	n.add_child(poly)
	return n
