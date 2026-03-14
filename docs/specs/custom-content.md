# Feature Spec: Custom Content (Tasks, Items, Clash Penalties)

## Overview
Players can add custom tasks, items, and clash penalty tasks via the Settings screen. Custom content is stored in the user data directory and loaded alongside defaults.

## Custom Tasks
### Data Format
```json
{
  "tasks": [
    {
      "id": "custom_task_001",
      "title": "Dance Break",
      "description": "Do your best dance move for 15 seconds",
      "media_file": "dance_break.gif",
      "duration_seconds": 15
    }
  ]
}
```

### Add Task UI
- Text field: Title
- Text area: Description
- File picker: Media (gif/mp4/webm)
- Number input: Duration (seconds)
- Preview button
- Save / Cancel

### Storage
- JSON manifest: `user://custom/tasks.json`
- Media files: `user://custom/media/`

### Validation
- Title: required, max 100 chars
- Description: required, max 500 chars
- Media: must be gif/mp4/webm, max 10MB
- Duration: minimum 5 seconds, maximum 300 seconds

## Custom Items
### Data Format
```json
{
  "items": [
    {
      "id": "custom_item_001",
      "name": "Rubber Duck",
      "icon_file": "rubber_duck.png"
    }
  ]
}
```

### Add Item UI
- Text field: Name
- File picker: Icon image (png/jpg, recommended 64x64 or 128x128)
- Preview
- Save / Cancel

### Storage
- JSON manifest: `user://custom/items.json`
- Icon files: `user://custom/icons/`

## Custom Clash Penalties
### Data Format
```json
{
  "penalties": [
    {
      "id": "custom_penalty_001",
      "exercise": "Star Jumps",
      "reps": 15,
      "weight_tiers": { "low": "bodyweight", "mid": "bodyweight", "high": "bodyweight" },
      "speed_descriptions": { "fast": "FAST!", "normal": "steady pace", "slow": "super slow" },
      "durations": { "fast": 12, "normal": 20, "slow": 35 }
    }
  ]
}
```

### Add Penalty UI
- Exercise name, reps, weight tier labels, speed descriptions, durations
- Save / Cancel

## Content Management
- List view showing all custom content (tasks, items, penalties)
- Edit and Delete buttons per entry
- Deleting content that exists in a save file: content removed from pool, saves using it still function (fallback to default)

## Testing Criteria
- [ ] Custom task with gif displays correctly in game
- [ ] Custom task with mp4/webm plays correctly
- [ ] Custom item appears in New Game item selector
- [ ] Custom penalty triggers in clash with correct scaling
- [ ] Invalid files rejected with clear error messages
- [ ] Edited content updates in game
- [ ] Deleted content removed from pool
- [ ] Saves referencing deleted content don't crash
- [ ] File size limits enforced
