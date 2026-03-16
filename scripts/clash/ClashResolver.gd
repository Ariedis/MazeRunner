class_name ClashResolver
extends RefCounted

## Rolls a single six-sided die. Returns 1-6.
static func roll_d6(rng: RandomNumberGenerator) -> int:
	return rng.randi_range(1, 6)


## Resolves a clash between participant A and B.
## Returns a Dictionary:
##   winner   : "a" or "b"
##   roll_a   : int (dice result for A)
##   roll_b   : int (dice result for B)
##   total_a  : int (roll_a + size_a)
##   total_b  : int (roll_b + size_b)
##   rerolls  : int (number of ties resolved)
static func resolve(size_a: int, size_b: int, rng: RandomNumberGenerator) -> Dictionary:
	var rerolls := 0
	while true:
		var roll_a := roll_d6(rng)
		var roll_b := roll_d6(rng)
		var total_a := roll_a + size_a
		var total_b := roll_b + size_b
		if total_a != total_b:
			return {
				"winner": "a" if total_a > total_b else "b",
				"roll_a": roll_a,
				"roll_b": roll_b,
				"total_a": total_a,
				"total_b": total_b,
				"rerolls": rerolls,
			}
		rerolls += 1
	return {}  # Unreachable — satisfies static analysis.


## Returns the penalty weight string based on the winner's Size stat.
## Size 1-3 → "1kg", 4-7 → "2kg", 8-10 → "3kg"
static func get_penalty_weight(winner_size: int) -> String:
	if winner_size <= 3:
		return "1kg"
	elif winner_size <= 7:
		return "2kg"
	else:
		return "3kg"


## Returns the speed instruction based on winner's current energy (0-100 scale).
## >80 → "QUICKLY", 50-80 → "normal speed", <50 → "SLOWLY"
static func get_penalty_speed(winner_energy: float) -> String:
	if winner_energy > 80.0:
		return "QUICKLY"
	elif winner_energy >= 50.0:
		return "normal speed"
	else:
		return "SLOWLY"


## Returns the penalty timer duration in seconds based on winner's energy.
## QUICKLY → 15s, normal → 25s, SLOWLY → 40s
static func get_penalty_duration(winner_energy: float) -> float:
	if winner_energy > 80.0:
		return 15.0
	elif winner_energy >= 50.0:
		return 25.0
	else:
		return 40.0
