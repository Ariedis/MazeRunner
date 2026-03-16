class_name AIBrain
extends RefCounted


enum State { EXPLORE = 0, GO_TO_LOC, DO_TASK, GO_TO_EXIT, RESTING, PENALTY }

var difficulty: int = Enums.Difficulty.MEDIUM
var state: int = State.EXPLORE
var has_item: bool = false

## State saved before entering RESTING, restored when rest is complete.
var _pre_rest_state: int = State.EXPLORE
var _rest_threshold: float = 20.0
var _rest_target: float = 50.0

## State saved before entering PENALTY, restored when penalty timer expires.
var _pre_penalty_state: int = State.EXPLORE

## Penalty countdown timer (seconds). Active while state == PENALTY.
var penalty_timer: float = 0.0

## Cells this AI has physically visited.
var explored: Dictionary = {}  # Vector2i -> true

## Positions of known uncompleted locations.
var known_uncompleted_locs: Array = []  # Array of Vector2i

var exit_known: bool = false
var exit_pos: Vector2i = Vector2i(-1, -1)

## Task countdown timer (seconds remaining).
var task_timer: float = 0.0

## Current A* path — head is next cell to move toward.
var current_path: Array = []  # Array of Vector2i

var _item_loc_pos: Vector2i = Vector2i(-1, -1)
var _current_task_pos: Vector2i = Vector2i(-1, -1)
var _current_target: Vector2i = Vector2i(-1, -1)
var _pathfinder: AStarPathfinder
var _rng: RandomNumberGenerator


## Initialise the brain. Hard AI gets full location/exit knowledge upfront.
func setup(diff: int, maze_data: MazeData, rng: RandomNumberGenerator) -> void:
	difficulty = diff
	_rng = rng
	_pathfinder = AStarPathfinder.new()
	_rest_threshold = Enums.AI_REST_THRESHOLD.get(diff, 20.0)
	_rest_target = Enums.AI_REST_TARGET.get(diff, 50.0)

	# Every difficulty: pick a random location as this AI's item location.
	if maze_data.locations.size() > 0:
		var idx := rng.randi() % maze_data.locations.size()
		_item_loc_pos = maze_data.locations[idx]

	# Hard AI: omniscient — knows all locations and exit from the start.
	if difficulty == Enums.Difficulty.HARD:
		for pos in maze_data.locations:
			if not known_uncompleted_locs.has(pos):
				known_uncompleted_locs.append(pos)
		exit_known = true
		exit_pos = maze_data.exit
		if not known_uncompleted_locs.is_empty():
			state = State.GO_TO_LOC


## Called by AIOpponent when this AI loses a clash.
## duration: penalty wait time in seconds (mirrors the physical task timer).
func start_penalty(duration: float) -> void:
	_pre_penalty_state = state
	state = State.PENALTY
	penalty_timer = duration
	current_path.clear()


func is_in_penalty() -> bool:
	return state == State.PENALTY


## Called each physics frame. Advances timers and ensures a valid path exists.
## energy: current energy level from PlayerStats (used for rest decisions).
func tick(delta: float, grid_pos: Vector2i, maze_data: MazeData, energy: float = 100.0) -> void:
	if state == State.DO_TASK:
		task_timer = maxf(0.0, task_timer - delta)
		return

	# PENALTY: stay frozen for the clash penalty duration.
	if state == State.PENALTY:
		penalty_timer = maxf(0.0, penalty_timer - delta)
		if penalty_timer <= 0.0:
			state = _pre_penalty_state
			current_path.clear()
		return

	# RESTING: stay still until energy reaches target, then resume.
	if state == State.RESTING:
		if energy >= _rest_target:
			state = _pre_rest_state
			current_path.clear()
		return

	# Enter RESTING if energy is critically low.
	if energy <= _rest_threshold and state != State.GO_TO_EXIT:
		_pre_rest_state = state
		state = State.RESTING
		current_path.clear()
		return

	# High-priority transitions based on knowledge state.
	if has_item and exit_known:
		if state != State.GO_TO_EXIT:
			state = State.GO_TO_EXIT
			current_path.clear()
	elif has_item and not exit_known:
		if state == State.GO_TO_EXIT:
			state = State.EXPLORE
			current_path.clear()
	else:
		if state == State.EXPLORE and not known_uncompleted_locs.is_empty():
			state = State.GO_TO_LOC
			current_path.clear()
		elif state == State.GO_TO_LOC and known_uncompleted_locs.is_empty():
			state = State.EXPLORE
			current_path.clear()

	if current_path.is_empty():
		_plan_next_path(grid_pos, maze_data)


## Called when the AI physically arrives at a new grid cell.
## Returns true if the AI has reached the exit with its item (win condition).
func on_step_reached(grid_pos: Vector2i, maze_data: MazeData) -> bool:
	# Advance path.
	if not current_path.is_empty() and current_path[0] == grid_pos:
		current_path.pop_front()

	explored[grid_pos] = true

	# Easy/Medium: discover locations and exit by physical contact.
	if difficulty != Enums.Difficulty.HARD:
		var cell := maze_data.get_cell_v(grid_pos)
		if cell != null and cell.has_location and not known_uncompleted_locs.has(grid_pos):
			known_uncompleted_locs.append(grid_pos)

	# All difficulties: discover exit by walking to it.
	if not exit_known:
		var cell := maze_data.get_cell_v(grid_pos)
		if cell != null and cell.is_exit:
			exit_known = true
			exit_pos = grid_pos

	# Win condition: at exit with item.
	if has_item and exit_known and grid_pos == exit_pos:
		return true

	# Easy: 15% chance of a wrong turn at junctions (3+ passable neighbours).
	if difficulty == Enums.Difficulty.EASY and not current_path.is_empty():
		var neighbors := _pathfinder.get_passable_neighbors(maze_data, grid_pos)
		if neighbors.size() >= 3 and _rng.randf() < 0.15:
			current_path = [neighbors[_rng.randi() % neighbors.size()]]

	# Clear path when we've reached the current target.
	if grid_pos == _current_target:
		_current_target = Vector2i(-1, -1)
		current_path.clear()

	return false


