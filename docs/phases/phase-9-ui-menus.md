# Phase 9: UI & Menus

## Status: COMPLETE

## Goal
Implement all game screens: Main Menu, New Game, Game HUD, and supporting UI overlays.

## Tasks

### Main Menu
- [x] Layout with buttons: New Game, Continue, Load Game, Settings, Quit
- [x] Continue button greyed out if no save exists
- [x] Quit exits application
- [x] Menu theme/styling

### New Game Screen
- [x] Map Size selector (Small / Medium / Large)
- [x] Character Creator:
  - Avatar/portrait selection or customization
  - Stat allocation (Size starting value, within allowed range)
- [x] Number of Opponents selector
- [x] AI Difficulty selector (per-AI dropdown)
- [x] Item Selector (pick from list, custom items available from settings)
- [x] Start Game button — validates config and launches game

### Game HUD
- [x] Top-left: player avatar portrait
- [x] Below portrait: Size, Speed, Energy stats (energy as bar)
- [x] Top-right of portrait: item collected indicator (hidden until collected)
- [x] Pause menu overlay (Resume, Save, Quit to Menu)

### Overlays
- [x] Task overlay (from Phase 5 — integrated via existing CanvasLayer system)
- [x] Clash overlay (from Phase 8 — integrated via existing CanvasLayer system)
- [x] Win/Loss screen (from Phase 6 — integrated via existing CanvasLayer system)

## Dependencies
- Phase 1 (scene management)
- Phases 3, 5, 6, 8 (game systems feeding into HUD/overlays)

## Key Specs
- [Main Menu](../specs/main-menu.md)
- [HUD](../specs/hud.md)
- [Character Creator](../specs/character-creator.md)

## Deliverables
- All menu screens navigable
- Game HUD displays live stats
- Overlays integrate with game systems
- Character creator functional

## Testing Criteria
- [x] All main menu buttons navigate to correct screens
- [x] Continue button disabled when no save exists
- [x] New Game screen validates all options before starting
- [x] Character creator stat allocation works within bounds
- [x] HUD updates energy, size, speed in real-time
- [x] Item indicator appears on collection
- [x] Pause menu works mid-game
- [x] All overlays display and dismiss correctly
- [x] UI scales correctly at different resolutions

---

## Implementation Notes

### New Files

| File | Type | Purpose |
|------|------|---------|
| `scripts/ui/CharacterCreatorLogic.gd` | `class_name CharacterCreatorLogic` | Pure-logic class managing size stat allocation with budget constraints. Holds `size`, `points_spent`, `points_remaining`. Methods: `increase_size() -> bool`, `decrease_size() -> bool`, `reset()`. |
| `scripts/ui/NewGameConfig.gd` | `class_name NewGameConfig` | Static validator for game config dictionaries. `validate(config) -> bool` checks item selected, opponent count in range, difficulty array length matches, map size valid. `get_max_opponents(map_size) -> int` returns cap from `Enums.MAP_SIZE_DATA`. |
| `scenes/menus/NewGameScreen.gd/.tscn` | `extends Control` | Full new game setup screen built entirely in code. Sections: map size toggle buttons, avatar selector (5 coloured buttons), size +/- with points counter, opponent count +/- with dynamic per-opponent difficulty dropdowns, item OptionButton, validation error label, Back/Start Game buttons. Writes to `GameState.config` and `GameState.player` on start. |
| `scenes/game/GameHUD.gd` | `class_name GameHUD extends CanvasLayer` | In-game HUD at z=5. Portrait (64×64 ColorRect, colour per avatar), item indicator (20×20 star overlay, hidden until collected), Size label, Speed label (green/red), energy bar (ColorRect that resizes and recolours green→yellow→red). `setup(avatar_id)`, `update_size()`, `update_energy()`, `update_speed()`, `show_item_collected()`, `show_rejection_message()`. |
| `scenes/game/PauseMenu.gd` | `class_name PauseMenu extends CanvasLayer` | Pause overlay at z=10. Semi-transparent backdrop + centred panel with Resume, Save Game (stub), Quit to Menu buttons. Signals: `resume_requested`, `save_requested`, `quit_to_menu_requested`. `show_menu()` / `hide_menu()`. |
| `tests/test_ui.gd` | `extends TestBase` | 40 unit tests covering `CharacterCreatorLogic` allocation logic, `NewGameConfig.validate` boundary cases, `NewGameConfig.get_max_opponents`, `GameState` stubs, and `GameHUD` instantiation/update methods. |

### Modified Files

| File | Changes |
|------|---------|
| `scenes/menus/MainMenu.gd/.tscn` | Replaced placeholder buttons with proper layout: New Game → `go_to_new_game_screen()`, Continue (reads `GameState.has_save_data()`), Load Game (disabled, Phase 10), Settings (disabled, Phase 11), Quit. |
| `scripts/autoloads/SceneManager.gd` | Added `SCENE_NEW_GAME_SCREEN` constant and `go_to_new_game_screen()` method. |
| `scripts/autoloads/GameState.gd` | `item_id` default changed from `-1` (int) to `""` (String). `avatar_id` key added to `config`. `reset_for_new_game()` now preserves `avatar_id` from config. Added `has_save_data() -> bool` stub (returns false; Phase 10 will check the filesystem). |
| `scenes/game/GameScene.gd` | Removed all `$UI/Label*` and `$UI/BtnMainMenu` references. Instantiates `GameHUD` and `PauseMenu` in `_ready()`. Added `_unhandled_input()` for Escape key pause toggle (blocked while task/clash overlays are active). `_on_player_energy_changed`, `_on_player_item_collected`, `_on_task_completed` updated to call `_hud.*` methods. |
| `scenes/game/GameScene.tscn` | Removed the old `UI` CanvasLayer with debug labels — `GameHUD` is now fully code-driven. |
| `tests/scenes/TestRunnerScene.gd` | Added `test_ui.gd` to the test suite. |

### Phase 10 Stubs Left in Place
- `GameState.has_save_data()` returns `false` — Phase 10 will check `user://` for save files.
- `PauseMenu` "Save Game" button emits `save_requested` but `GameScene._on_pause_save()` is a no-op — Phase 10 will wire in the save system.
- Main Menu "Continue" and "Load Game" buttons are disabled pending Phase 10.
