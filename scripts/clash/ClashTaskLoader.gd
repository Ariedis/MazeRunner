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
## If category is provided, only penalties matching that category (or with no category) are used.
static func load_active_task(category: String = "") -> Dictionary:
	# Phase 11: load from custom content manifest
	var mgr := CustomContentManager.new()
	var penalties := mgr.get_custom_penalties()
	if not penalties.is_empty():
		var filtered: Array = []
		if category != "":
			for p in penalties:
				var cat: String = str(p.get("category", ""))
				if cat == category or cat == "":
					filtered.append(p)
			# Fall back to all penalties if none match
			if filtered.is_empty():
				filtered = penalties
		else:
			filtered = penalties

		var idx := randi() % filtered.size()
		var p: Dictionary = filtered[idx]
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
