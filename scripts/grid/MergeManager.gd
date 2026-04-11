extends Node

signal merge_completed(new_item, tier)
signal new_perfume_discovered(perfume_data)

const MAX_TIER := 20
const PerfumeItemScene := preload("res://scenes/grid/PerfumeItem.tscn")
const MergeParticlesScene := preload("res://scenes/effects/MergeParticles.tscn")


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

	var perfume_color: Color = DataManager.get_tier_color(new_tier)
	_animate_merge(item_a, item_b, target_slot, new_tier, new_data, perfume_color)
	return true


func _animate_merge(item_a, item_b, target_slot, new_tier: int, new_data: Dictionary, perfume_color: Color) -> void:
	var root := get_tree().root

	var size_a: Vector2 = item_a.size
	var size_b: Vector2 = item_b.size
	var gpos_a: Vector2 = item_a.global_position
	var gpos_b: Vector2 = item_b.global_position

	var slot_a = item_a.original_slot
	if slot_a != null and slot_a.occupied_item == item_a:
		slot_a.remove_item()
	elif item_a.get_parent() != null:
		item_a.get_parent().remove_child(item_a)
	root.add_child(item_a)
	item_a.top_level = true
	item_a.custom_minimum_size = size_a
	item_a.size = size_a
	item_a.global_position = gpos_a
	item_a.pivot_offset = size_a * 0.5
	item_a.z_index = 100

	if target_slot.occupied_item == item_b:
		target_slot.remove_item()
	elif item_b.get_parent() != null:
		item_b.get_parent().remove_child(item_b)
	root.add_child(item_b)
	item_b.top_level = true
	item_b.custom_minimum_size = size_b
	item_b.size = size_b
	item_b.global_position = gpos_b
	item_b.pivot_offset = size_b * 0.5
	item_b.z_index = 100

	var target_center: Vector2 = target_slot.global_position + target_slot.size * 0.5
	var target_a: Vector2 = target_center - size_a * 0.5
	var target_b: Vector2 = target_center - size_b * 0.5

	var shrink := create_tween().set_parallel(true).set_ease(Tween.EASE_IN)
	shrink.tween_property(item_a, "scale", Vector2.ZERO, 0.15)
	shrink.tween_property(item_a, "global_position", target_a, 0.15)
	shrink.tween_property(item_b, "scale", Vector2.ZERO, 0.15)
	shrink.tween_property(item_b, "global_position", target_b, 0.15)
	await shrink.finished

	if is_instance_valid(item_a):
		item_a.queue_free()
	if is_instance_valid(item_b):
		item_b.queue_free()

	_spawn_merge_particles(target_center, perfume_color)

	var new_item = PerfumeItemScene.instantiate()
	target_slot.place_item(new_item)
	new_item.setup(new_tier, new_data)
	await get_tree().process_frame
	new_item.pivot_offset = new_item.size * 0.5
	new_item.scale = Vector2.ZERO
	var bounce := create_tween()
	bounce.tween_property(new_item, "scale", Vector2(1.15, 1.15), 0.15)
	bounce.tween_property(new_item, "scale", Vector2(1, 1), 0.1)

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

	EconomyManager.add_essence(EconomyManager.get_merge_reward(new_tier))

	SaveManager.save_game()
	emit_signal("merge_completed", new_item, new_tier)


func _spawn_merge_particles(center: Vector2, color: Color) -> void:
	var particles: CPUParticles2D = MergeParticlesScene.instantiate()
	get_tree().root.add_child(particles)
	particles.global_position = center
	particles.color = color
	particles.z_index = 200
	particles.emitting = true
	var t := get_tree().create_timer(particles.lifetime + 0.2)
	t.timeout.connect(particles.queue_free)
