class_name LocationManager
extends RefCounted

var locations: Array[LocationData] = []


func setup(maze_data: MazeData, tasks: Array[TaskData], rng: RandomNumberGenerator) -> void:
	locations.clear()
	for i in maze_data.locations.size():
		var loc := LocationData.new()
		loc.id = i
		loc.grid_pos = maze_data.locations[i]
		locations.append(loc)

	# Shuffle with rng
	for i in range(locations.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp := locations[i]
		locations[i] = locations[j]
		locations[j] = tmp

	# Assign item types: first gets PLAYER_ITEM, rest get SIZE_INCREASER
	for i in locations.size():
		if i == 0:
			locations[i].item_type = Enums.ItemType.PLAYER_ITEM
		else:
			locations[i].item_type = Enums.ItemType.SIZE_INCREASER

	# Assign random tasks
	if tasks.size() == 0:
		return
	for loc in locations:
		loc.task = tasks[rng.randi_range(0, tasks.size() - 1)]


func get_location_at(grid_pos: Vector2i) -> LocationData:
	for loc in locations:
		if loc.grid_pos == grid_pos:
			return loc
	return null


func get_location_by_id(id: int) -> LocationData:
	for loc in locations:
		if loc.id == id:
			return loc
	return null


func has_uncompleted_at(grid_pos: Vector2i) -> bool:
	var loc := get_location_at(grid_pos)
	return loc != null and not loc.completed


func complete_location(id: int, completer: String = "player") -> void:
	var loc := get_location_by_id(id)
	if loc == null:
		return
	loc.completed = true
	loc.completed_by.append(completer)


func get_completed_count() -> int:
	var count := 0
	for loc in locations:
		if loc.completed:
			count += 1
	return count
