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
	resized.connect(_update_slot_sizes)
	get_viewport().size_changed.connect(_update_slot_sizes)
	call_deferred("_update_slot_sizes")


func _update_slot_sizes() -> void:
	if slots.is_empty() or columns <= 0:
		return
	var rows: int = int(ceil(float(slots.size()) / float(columns)))
	var h_sep: int = get_theme_constant("h_separation")
	var v_sep: int = get_theme_constant("v_separation")
	var viewport_size: Vector2 = get_viewport_rect().size
	var parent_ctrl := get_parent()
	var available_w: float = viewport_size.x
	var available_h: float = viewport_size.y
	var top_reserved: float = 0.0
	var bottom_reserved: float = 0.0
	var side_margin: float = 0.0
	if parent_ctrl is VBoxContainer:
		var vbox_sep: int = parent_ctrl.get_theme_constant("separation")
		for child in parent_ctrl.get_children():
			if child == self:
				continue
			if child is Control:
				var min_h: float = child.get_combined_minimum_size().y
				top_reserved += min_h + vbox_sep
		top_reserved += vbox_sep
		var margin_parent := parent_ctrl.get_parent()
		if margin_parent is MarginContainer:
			side_margin = float(margin_parent.get_theme_constant("margin_left") + margin_parent.get_theme_constant("margin_right"))
			top_reserved += float(margin_parent.get_theme_constant("margin_top") + margin_parent.get_theme_constant("margin_bottom"))
	available_w -= side_margin
	available_h -= top_reserved + bottom_reserved
	var slot_w: float = (available_w - float(columns - 1) * float(h_sep)) / float(columns)
	var slot_h: float = (available_h - float(rows - 1) * float(v_sep)) / float(rows)
	var slot_size: float = floor(min(slot_w, slot_h))
	if slot_size <= 0.0:
		return
	var sq := Vector2(slot_size, slot_size)
	for slot in slots:
		slot.custom_minimum_size = sq


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
