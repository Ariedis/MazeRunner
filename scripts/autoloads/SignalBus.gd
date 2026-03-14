extends Node

# Phase 1: Scene and state signals
signal scene_change_requested(scene_path: String)
signal scene_changed(new_scene_path: String)
signal scene_transition_started(target_path: String)
signal game_state_changed(old_state: int, new_state: int)
signal game_config_changed()

# Phase 3+ stubs
signal player_energy_changed(new_value: float)
signal player_size_changed(new_value: int)
signal player_item_collected()
signal location_completed(location_id: int, completed_by: String)
signal match_ended(result: String)
