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
	var center := $CenterContainer
	if item.get_parent() != null:
		item.get_parent().remove_child(item)
	center.add_child(item)

func remove_item() -> Node:
	var item := occupied_item
	if item != null:
		var center := $CenterContainer
		if item.get_parent() == center:
			center.remove_child(item)
		occupied_item = null
	return item
