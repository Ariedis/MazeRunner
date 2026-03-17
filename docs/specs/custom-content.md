# Feature Spec: Custom Content (Tasks, Items, Clash Penalties)

## Status: IMPLEMENTED

## Overview
Players can add custom tasks, items, and clash penalty tasks via the Settings screen. Custom content is stored in the user data directory and loaded alongside defaults.

## Architecture

### SettingsManager (Autoload)
- Registered in `project.godot` as the 7th autoload
- Manages display settings: resolution (5 options), fullscreen toggle
- Manages sound settings: master/music/sfx volume (placeholder — no audio system yet)
- Persistence: `user://settings.json`
- `apply_settings()` applies resolution and fullscreen to DisplayServer
- `reset_to_defaults()` restores all settings

### CustomContentManager (RefCounted)
- Handles CRUD for custom tasks, items, and penalties
- Validates all fields (title length, description length, duration range, media extensions, reps range)
- Persistence: JSON manifests in `user://custom/` directory
- Each content type has `get_*()`, `add_*()`, `update_*()`, `remove_*()`, and `validate_*()` methods

### SettingsScreen
- Code-driven UI with TabContainer: Display, Custom Tasks, Custom Items, Clash Penalties
- Editor overlay dialogs for add/edit operations
- Accessible from Main Menu Settings button
- Uses `SceneManager.go_to_settings()` for navigation

## Custom Tasks
### Data Format
```json
{
  "tasks": [
    {
      "id": "custom_task_1742000000000",
      "title": "Dance Break",
      "description": "Do your best dance move for 15 seconds",
      "duration_seconds": 15.0,
      "media_path": "dance_break.gif"
    }
  ]
}
```

### Storage
- JSON manifest: `user://custom/tasks.json`
- Media files: `user://custom/media/`

### Validation
- Title: required, max 100 chars
- Description: required, max 500 chars
- Media: must be gif/mp4/webm if provided, max 10MB
- Duration: minimum 5 seconds, maximum 300 seconds

### Integration
- `TaskLoader.load_user_tasks()` reads from the custom manifest
- Custom tasks appear in the location task pool alongside defaults

## Custom Items
### Data Format
```json
{
  "items": [
    {
      "id": "custom_rubber_duck",
      "name": "Rubber Duck",
      "icon_path": "rubber_duck.png"
    }
  ]
}
```

### Storage
- JSON manifest: `user://custom/items.json`
- Icon files: `user://custom/icons/`

### Validation
- Name: required, max 100 chars
- Icon: must be png/jpg if provided

### Integration
- `ItemRegistry._load_custom_items()` reads from the manifest on init
- Custom items appear in the New Game item selector

## Custom Clash Penalties
### Data Format
```json
{
  "penalties": [
    {
      "id": "custom_penalty_1742000000000",
      "exercise": "Star Jumps",
      "reps": 15
    }
  ]
}
```

### Storage
- JSON manifest: `user://custom/penalties.json`

### Validation
- Exercise name: required, max 100 chars
- Reps: 1-999

### Integration
- `ClashTaskLoader.load_active_task()` picks a random custom penalty if available
- Falls back to legacy `user://clash_tasks.json`, then to default (Bicep Curls x10)

## Content Management UI
- TabContainer in SettingsScreen with tabs for each content type
- List view showing all custom content with Edit and Delete buttons per entry
- Add button at top of each list
- Editor overlay dialog with validation and error display
- Deleting content: removed from pool, defaults always available

## Files
- `scripts/settings/SettingsManager.gd` — Autoload for display/sound settings
- `scripts/settings/CustomContentManager.gd` — CRUD for custom tasks, items, penalties
- `scenes/menus/SettingsScreen.gd` — Code-driven settings UI with tabs
- `scenes/menus/SettingsScreen.tscn` — Settings screen scene
- `tests/test_settings_system.gd` — Tests for settings and custom content

## Testing Criteria
- [x] Custom task with gif displays correctly in game
- [x] Custom task with mp4/webm plays correctly
- [x] Custom item appears in New Game item selector
- [x] Custom penalty triggers in clash with correct data
- [x] Invalid files rejected with clear error messages
- [x] Edited content updates in game
- [x] Deleted content removed from pool
- [x] Saves referencing deleted content don't crash
- [x] File size limits enforced
