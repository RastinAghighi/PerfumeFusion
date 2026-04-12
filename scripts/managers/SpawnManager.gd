extends Node

const PerfumeItemScene := preload("res://scenes/grid/PerfumeItem.tscn")

const SPAWN_INTERVALS := [3.0, 2.5, 2.0, 1.5]
const FRENZY_INTERVAL := 0.5
const COOLDOWN_BY_HIGHEST_TIER := [
	[3, 3.0],
	[6, 4.0],
	[9, 5.0],
	[12, 7.0],
	[15, 10.0],
	[18, 14.0],
	[20, 20.0],
]
const COOLDOWN_REDUCTIONS := [0.0, 0.15, 0.30, 0.45]
const SPAWN_COST_TIERS := [
	[5, 0],
	[15, 10],
	[30, 25],
	[50, 50],
	[-1, 100],
]

var spawn_interval: float = 5.0
var spawn_timer: float = 5.0
var grid_reference: Node = null

var auto_spawn_enabled: bool = false

var _frenzy_active: bool = false
var _frenzy_time_left: float = 0.0
var manual_cooldown_left: float = 0.0
var _last_base_cooldown: float = 3.0

signal manual_spawn_failed(reason: String)
signal manual_spawn_succeeded(remaining_free: int, essence: int)
signal spawn_cooldown_increased


func _ready() -> void:
	spawn_interval = get_current_spawn_interval()
	spawn_timer = spawn_interval
	_last_base_cooldown = get_base_manual_cooldown()


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
	if manual_cooldown_left > 0.0:
		manual_cooldown_left = max(0.0, manual_cooldown_left - delta)

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


func _try_spawn() -> Dictionary:
	if grid_reference == null or not grid_reference.has_method("get_empty_slots"):
		return {}
	var empty_slots: Array = grid_reference.get_empty_slots()
	if empty_slots.is_empty():
		return {}
	var slot = empty_slots[randi() % empty_slots.size()]
	var data: Dictionary = DataManager.get_random_perfume(1)
	if data.is_empty():
		return {}
	var item := PerfumeItemScene.instantiate()
	slot.place_item(item)
	item.setup(1, data)
	_fade_in(item)
	return data


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

	var cost: int = get_manual_spawn_cost()
	if cost > 0 and not EconomyManager.spend_essence(cost):
		manual_spawn_failed.emit("not_enough_essence")
		return false

	_try_spawn()

	var total: int = int(SaveManager.data.get("total_spawns", 0)) + 1
	SaveManager.data["total_spawns"] = total
	SaveManager.save_game()

	manual_spawn_succeeded.emit(0, EconomyManager.get_essence())
	return true


func get_manual_spawn_cost() -> int:
	var total: int = int(SaveManager.data.get("total_spawns", 0))
	for tier in SPAWN_COST_TIERS:
		if int(tier[0]) < 0 or total < int(tier[0]):
			return int(tier[1])
	return 100


func start_frenzy(duration: float) -> void:
	_frenzy_active = true
	_frenzy_time_left = duration
	spawn_timer = min(spawn_timer, FRENZY_INTERVAL)
	AudioManager.play_frenzy()


func is_frenzy_active() -> bool:
	return _frenzy_active


func get_base_manual_cooldown() -> float:
	var highest: int = int(SaveManager.data.get("stats", {}).get("highest_tier", 0))
	for entry in COOLDOWN_BY_HIGHEST_TIER:
		if highest <= int(entry[0]):
			return float(entry[1])
	return 20.0


func get_manual_cooldown() -> float:
	var base: float = get_base_manual_cooldown()
	var level: int = int(SaveManager.data.get("upgrades", {}).get("spawn_cooldown_level", 0))
	level = clampi(level, 0, COOLDOWN_REDUCTIONS.size() - 1)
	return base * (1.0 - COOLDOWN_REDUCTIONS[level])


func start_manual_cooldown() -> void:
	manual_cooldown_left = get_manual_cooldown()


func is_manual_on_cooldown() -> bool:
	return manual_cooldown_left > 0.0


func check_cooldown_bracket_change() -> void:
	var new_base: float = get_base_manual_cooldown()
	if new_base > _last_base_cooldown:
		_last_base_cooldown = new_base
		spawn_cooldown_increased.emit()
	else:
		_last_base_cooldown = new_base


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
