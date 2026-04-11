extends Node

const PerfumeItemScene := preload("res://scenes/grid/PerfumeItem.tscn")

const SPAWN_INTERVALS := [3.0, 2.5, 2.0, 1.5]
const FRENZY_INTERVAL := 0.5
const MANUAL_SPAWN_COST := 10

var spawn_interval: float = 5.0
var spawn_timer: float = 5.0
var grid_reference: Node = null

var auto_spawn_enabled: bool = false

var _frenzy_active: bool = false
var _frenzy_time_left: float = 0.0

signal manual_spawn_failed(reason: String)
signal manual_spawn_succeeded(remaining_free: int, essence: int)


func _ready() -> void:
	spawn_interval = get_current_spawn_interval()
	spawn_timer = spawn_interval


func set_grid(grid: Node) -> void:
	grid_reference = grid
	spawn_timer = get_current_spawn_interval()


func get_current_spawn_interval() -> float:
	var level: int = 0
	if SaveManager != null and SaveManager.data.has("upgrades"):
		level = int(SaveManager.data["upgrades"].get("spawn_speed_level", 0))
	level = clamp(level, 0, SPAWN_INTERVALS.size() - 1)
	return SPAWN_INTERVALS[level]


func _process(delta: float) -> void:
	if _frenzy_active:
		_frenzy_time_left -= delta
		if _frenzy_time_left <= 0.0:
			_frenzy_active = false

	if grid_reference == null:
		return

	if not (auto_spawn_enabled or _frenzy_active):
		return

	spawn_timer -= delta
	if spawn_timer <= 0.0:
		spawn_timer = _active_interval()
		_try_spawn()


func _active_interval() -> float:
	if _frenzy_active:
		return FRENZY_INTERVAL
	return get_current_spawn_interval()


func _try_spawn() -> void:
	if grid_reference == null or not grid_reference.has_method("get_empty_slots"):
		return
	var empty_slots: Array = grid_reference.get_empty_slots()
	if empty_slots.is_empty():
		return
	var slot = empty_slots[randi() % empty_slots.size()]
	var data: Dictionary = DataManager.get_random_perfume(1)
	if data.is_empty():
		return
	var item := PerfumeItemScene.instantiate()
	slot.place_item(item)
	item.setup(1, data)
	_fade_in(item)


func _fade_in(item: Node) -> void:
	if not (item is CanvasItem):
		return
	item.modulate = Color(1, 1, 1, 0)
	var tween := item.create_tween()
	tween.tween_property(item, "modulate:a", 1.0, 0.3)


func manual_spawn() -> bool:
	if grid_reference == null or not grid_reference.has_method("get_empty_slots"):
		manual_spawn_failed.emit("no_grid")
		return false
	if grid_reference.get_empty_slots().is_empty():
		manual_spawn_failed.emit("grid_full")
		return false

	var free_remaining: int = int(SaveManager.data.get("free_spawns_remaining", 0))
	var is_free: bool = free_remaining > 0
	var essence: int = int(SaveManager.data.get("essence", 0))

	if not is_free and essence < MANUAL_SPAWN_COST:
		manual_spawn_failed.emit("not_enough_essence")
		return false

	_try_spawn()

	if is_free:
		free_remaining -= 1
		SaveManager.data["free_spawns_remaining"] = free_remaining
		print("Spawned! Free spawns left: ", free_remaining)
	else:
		essence -= MANUAL_SPAWN_COST
		SaveManager.data["essence"] = essence
		print("Spawned! Essence remaining: ", essence)
	SaveManager.save_game()

	manual_spawn_succeeded.emit(free_remaining, int(SaveManager.data["essence"]))
	return true


func get_manual_spawn_cost() -> int:
	var free_remaining: int = int(SaveManager.data.get("free_spawns_remaining", 0))
	if free_remaining > 0:
		return 0
	return MANUAL_SPAWN_COST


func start_frenzy(duration: float) -> void:
	_frenzy_active = true
	_frenzy_time_left = duration
	spawn_timer = min(spawn_timer, FRENZY_INTERVAL)
	AudioManager.play_frenzy()


func is_frenzy_active() -> bool:
	return _frenzy_active


func spawn_at_tier(tier: int) -> bool:
	if grid_reference == null or not grid_reference.has_method("get_empty_slots"):
		return false
	var empty_slots: Array = grid_reference.get_empty_slots()
	if empty_slots.is_empty():
		return false
	var slot = empty_slots[randi() % empty_slots.size()]
	var data: Dictionary = DataManager.get_random_perfume(tier)
	if data.is_empty():
		return false
	var item := PerfumeItemScene.instantiate()
	slot.place_item(item)
	item.setup(tier, data)
	_fade_in(item)
	return true
