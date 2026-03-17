class_name CustomContentManager
extends RefCounted

const CUSTOM_DIR: String = "user://custom/"
const TASKS_PATH: String = "user://custom/tasks.json"
const ITEMS_PATH: String = "user://custom/items.json"
const PENALTIES_PATH: String = "user://custom/penalties.json"
const MEDIA_DIR: String = "user://custom/media/"
const ICONS_DIR: String = "user://custom/icons/"

const MAX_TITLE_LENGTH: int = 100
const MAX_DESCRIPTION_LENGTH: int = 500
const MIN_DURATION: float = 5.0
const MAX_DURATION: float = 300.0
const MAX_MEDIA_SIZE_BYTES: int = 10 * 1024 * 1024  # 10 MB
const VALID_MEDIA_EXTENSIONS: Array = ["gif", "mp4", "webm"]
const VALID_ICON_EXTENSIONS: Array = ["png", "jpg", "jpeg"]
const MAX_REPS: int = 999
const MIN_REPS: int = 1


func _init() -> void:
	DirAccess.make_dir_recursive_absolute(CUSTOM_DIR)
	DirAccess.make_dir_recursive_absolute(MEDIA_DIR)
	DirAccess.make_dir_recursive_absolute(ICONS_DIR)


# ========================
# CUSTOM TASKS
# ========================

## Returns all custom tasks as an Array of Dictionaries.
func get_custom_tasks() -> Array:
	return _load_json_array(TASKS_PATH, "tasks")


## Add a custom task. Returns "" on success, or an error message string.
func add_custom_task(title: String, description: String, duration: float, media_path: String = "") -> String:
	var err := validate_task(title, description, duration, media_path)
	if err != "":
		return err

	var tasks := get_custom_tasks()
	var id := "custom_task_%d" % (Time.get_unix_time_from_system() * 1000 + tasks.size())
	var entry := {
		"id": id,
		"title": title,
		"description": description,
		"duration_seconds": duration,
		"media_path": media_path,
	}
	tasks.append(entry)
	_save_json_array(TASKS_PATH, "tasks", tasks)
	return ""


## Update an existing custom task by id. Returns "" on success, or error message.
func update_custom_task(id: String, title: String, description: String, duration: float, media_path: String = "") -> String:
	var err := validate_task(title, description, duration, media_path)
	if err != "":
		return err

	var tasks := get_custom_tasks()
	for i in tasks.size():
		if tasks[i].get("id", "") == id:
			tasks[i]["title"] = title
			tasks[i]["description"] = description
			tasks[i]["duration_seconds"] = duration
			tasks[i]["media_path"] = media_path
			_save_json_array(TASKS_PATH, "tasks", tasks)
			return ""
	return "Task not found"


## Remove a custom task by id.
func remove_custom_task(id: String) -> bool:
	var tasks := get_custom_tasks()
	for i in tasks.size():
		if tasks[i].get("id", "") == id:
			tasks.remove_at(i)
			_save_json_array(TASKS_PATH, "tasks", tasks)
			return true
	return false


## Validate task fields. Returns "" if valid, or an error message.
func validate_task(title: String, description: String, duration: float, media_path: String = "") -> String:
	if title.strip_edges().is_empty():
		return "Title is required"
	if title.length() > MAX_TITLE_LENGTH:
		return "Title must be %d characters or less" % MAX_TITLE_LENGTH
	if description.strip_edges().is_empty():
		return "Description is required"
	if description.length() > MAX_DESCRIPTION_LENGTH:
		return "Description must be %d characters or less" % MAX_DESCRIPTION_LENGTH
	if duration < MIN_DURATION:
		return "Duration must be at least %.0f seconds" % MIN_DURATION
	if duration > MAX_DURATION:
		return "Duration must be at most %.0f seconds" % MAX_DURATION
	if media_path != "":
		var ext := media_path.get_extension().to_lower()
		if ext not in VALID_MEDIA_EXTENSIONS:
			return "Media must be gif, mp4, or webm"
	return ""


## Validate a media file path for size. Returns "" if valid, or error message.
func validate_media_file(path: String) -> String:
	if not FileAccess.file_exists(path):
		return "File not found"
	var ext := path.get_extension().to_lower()
	if ext not in VALID_MEDIA_EXTENSIONS:
		return "Unsupported format (use gif, mp4, or webm)"
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return "Cannot read file"
	var size := file.get_length()
	file.close()
	if size > MAX_MEDIA_SIZE_BYTES:
		return "File too large (max 10 MB)"
	return ""


# ========================
# CUSTOM ITEMS
# ========================

## Returns all custom items as an Array of Dictionaries.
func get_custom_items() -> Array:
	return _load_json_array(ITEMS_PATH, "items")


## Add a custom item. Returns "" on success, or error message.
func add_custom_item(item_name: String, icon_path: String = "") -> String:
	var err := validate_item(item_name, icon_path)
	if err != "":
		return err

	var items := get_custom_items()
	# Generate id from name (lowercase, underscores)
	var id := "custom_" + item_name.to_lower().replace(" ", "_")
	# Ensure unique
	var base_id := id
	var counter := 1
	while _array_has_id(items, id):
		id = base_id + "_" + str(counter)
		counter += 1

	var entry := {
		"id": id,
		"name": item_name,
		"icon_path": icon_path,
	}
	items.append(entry)
	_save_json_array(ITEMS_PATH, "items", items)
	return ""


