class_name PlayerStats
extends RefCounted

var size: int = 1
var energy: float = 100.0

var is_full_speed: bool:
	get:
		return energy > 0.0


func drain(delta: float) -> void:
	energy = maxf(0.0, energy - Enums.ENERGY_DRAIN * delta)


func regen(delta: float) -> void:
	energy = minf(100.0, energy + Enums.ENERGY_REGEN * delta)


func add_size(amount: int = 1) -> void:
	size = clampi(size + amount, Enums.MIN_SIZE, Enums.MAX_SIZE)


func current_speed() -> float:
	return Enums.FULL_SPEED if is_full_speed else Enums.HALF_SPEED