## Called by AIOpponent when the AI arrives at an uncompleted location.
## base_duration: the location's task duration_seconds before difficulty scaling.
func start_task(base_duration: float, loc_pos: Vector2i) -> void:
	var mult: float = Enums.AI_TASK_MULTIPLIER.get(difficulty, 1.0)
	task_timer = base_duration * mult
	state = State.DO_TASK
	current_path.clear()
	_current_task_pos = loc_pos


## Called by AIOpponent when task_timer has reached zero.
func on_task_complete() -> void:
	var got_item := (_current_task_pos == _item_loc_pos and _item_loc_pos != Vector2i(-1, -1))

	var idx := known_uncompleted_locs.find(_current_task_pos)
	if idx >= 0:
		known_uncompleted_locs.remove_at(idx)

	_current_task_pos = Vector2i(-1, -1)
	current_path.clear()

	if got_item:
		has_item = true
		state = State.GO_TO_EXIT
	elif not known_uncompleted_locs.is_empty():
		state = State.GO_TO_LOC
	else:
		state = State.EXPLORE


## Returns the next cell the AI should move toward, or Vector2i(-1,-1) if none.
func get_next_step() -> Vector2i:
	if current_path.is_empty():
		return Vector2i(-1, -1)
	return current_path[0]


func is_doing_task() -> bool:
	return state == State.DO_TASK


func is_resting() -> bool:
	return state == State.RESTING


## Called when another entity completes a location. Removes it from known list
## and invalidates current path if we were heading there.
func on_location_completed_externally(loc_pos: Vector2i) -> void:
	var idx := known_uncompleted_locs.find(loc_pos)
	if idx >= 0:
		known_uncompleted_locs.remove_at(idx)

	if _current_target == loc_pos:
		_current_target = Vector2i(-1, -1)
		current_path.clear()


# --- Private helpers ---

func _plan_next_path(from: Vector2i, maze_data: MazeData) -> void:
	var target := Vector2i(-1, -1)
	match state:
		State.GO_TO_LOC:
			target = _get_best_location_target(from)
			if target == Vector2i(-1, -1):
				state = State.EXPLORE
				target = _pick_explore_target(from, maze_data)
		State.GO_TO_EXIT:
			if exit_known:
				target = exit_pos
			else:
				state = State.EXPLORE
				target = _pick_explore_target(from, maze_data)
		State.EXPLORE:
			target = _pick_explore_target(from, maze_data)

	if target == Vector2i(-1, -1):
		return

	var path := _pathfinder.find_path(maze_data, from, target)
	if path.size() > 1:
		path.pop_front()  # Remove start cell — already there.
		current_path = path
		_current_target = target
	elif path.size() == 1:
		# Already at target; let tick handle the state.
		current_path.clear()
		_current_target = Vector2i(-1, -1)


## Returns the best known uncompleted location to target.
## Hard AI always prioritises its own item location.
func _get_best_location_target(from: Vector2i) -> Vector2i:
	if known_uncompleted_locs.is_empty():
		return Vector2i(-1, -1)
	if difficulty == Enums.Difficulty.HARD and known_uncompleted_locs.has(_item_loc_pos):
		return _item_loc_pos
	return _nearest_cell(from, known_uncompleted_locs)


## Returns an unexplored frontier cell to explore toward.
func _pick_explore_target(from: Vector2i, maze_data: MazeData) -> Vector2i:
	# Frontier: cells reachable via open passages from explored territory, not yet visited.
	var frontier: Array[Vector2i] = []
	for cell in explored:
		for nb in _pathfinder.get_passable_neighbors(maze_data, cell):
			if not explored.has(nb) and not frontier.has(nb):
				frontier.append(nb)

	if frontier.is_empty():
		# Fallback: any unvisited cell in the maze.
		for row in maze_data.height:
			for col in maze_data.width:
				var pos := Vector2i(col, row)
				if not explored.has(pos):
					return pos
		return Vector2i(-1, -1)

	match difficulty:
		Enums.Difficulty.EASY:
			return frontier[_rng.randi() % frontier.size()]
		Enums.Difficulty.MEDIUM:
			if _rng.randf() < 0.7:
				return _nearest_cell(from, frontier)
			return frontier[_rng.randi() % frontier.size()]
		Enums.Difficulty.HARD:
			# Bias toward frontier cell closest to item location / exit.
			if not known_uncompleted_locs.is_empty():
				var bias := _get_best_location_target(from)
				if bias != Vector2i(-1, -1):
					return _nearest_to_target(bias, frontier)
			elif exit_known:
				return _nearest_to_target(exit_pos, frontier)
			return _nearest_cell(from, frontier)

	return frontier[0]


func _nearest_cell(from: Vector2i, cells: Array) -> Vector2i:
	var best := Vector2i(-1, -1)
	var best_d := INF
	for c in cells:
		var d := float(abs(c.x - from.x) + abs(c.y - from.y))
		if d < best_d:
			best_d = d
			best = c
	return best


func _nearest_to_target(target: Vector2i, cells: Array) -> Vector2i:
	var best := Vector2i(-1, -1)
	var best_d := INF
	for c in cells:
		var d := float(abs(c.x - target.x) + abs(c.y - target.y))
		if d < best_d:
			best_d = d
			best = c
	return best
