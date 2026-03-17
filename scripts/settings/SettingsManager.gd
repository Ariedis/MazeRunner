extends Node

const SETTINGS_PATH: String = "user://settings.json"

const DEFAULT_SETTINGS: Dictionary = {
	"resolution": 2,          # Index into RESOLUTIONS array
	"fullscreen": false,
	"master_volume": 80,      # 0-100 (placeholder — no audio system yet)
	"music_volume": 70,       # 0-100 (placeholder)
	"sfx_volume": 90,         # 0-100 (placeholder)
}

const RESOLUTIONS: Array = [
	Vector2i(800, 600),
	Vector2i(1024, 768),
	Vector2i(1280, 720),
	Vector2i(1600, 900),
	Vector2i(1920, 1080),
]

const RESOLUTION_LABELS: Array = [
	"800x600",
	"1024x768",
	"1280x720",
	"1600x900",
	"1920x1080",
]

var _settings: Dictionary = {}


func _ready() -> void:
	_settings = DEFAULT_SETTINGS.duplicate(true)
	load_settings()
	apply_settings()


## Returns the current value for a given key.
func get_setting(key: String) -> Variant:
	return _settings.get(key, DEFAULT_SETTINGS.get(key))


## Sets a value and persists to disk.
func set_setting(key: String, value: Variant) -> void:
	_settings[key] = value


## Returns the full settings dictionary (copy).
func get_all_settings() -> Dictionary:
	return _settings.duplicate(true)


## Apply display settings to the window.
func apply_settings() -> void:
	# Skip window manipulation when running embedded inside the Godot editor.
	if OS.has_feature("editor"):
		return
	var fullscreen: bool = _settings.get("fullscreen", false)
	if fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		var res_idx: int = _settings.get("resolution", 2)
		res_idx = clampi(res_idx, 0, RESOLUTIONS.size() - 1)
		var res: Vector2i = RESOLUTIONS[res_idx]
		DisplayServer.window_set_size(res)
		# Center window on screen
		var screen_size := DisplayServer.screen_get_size()
		var win_pos := Vector2i((screen_size.x - res.x) / 2, (screen_size.y - res.y) / 2)
		DisplayServer.window_set_position(win_pos)


## Save settings to user data directory.
func save_settings() -> void:
	var json_string := JSON.stringify(_settings, "\t")
	var file := FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)
	if file == null:
		push_error("SettingsManager: could not write settings file")
		return
	file.store_string(json_string)
	file.close()


## Load settings from user data directory. Missing keys get defaults.
func load_settings() -> void:
	if not FileAccess.file_exists(SETTINGS_PATH):
		return

	var file := FileAccess.open(SETTINGS_PATH, FileAccess.READ)
	if file == null:
		return

	var content := file.get_as_text()
	file.close()

	var json := JSON.new()
	if json.parse(content) != OK:
		push_warning("SettingsManager: corrupt settings file, using defaults")
		return

	var data = json.data
	if not data is Dictionary:
		return

	# Merge loaded values over defaults (so new keys get defaults)
	for key in DEFAULT_SETTINGS:
		if data.has(key):
			_settings[key] = data[key]


## Reset all settings to defaults, apply, and save.
func reset_to_defaults() -> void:
	_settings = DEFAULT_SETTINGS.duplicate(true)
	apply_settings()
	save_settings()
