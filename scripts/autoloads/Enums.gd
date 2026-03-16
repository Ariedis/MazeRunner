extends Node

enum ItemType {
	PLAYER_ITEM = 0,
	OPPONENT_ITEM = 1,
	SIZE_INCREASER = 2
}

enum AIState {
	EXPLORE = 0,
	GO_TO_LOC,
	DO_TASK,
	GO_TO_EXIT
}

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

## Task duration multipliers per AI difficulty (keyed by Difficulty enum int value).
const AI_TASK_MULTIPLIER: Dictionary = {
	0: 1.5,  # EASY
	1: 1.0,  # MEDIUM
	2: 0.7,  # HARD
}

## Movement speed multipliers per AI difficulty.
const AI_SPEED_MULTIPLIER: Dictionary = {
	0: 0.8,  # EASY
	1: 1.0,  # MEDIUM
	2: 1.2,  # HARD
}

## Energy thresholds at which AI starts resting, per difficulty.
const AI_REST_THRESHOLD: Dictionary = {
	0: 40.0,  # EASY
	1: 20.0,  # MEDIUM
	2: 5.0,   # HARD
}

## Energy targets AI rests until reaching, per difficulty.
const AI_REST_TARGET: Dictionary = {
	0: 80.0,  # EASY
	1: 50.0,  # MEDIUM
	2: 30.0,  # HARD
}

const MIN_SIZE: int = 1
const MAX_SIZE: int = 10
const CREATOR_BUDGET: int = 3

## Seconds before a character that just clashed can clash again.
const CLASH_COOLDOWN_SECONDS: float = 3.0

## Default clash penalty task parameters.
const CLASH_PENALTY_EXERCISE: String = "Bicep Curls"
const CLASH_PENALTY_REPS: int = 10

const STARTING_ENERGY: float = 100.0
const ENERGY_DRAIN: float = 1.0
const ENERGY_REGEN: float = 2.0

const FULL_SPEED: float = 150.0
const HALF_SPEED: float = 75.0