## Update an existing custom item by id.
func update_custom_item(id: String, item_name: String, icon_path: String = "") -> String:
	var err := validate_item(item_name, icon_path)
	if err != "":
		return err

	var items := get_custom_items()
	for i in items.size():
		if items[i].get("id", "") == id:
			items[i]["name"] = item_name
			items[i]["icon_path"] = icon_path
			_save_json_array(ITEMS_PATH, "items", items)
			return ""
	return "Item not found"


## Remove a custom item by id.
func remove_custom_item(id: String) -> bool:
	var items := get_custom_items()
	for i in items.size():
		if items[i].get("id", "") == id:
			items.remove_at(i)
			_save_json_array(ITEMS_PATH, "items", items)
			return true
	return false


## Validate item fields. Returns "" if valid, or error message.
func validate_item(item_name: String, icon_path: String = "") -> String:
	if item_name.strip_edges().is_empty():
		return "Name is required"
	if item_name.length() > MAX_TITLE_LENGTH:
		return "Name must be %d characters or less" % MAX_TITLE_LENGTH
	if icon_path != "":
		var ext := icon_path.get_extension().to_lower()
		if ext not in VALID_ICON_EXTENSIONS:
			return "Icon must be png or jpg"
	return ""


## Validate an icon file. Returns "" if valid, or error message.
func validate_icon_file(path: String) -> String:
	if not FileAccess.file_exists(path):
		return "File not found"
	var ext := path.get_extension().to_lower()
	if ext not in VALID_ICON_EXTENSIONS:
		return "Unsupported format (use png or jpg)"
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return "Cannot read file"
	var size := file.get_length()
	file.close()
	if size > MAX_MEDIA_SIZE_BYTES:
		return "File too large (max 10 MB)"
	return ""


# ========================
# CUSTOM CLASH PENALTIES
# ========================

## Returns all custom penalties as an Array of Dictionaries.
func get_custom_penalties() -> Array:
	return _load_json_array(PENALTIES_PATH, "penalties")


## Add a custom penalty. Returns "" on success, or error message.
func add_custom_penalty(exercise: String, reps: int, media_path: String = "") -> String:
	var err := validate_penalty(exercise, reps, media_path)
	if err != "":
		return err

	var penalties := get_custom_penalties()
	var id := "custom_penalty_%d" % (Time.get_unix_time_from_system() * 1000 + penalties.size())
	var entry := {
		"id": id,
		"exercise": exercise,
		"reps": reps,
		"media_path": media_path,
	}
	penalties.append(entry)
	_save_json_array(PENALTIES_PATH, "penalties", penalties)
	return ""


## Update an existing custom penalty by id.
func update_custom_penalty(id: String, exercise: String, reps: int, media_path: String = "") -> String:
	var err := validate_penalty(exercise, reps, media_path)
	if err != "":
		return err

	var penalties := get_custom_penalties()
	for i in penalties.size():
		if penalties[i].get("id", "") == id:
			penalties[i]["exercise"] = exercise
			penalties[i]["reps"] = reps
			penalties[i]["media_path"] = media_path
			_save_json_array(PENALTIES_PATH, "penalties", penalties)
			return ""
	return "Penalty not found"


## Remove a custom penalty by id.
func remove_custom_penalty(id: String) -> bool:
	var penalties := get_custom_penalties()
	for i in penalties.size():
		if penalties[i].get("id", "") == id:
			penalties.remove_at(i)
			_save_json_array(PENALTIES_PATH, "penalties", penalties)
			return true
	return false


## Validate penalty fields. Returns "" if valid, or error message.
func validate_penalty(exercise: String, reps: int, media_path: String = "") -> String:
	if exercise.strip_edges().is_empty():
		return "Exercise name is required"
	if exercise.length() > MAX_TITLE_LENGTH:
		return "Exercise name must be %d characters or less" % MAX_TITLE_LENGTH
	if reps < MIN_REPS:
		return "Reps must be at least %d" % MIN_REPS
	if reps > MAX_REPS:
		return "Reps must be at most %d" % MAX_REPS
	if media_path != "":
		var ext := media_path.get_extension().to_lower()
		if ext not in VALID_MEDIA_EXTENSIONS:
			return "Media must be gif, mp4, or webm"
	return ""


# ========================
# HELPERS
# ========================

func _load_json_array(path: String, key: String) -> Array:
	if not FileAccess.file_exists(path):
		return []
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return []
	var content := file.get_as_text()
	file.close()
	if content.is_empty():
		return []
	var json := JSON.new()
	if json.parse(content) != OK:
		return []
	var data = json.data
	if not data is Dictionary:
		return []
	var arr = data.get(key, [])
	if not arr is Array:
		return []
	return arr


func _save_json_array(path: String, key: String, arr: Array) -> void:
	var data := {key: arr}
	var json_string := JSON.stringify(data, "\t")
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("CustomContentManager: could not write to %s" % path)
		return
	file.store_string(json_string)
	file.close()


func _array_has_id(arr: Array, id: String) -> bool:
	for entry in arr:
		if entry is Dictionary and entry.get("id", "") == id:
			return true
	return false
