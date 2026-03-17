class_name ContentPackLoader
extends RefCounted

## Loads a content pack JSON file and imports its tasks, penalties, items, and categories
## into the CustomContentManager.
##
## Expected JSON format:
## {
##   "categories": [
##     {"id": "yoga", "name": "Yoga"}
##   ],
##   "tasks": [
##     {"title": "...", "description": "...", "duration_seconds": 30, "category": "yoga", "media_path": ""}
##   ],
##   "penalties": [
##     {"exercise": "...", "reps": 10, "category": "yoga", "media_path": ""}
##   ],
##   "items": [
##     {"name": "...", "icon_path": ""}
##   ]
## }


## Result of loading a content pack.
class LoadResult extends RefCounted:
	var success: bool = false
	var error: String = ""
	var tasks_added: int = 0
	var penalties_added: int = 0
	var items_added: int = 0
	var categories_added: int = 0


## Load and import a content pack from the given file path.
## Returns a LoadResult with counts and any error.
static func load_pack(path: String) -> LoadResult:
	var result := LoadResult.new()

	if not FileAccess.file_exists(path):
		result.error = "File not found: %s" % path
		return result

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		result.error = "Cannot read file"
		return result

	var text := file.get_as_text()
	file.close()

	var json := JSON.new()
	if json.parse(text) != OK:
		result.error = "Invalid JSON: %s" % json.get_error_message()
		return result

	var data = json.data
	if not data is Dictionary:
		result.error = "JSON root must be an object"
		return result

	var mgr := CustomContentManager.new()

	# Import categories
	var categories = data.get("categories", [])
	if categories is Array:
		for cat in categories:
			if cat is Dictionary:
				var cat_id: String = str(cat.get("id", ""))
				var cat_name: String = str(cat.get("name", ""))
				if cat_id != "" and cat_name != "":
					var err := mgr.add_category(cat_id, cat_name)
					if err == "":
						result.categories_added += 1

	# Import tasks
	var tasks = data.get("tasks", [])
	if tasks is Array:
		for entry in tasks:
			if entry is Dictionary:
				var title: String = str(entry.get("title", ""))
				var description: String = str(entry.get("description", ""))
				var duration: float = float(entry.get("duration_seconds", 30.0))
				var media: String = str(entry.get("media_path", ""))
				var category: String = str(entry.get("category", ""))
				var err := mgr.add_custom_task(title, description, duration, media, category)
				if err == "":
					result.tasks_added += 1

	# Import penalties
	var penalties = data.get("penalties", [])
	if penalties is Array:
		for entry in penalties:
			if entry is Dictionary:
				var exercise: String = str(entry.get("exercise", ""))
				var reps: int = int(entry.get("reps", 10))
				var media: String = str(entry.get("media_path", ""))
				var category: String = str(entry.get("category", ""))
				var err := mgr.add_custom_penalty(exercise, reps, media, category)
				if err == "":
					result.penalties_added += 1

	# Import items
	var items = data.get("items", [])
	if items is Array:
		for entry in items:
			if entry is Dictionary:
				var item_name: String = str(entry.get("name", ""))
				var icon: String = str(entry.get("icon_path", ""))
				var err := mgr.add_custom_item(item_name, icon)
				if err == "":
					result.items_added += 1

	result.success = true
	return result
