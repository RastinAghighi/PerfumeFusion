extends Node

const MIN_INTERVAL := 60.0
const MAX_INTERVAL := 90.0
const VISIBLE_DURATION := 10.0

signal rare_drop_available
signal rare_drop_expired

var _time_until_next: float = 0.0
var _visible_time_left: float = 0.0
var _is_visible: bool = false


func _ready() -> void:
	_schedule_next()


func _process(delta: float) -> void:
	if _is_visible:
		_visible_time_left -= delta
		if _visible_time_left <= 0.0:
			_is_visible = false
			emit_signal("rare_drop_expired")
			_schedule_next()
		return

	_time_until_next -= delta
	if _time_until_next <= 0.0:
		_show_drop()


func _schedule_next() -> void:
	_time_until_next = randf_range(MIN_INTERVAL, MAX_INTERVAL)


func _show_drop() -> void:
	_is_visible = true
	_visible_time_left = VISIBLE_DURATION
	emit_signal("rare_drop_available")


func is_available() -> bool:
	return _is_visible


func claim() -> void:
	if not _is_visible:
		return
	_is_visible = false
	emit_signal("rare_drop_expired")
	var tier: int = _calculate_rare_tier()
	AdManager.show_rewarded_ad(func(success: bool) -> void:
		if success:
			var ok: bool = SpawnManager.spawn_at_tier(tier)
			if not ok:
				_notify_grid_full()
		_schedule_next()
	)


func _notify_grid_full() -> void:
	var hud: Node = get_tree().get_first_node_in_group("hud")
	if hud != null and hud.has_method("show_grid_full_message"):
		hud.show_grid_full_message("Make room first!")


func _calculate_rare_tier() -> int:
	var grid: Node = SpawnManager.grid_reference
	if grid == null or not ("slots" in grid):
		return 3
	var total: int = 0
	var count: int = 0
	for slot in grid.slots:
		var item = slot.occupied_item
		if item != null and "tier" in item:
			total += int(item.tier)
			count += 1
	var avg: float = 1.0
	if count > 0:
		avg = float(total) / float(count)
	var rare: int = int(round(avg)) + 2
	return clamp(rare, 3, 20)
