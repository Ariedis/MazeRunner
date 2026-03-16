class_name ItemRegistry
extends RefCounted

const DEFAULT_ITEMS: Array[Dictionary] = [
	{"id": "golden_key", "name": "Golden Key"},
	{"id": "crystal_orb", "name": "Crystal Orb"},
	{"id": "ancient_scroll", "name": "Ancient Scroll"},
	{"id": "dragon_scale", "name": "Dragon Scale"},
	{"id": "phoenix_feather", "name": "Phoenix Feather"},
]

var _items: Array[ItemData] = []


func _init() -> void:
	for entry in DEFAULT_ITEMS:
		var item := ItemData.new()
		item.id = entry["id"]
		item.name = entry["name"]
		item.is_custom = false
		_items.append(item)


func get_all() -> Array[ItemData]:
	return _items.duplicate()


func get_item(id: String) -> ItemData:
	for item in _items:
		if item.id == id:
			return item
	return null


func add_custom(id: String, item_name: String) -> void:
	var item := ItemData.new()
	item.id = id
	item.name = item_name
	item.is_custom = true
	_items.append(item)


func count() -> int:
	return _items.size()
