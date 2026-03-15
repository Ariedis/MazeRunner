class_name FogOfWar
extends RefCounted

var explored: Dictionary = {}
var reveal_radius: int = 2


func reveal(center: Vector2i, maze_width: int, maze_height: int) -> Array[Vector2i]:
	var newly_revealed: Array[Vector2i] = []
	for dy in range(-reveal_radius, reveal_radius + 1):
		for dx in range(-reveal_radius, reveal_radius + 1):
			var cell := Vector2i(center.x + dx, center.y + dy)
			if cell.x < 0 or cell.x >= maze_width:
				continue
			if cell.y < 0 or cell.y >= maze_height:
				continue
			if explored.has(cell):
				continue
			explored[cell] = true
			newly_revealed.append(cell)
	return newly_revealed


func is_explored(pos: Vector2i) -> bool:
	return explored.has(pos)


func get_explored_array() -> Array:
	return explored.keys()


func load_from_array(cells: Array) -> void:
	explored.clear()
	for cell in cells:
		explored[cell] = true
