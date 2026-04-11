extends Node

signal merge_completed(new_item, tier)
signal new_perfume_discovered(perfume_data)

const MAX_TIER := 20
const PerfumeItemScene := preload("res://scenes/grid/PerfumeItem.tscn")


func execute_merge(item_a, item_b, target_slot, _grid) -> bool:
	if item_a == null or item_b == null or target_slot == null:
		return false
	if item_a.tier != item_b.tier:
		return false

	var new_tier: int = item_a.tier + 1
	if new_tier > MAX_TIER:
		print("MAX TIER REACHED!")
		return false

	var new_data: Dictionary = DataManager.get_random_perfume(new_tier)
	if new_data.is_empty():
		push_warning("MergeManager: no perfume available for tier %d" % new_tier)
		return false

	var slot_a = item_a.original_slot
	if slot_a != null and slot_a.occupied_item == item_a:
		slot_a.remove_item()
	elif item_a.get_parent() != null:
		item_a.get_parent().remove_child(item_a)
	item_a.queue_free()

	var slot_b = target_slot
	if slot_b.occupied_item == item_b:
		slot_b.remove_item()
	elif item_b.get_parent() != null:
		item_b.get_parent().remove_child(item_b)
	item_b.queue_free()

	var new_item = PerfumeItemScene.instantiate()
	target_slot.place_item(new_item)
	new_item.setup(new_tier, new_data)

	var url := String(new_data.get("url", ""))
	var unlocked: Array = SaveManager.data.get("unlocked_perfumes", [])
	if url != "" and not unlocked.has(url):
		unlocked.append(url)
		SaveManager.data["unlocked_perfumes"] = unlocked
		var stats: Dictionary = SaveManager.data.get("stats", {})
		stats["total_perfumes_discovered"] = int(stats.get("total_perfumes_discovered", 0)) + 1
		SaveManager.data["stats"] = stats
		emit_signal("new_perfume_discovered", new_data)

	var stats2: Dictionary = SaveManager.data.get("stats", {})
	stats2["total_merges"] = int(stats2.get("total_merges", 0)) + 1
	if new_tier > int(stats2.get("highest_tier", 0)):
		stats2["highest_tier"] = new_tier
	SaveManager.data["stats"] = stats2

	var essence_reward: int = 10 * new_tier
	print("Earned %d essence" % essence_reward)

	SaveManager.save_game()
	emit_signal("merge_completed", new_item, new_tier)
	return true
