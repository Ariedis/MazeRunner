class_name TaskLoader
extends RefCounted


func load_default_tasks() -> Array[TaskData]:
	var tasks: Array[TaskData] = []

	var t1 := TaskData.new()
	t1.title = "Plank"
	t1.description = "Hold a plank position"
	t1.duration_seconds = 30.0
	tasks.append(t1)

	var t2 := TaskData.new()
	t2.title = "Push-ups"
	t2.description = "Do 10 push-ups"
	t2.duration_seconds = 20.0
	tasks.append(t2)

	var t3 := TaskData.new()
	t3.title = "Jumping Jacks"
	t3.description = "Do 20 jumping jacks"
	t3.duration_seconds = 15.0
	tasks.append(t3)

	var t4 := TaskData.new()
	t4.title = "Wall Sit"
	t4.description = "Hold a wall sit for 20 seconds"
	t4.duration_seconds = 20.0
	tasks.append(t4)

	var t5 := TaskData.new()
	t5.title = "Squats"
	t5.description = "Do 15 squats"
	t5.duration_seconds = 20.0
	tasks.append(t5)

	return tasks


func load_user_tasks() -> Array[TaskData]:
	var tasks: Array[TaskData] = []

	# Load from legacy individual JSON files in user://tasks/
	var dir := DirAccess.open("user://tasks/")
	if dir != null:
		dir.list_dir_begin()
		var file_name := dir.get_next()
		while file_name != "":
			if not dir.current_is_dir() and file_name.ends_with(".json"):
				var full_path := "user://tasks/" + file_name
				var file := FileAccess.open(full_path, FileAccess.READ)
				if file != null:
					var json_text := file.get_as_text()
					file.close()
					var task := _parse_task_json(json_text)
					if task != null:
						tasks.append(task)
			file_name = dir.get_next()

	# Load from custom content manifest (Phase 11)
	var mgr := CustomContentManager.new()
	var custom := mgr.get_custom_tasks()
	for entry in custom:
		var task := TaskData.new()
		task.title = str(entry.get("title", ""))
		task.description = str(entry.get("description", ""))
		task.duration_seconds = float(entry.get("duration_seconds", 30.0))
		task.media_path = str(entry.get("media_path", ""))
		if task.title != "" and task.duration_seconds > 0.0:
			tasks.append(task)

	return tasks


func load_all_tasks() -> Array[TaskData]:
	var result: Array[TaskData] = load_default_tasks()
	result.append_array(load_user_tasks())
	return result


func _parse_task_json(json_text: String) -> TaskData:
	var json := JSON.new()
	var err := json.parse(json_text)
	if err != OK:
		return null
	var data = json.data
	if not data is Dictionary:
		return null
	if not data.has("title") or not data.has("description") or not data.has("duration_seconds"):
		return null
	var task := TaskData.new()
	task.title = str(data["title"])
	task.description = str(data["description"])
	task.duration_seconds = float(data["duration_seconds"])
	task.media_path = str(data.get("media_path", ""))
	return task
