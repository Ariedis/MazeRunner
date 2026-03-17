class_name CharacterCreatorLogic
extends RefCounted

var budget: int = Enums.CREATOR_BUDGET
var _size: int = 1


var size: int:
	get:
		return _size


var points_spent: int:
	get:
		return _size - 1


var points_remaining: int:
	get:
		return budget - points_spent


func increase_size() -> bool:
	if points_remaining <= 0:
		return false
	_size += 1
	return true


func decrease_size() -> bool:
	if _size <= Enums.MIN_SIZE:
		return false
	_size -= 1
	return true


func reset() -> void:
	_size = 1
