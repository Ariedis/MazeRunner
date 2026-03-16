class_name LocationData
extends RefCounted

var id: int = 0
var grid_pos: Vector2i = Vector2i(-1, -1)
var item_type: int = Enums.ItemType.SIZE_INCREASER
var item_owner: String = ""
var task: TaskData = null
var completed: bool = false
var completed_by: Array = []
