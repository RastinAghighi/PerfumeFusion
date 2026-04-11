extends GridContainer

var slots: Array = []

func _ready() -> void:
	slots.clear()
	var i := 0
	for child in get_children():
		slots.append(child)
		if child.has_method("initialize"):
			child.initialize(i)
		i += 1

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
