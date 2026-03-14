extends TestBase

var _captured_old_state: int = -1
var _captured_new_state: int = -1


func _init() -> void:
	_test_name = "test_game_state"


func run_tests() -> void:
	_test_default_state()
	_test_state_write_persists()
	_test_state_change_emits_signal()
	_test_reset_for_new_game()
	_test_config_keys()
	_test_is_in_match()


func _test_default_state() -> void:
	# GameState starts as MENU (set in Main.gd / MainMenu.gd _ready, but default value is 0)
	assert_equal(Enums.GameState.MENU, 0, "default MENU value is 0")


func _test_state_write_persists() -> void:
	var original := GameState.current_state
	GameState.current_state = Enums.GameState.IN_GAME
	assert_equal(GameState.current_state, Enums.GameState.IN_GAME, "state write persists to IN_GAME")
	GameState.current_state = original


func _test_state_change_emits_signal() -> void:
	var callable := func(old_state: int, new_state: int) -> void:
		_captured_old_state = old_state
		_captured_new_state = new_state

	SignalBus.game_state_changed.connect(callable)

	var before := GameState.current_state
	GameState.current_state = Enums.GameState.GAME_OVER

	assert_equal(_captured_old_state, before, "signal emits correct old_state")
	assert_equal(_captured_new_state, Enums.GameState.GAME_OVER, "signal emits correct new_state")

	SignalBus.game_state_changed.disconnect(callable)
	GameState.current_state = before


func _test_reset_for_new_game() -> void:
	GameState.player["size"] = 5
	GameState.player["energy"] = 10.0
	GameState.player["has_item"] = true
	GameState.match_state["locations_completed"] = [1, 2, 3]

	GameState.reset_for_new_game()

	assert_equal(GameState.player["size"], 1, "reset: player size == 1")
	assert_equal(GameState.player["energy"], 100.0, "reset: player energy == 100.0")
	assert_false(GameState.player["has_item"], "reset: has_item == false")
	assert_equal(GameState.match_state["locations_completed"], [], "reset: locations_completed == []")


func _test_config_keys() -> void:
	assert_true(GameState.config.has("map_size"), "config has map_size")
	assert_true(GameState.config.has("num_opponents"), "config has num_opponents")
	assert_true(GameState.config.has("ai_difficulties"), "config has ai_difficulties")
	assert_true(GameState.config.has("seed"), "config has seed")
	assert_true(GameState.config.has("item_id"), "config has item_id")


func _test_is_in_match() -> void:
	GameState.current_state = Enums.GameState.MENU
	assert_false(GameState.is_in_match(), "MENU: is_in_match == false")

	GameState.current_state = Enums.GameState.IN_GAME
	assert_true(GameState.is_in_match(), "IN_GAME: is_in_match == true")

	GameState.current_state = Enums.GameState.PAUSED
	assert_true(GameState.is_in_match(), "PAUSED: is_in_match == true")

	GameState.current_state = Enums.GameState.MENU
