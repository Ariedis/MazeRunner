class_name AStarPathfinder
extends RefCounted


## Finds shortest path from [from] to [to] through the maze.
## teleporter_pairs: optional dict of Vector2i->Vector2i for teleporter edges.
## forbidden: optional list of Vector2i cells to treat as impassable.
## Returns Array[Vector2i] including both endpoints. Returns [] if no path.
func find_path(maze_data: MazeData, from: Vector2i, to: Vector2i,
		teleporter_pairs: Dictionary = {}, forbidden: Array = []) -> Array[Vector2i]:
	if from == to:
		return [from]
	if not maze_data.is_valid(from.x, from.y) or not maze_data.is_valid(to.x, to.y):
		return []

	var came_from: Dictionary = {}  # Vector2i -> Vector2i
	var g_score: Dictionary = {}    # Vector2i -> float
	var closed: Dictionary = {}     # Vector2i -> true

	# Binary min-heap: each element is [f_score, Vector2i]
	var heap: Array = []

	g_score[from] = 0.0
	var f0 := _heuristic(from, to)
	_heap_push(heap, f0, from)

	while heap.size() > 0:
		var top: Array = _heap_pop(heap)
		var current: Vector2i = top[1]

		# Lazy deletion: skip if already closed.
		if closed.has(current):
			continue
		closed[current] = true

		if current == to:
			return _reconstruct_path(came_from, current)

		var neighbors := get_passable_neighbors(maze_data, current)
		# Add teleporter destination as a passable neighbor if available.
		if not teleporter_pairs.is_empty() and teleporter_pairs.has(current):
			var tele_dest: Vector2i = teleporter_pairs[current]
			if not neighbors.has(tele_dest):
				neighbors.append(tele_dest)

		for neighbor in neighbors:
			if closed.has(neighbor):
				continue
			if forbidden.has(neighbor):
				continue
			var tg: float = g_score.get(current, INF) + 1.0
			if tg < g_score.get(neighbor, INF):
				came_from[neighbor] = current
				g_score[neighbor] = tg
				var f: float = tg + _heuristic(neighbor, to)
				_heap_push(heap, f, neighbor)

	return []


## Returns all maze cells directly reachable from [cell] via open passages.
func get_passable_neighbors(maze_data: MazeData, cell: Vector2i) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	var c := maze_data.get_cell_v(cell)
	if c == null:
		return result
	if not c.walls.get("top", true) and cell.y > 0:
		result.append(Vector2i(cell.x, cell.y - 1))
	if not c.walls.get("right", true) and cell.x < maze_data.width - 1:
		result.append(Vector2i(cell.x + 1, cell.y))
	if not c.walls.get("bottom", true) and cell.y < maze_data.height - 1:
		result.append(Vector2i(cell.x, cell.y + 1))
	if not c.walls.get("left", true) and cell.x > 0:
		result.append(Vector2i(cell.x - 1, cell.y))
	return result


func _heuristic(a: Vector2i, b: Vector2i) -> float:
	return float(abs(a.x - b.x) + abs(a.y - b.y))


func _reconstruct_path(came_from: Dictionary, end: Vector2i) -> Array[Vector2i]:
	var path: Array[Vector2i] = []
	var current := end
	while came_from.has(current):
		path.push_front(current)
		current = came_from[current]
	path.push_front(current)  # add start cell
	return path


# --- Binary min-heap helpers ---
# Each element is [f_score: float, cell: Vector2i]

func _heap_push(heap: Array, f: float, cell: Vector2i) -> void:
	heap.append([f, cell])
	var i: int = heap.size() - 1
	while i > 0:
		var parent: int = (i - 1) / 2
		if heap[parent][0] > heap[i][0]:
			var tmp: Array = heap[parent]
			heap[parent] = heap[i]
			heap[i] = tmp
			i = parent
		else:
			break


func _heap_pop(heap: Array) -> Array:
	var top: Array = heap[0]
	var last: int = heap.size() - 1
	heap[0] = heap[last]
	heap.pop_back()
	var size: int = heap.size()
	var i: int = 0
	while true:
		var left: int = 2 * i + 1
		var right: int = 2 * i + 2
		var smallest: int = i
		if left < size and heap[left][0] < heap[smallest][0]:
			smallest = left
		if right < size and heap[right][0] < heap[smallest][0]:
			smallest = right
		if smallest != i:
			var tmp: Array = heap[i]
			heap[i] = heap[smallest]
			heap[smallest] = tmp
			i = smallest
		else:
			break
	return top
