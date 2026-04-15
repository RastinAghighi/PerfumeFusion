extends Panel

var occupied_item: Node = null
var grid_index: int = -1

func initialize(index: int) -> void:
	grid_index = index

func is_empty() -> bool:
	return occupied_item == null

func place_item(item: Node) -> void:
	if occupied_item != null:
		return
	occupied_item = item
	if item.get_parent() != null:
		item.get_parent().remove_child(item)
	add_child(item)
	item.anchor_left = 0
	item.anchor_top = 0
	item.anchor_right = 1
	item.anchor_bottom = 1
	item.offset_left = 0
	item.offset_top = 0
	item.offset_right = 0
	item.offset_bottom = 0

func remove_item() -> Node:
	var item := occupied_item
	if item != null:
		if item.get_parent() == self:
			remove_child(item)
		occupied_item = null
	return item
