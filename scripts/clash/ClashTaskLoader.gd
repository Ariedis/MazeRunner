class_name ClashTaskLoader
extends RefCounted

## Default penalty task applied when no custom task is configured.
const DEFAULT_TASK: Dictionary = {
	"exercise": "Bicep Curls",
	"reps": 10,
}

## Path in the user data directory for a custom clash penalty task.
const USER_TASK_PATH: String = "user://clash_tasks.json"


## Returns the active penalty task as a Dictionary { "exercise": String, "reps": int }.
## Loads from user://clash_tasks.json if it exists and is valid; otherwise returns default.
static func load_active_task() -> Dictionary:
	if FileAccess.file_exists(USER_TASK_PATH):
		var file := FileAccess.open(USER_TASK_PATH, FileAccess.READ)
		if file != null:
			var text := file.get_as_text()
			file.close()
			var parsed = JSON.parse_string(text)
			if parsed is Dictionary and parsed.has("exercise") and parsed.has("reps"):
				return {
					"exercise": str(parsed["exercise"]),
					"reps": int(parsed["reps"]),
				}
	return DEFAULT_TASK.duplicate()
