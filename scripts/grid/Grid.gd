extends GridContainer

const PerfumeItemScene := preload("res://scenes/grid/PerfumeItem.tscn")

var slots: Array = []

func _ready() -> void:
	slots.clear()
	var i := 0
	for child in get_children():
		slots.append(child)
		if child.has_method("initialize"):
			child.initialize(i)
		i += 1
	_test_spawn_perfumes()


func _test_spawn_perfumes() -> void:
	for idx in range(10):
		var data: Dictionary = DataManager.get_random_perfume(1)
		if data.is_empty():
			continue
		var slot = get_slot(idx)
		if slot == null or not slot.is_empty():
			continue
		var item := PerfumeItemScene.instantiate()
		slot.place_item(item)
		item.setup(1, data)


func attempt_drop(item, target_slot) -> void:
	if target_slot == null:
		_return_to_origin(item)
		return
	if target_slot == item.original_slot:
		_return_to_origin(item)
		return
	if target_slot.is_empty():
		_place_in_slot(item, target_slot)
		return
	var other = target_slot.occupied_item
	if other != null and "tier" in other and other.tier == item.tier:
		var success: bool = MergeManager.execute_merge(item, other, target_slot, self)
		if not success:
			_return_to_origin(item)
	else:
		_return_to_origin(item)


func get_slot_at_position(global_pos: Vector2):
	for slot in slots:
		var rect := Rect2(slot.global_position, slot.size)
		if rect.has_point(global_pos):
			return slot
	return null


func _return_to_origin(item) -> void:
	var origin = item.original_slot
	if origin == null:
		return
	if item.get_parent() != null:
		item.get_parent().remove_child(item)
	item.top_level = false
	item.z_index = 0
	origin.place_item(item)
	item.original_slot = null


func _place_in_slot(item, target_slot) -> void:
	if item.get_parent() != null:
		item.get_parent().remove_child(item)
	item.top_level = false
	item.z_index = 0
	target_slot.place_item(item)
	item.original_slot = null


func get_empty_slots() -> Array:
	var empty: Array = []
	for slot in slots:
		if slot.is_empty():
			empty.append(slot)
	return empty

func get_slot(index: int):
	if index < 0 or index >= slots.size():
		return null
	return slots[index]

func is_full() -> bool:
	for slot in slots:
		if slot.is_empty():
			return false
	return true
