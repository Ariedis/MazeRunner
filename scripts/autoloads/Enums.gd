extends Node

enum GameState {
	MENU = 0,
	CHARACTER_SELECT,
	NEW_GAME,
	IN_GAME,
	PAUSED,
	GAME_OVER,
	LOAD_GAME
}

enum MapSize {
	SMALL = 0,
	MEDIUM,
	LARGE
}

enum Difficulty {
	EASY = 0,
	MEDIUM,
	HARD
}

const MAP_SIZE_DATA: Dictionary = {
	MapSize.SMALL: {
		"grid_width": 15,
		"grid_height": 15,
		"location_count": 4,
		"max_opponents": 2,
		"cell_px": 64
	},
	MapSize.MEDIUM: {
		"grid_width": 25,
		"grid_height": 25,
		"location_count": 8,
		"max_opponents": 4,
		"cell_px": 48
	},
	MapSize.LARGE: {
		"grid_width": 40,
		"grid_height": 40,
		"location_count": 14,
		"max_opponents": 6,
		"cell_px": 32
	}
}

const MIN_SIZE: int = 1
const MAX_SIZE: int = 10
const CREATOR_BUDGET: int = 3

const STARTING_ENERGY: float = 100.0
const ENERGY_DRAIN: float = 1.0
const ENERGY_REGEN: float = 2.0

const FULL_SPEED: float = 150.0
const HALF_SPEED: float = 75.0
