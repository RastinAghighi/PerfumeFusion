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
	var test_tiers := [1, 5, 10]
	for idx in range(test_tiers.size()):
		var tier: int = test_tiers[idx]
		var data: Dictionary = DataManager.get_random_perfume(tier)
		if data.is_empty():
			continue
		var slot = get_slot(idx)
		if slot == null or not slot.is_empty():
			continue
		var item := PerfumeItemScene.instantiate()
		item.setup(tier, data)
		slot.place_item(item)

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
