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
	_load_custom_items()


## Load custom items from the Phase 11 custom content manifest.
func _load_custom_items() -> void:
	var mgr := CustomContentManager.new()
	var custom := mgr.get_custom_items()
	for entry in custom:
		var id: String = entry.get("id", "")
		var item_name: String = entry.get("name", "")
		if id != "" and item_name != "" and get_item(id) == null:
			add_custom(id, item_name)


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
