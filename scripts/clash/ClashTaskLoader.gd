class_name ClashTaskLoader
extends RefCounted

## Default penalty task applied when no custom task is configured.
const DEFAULT_TASK: Dictionary = {
	"exercise": "Bicep Curls",
	"reps": 10,
	"media_path": "",
}

## Path in the user data directory for a custom clash penalty task.
const USER_TASK_PATH: String = "user://clash_tasks.json"


## Returns the active penalty task as a Dictionary { "exercise": String, "reps": int, "media_path": String }.
## Picks a random custom penalty if available; falls back to legacy user file;
## otherwise returns default.
static func load_active_task() -> Dictionary:
	# Phase 11: load from custom content manifest
	var mgr := CustomContentManager.new()
	var penalties := mgr.get_custom_penalties()
	if not penalties.is_empty():
		var idx := randi() % penalties.size()
		var p: Dictionary = penalties[idx]
		if p.has("exercise") and p.has("reps"):
			return {
				"exercise": str(p["exercise"]),
				"reps": int(p["reps"]),
				"media_path": str(p.get("media_path", "")),
			}

	# Legacy: single custom task file
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
					"media_path": str(parsed.get("media_path", "")),
				}
	return DEFAULT_TASK.duplicate()
