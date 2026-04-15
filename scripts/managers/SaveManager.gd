extends Node

const SAVE_PATH := "user://save_data.json"

var data: Dictionary = {}


func _ready() -> void:
	data = load_game()


func get_default_data() -> Dictionary:
	var grid_state: Array = []
	for i in range(25):
		grid_state.append(null)
	return {
		"grid_state": grid_state,
		"unlocked_perfumes": [],
		"essence": 50,
		"total_spawns": 0,
		"upgrades": {
			"spawn_speed_level": 0,
			"spawn_cooldown_level": 0,
			"offline_rate_level": 0,
			"offline_cap_level": 0,
			"lucky_merge_level": 0,
			"extra_grid": false,
		},
		"last_logout_time": 0,
		"stats": {
			"total_merges": 0,
			"highest_tier": 0,
			"total_perfumes_discovered": 0,
		},
		"audio": {
			"music_volume": 0.8,
			"sfx_volume": 1.0,
			"muted": false,
		},
		"tutorial_completed": false,
		"beaten_opponents": [],
		"battle_stats": {
			"total_battles": 0,
			"total_victories": 0,
			"total_defeats": 0,
			"fastest_victory": {},
			"highest_combo": 0,
		},
	}


func save_game() -> void:
	if not BattleManager.is_battle_active:
		_capture_grid_state()
	var occupied := 0
	for entry in data.get("grid_state", []):
		if entry != null:
			occupied += 1
	print("Saving grid. Occupied slots: ", occupied)
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("SaveManager: failed to open save file for writing: %s" % FileAccess.get_open_error())
		return
	file.store_string(JSON.stringify(data))
	file.close()


func _capture_grid_state() -> void:
	var grid: Node = null
	if SpawnManager != null:
		grid = SpawnManager.grid_reference
	if grid == null or not ("slots" in grid):
		return
	var slots: Array = grid.slots
	var grid_state: Array = []
	for i in range(25):
		if i >= slots.size():
			grid_state.append(null)
			continue
		var slot = slots[i]
		if slot == null or slot.is_empty():
			grid_state.append(null)
			continue
		var item = slot.occupied_item
		if item == null or not ("tier" in item):
			grid_state.append(null)
			continue
		var p_data: Dictionary = item.perfume_data
		grid_state.append({
			"tier": int(item.tier),
			"name": String(p_data.get("name", "")),
			"brand": String(p_data.get("brand", "")),
			"url": String(p_data.get("url", "")),
		})
	data["grid_state"] = grid_state


func load_game() -> Dictionary:
	if not FileAccess.file_exists(SAVE_PATH):
		return get_default_data()
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		push_error("SaveManager: failed to open save file for reading: %s" % FileAccess.get_open_error())
		return get_default_data()
	var text := file.get_as_text()
	file.close()
	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("SaveManager: save file malformed, using defaults")
		return get_default_data()
	return _merge_defaults(parsed, get_default_data())


func _merge_defaults(loaded: Dictionary, defaults: Dictionary) -> Dictionary:
	for key in defaults.keys():
		if not loaded.has(key):
			loaded[key] = defaults[key]
		elif typeof(defaults[key]) == TYPE_DICTIONARY and typeof(loaded[key]) == TYPE_DICTIONARY:
			loaded[key] = _merge_defaults(loaded[key], defaults[key])
	return loaded


func mark_opponent_beaten(id: int) -> void:
	var beaten: Array = data.get("beaten_opponents", [])
	if not beaten.has(id):
		beaten.append(id)
		data["beaten_opponents"] = beaten
		save_game()


func is_opponent_beaten(id: int) -> bool:
	var beaten: Array = data.get("beaten_opponents", [])
	return id in beaten


func get_beaten_count() -> int:
	return data.get("beaten_opponents", []).size()


func update_battle_stats(opponent_id: int, won: bool, time_taken: float, max_combo: int) -> void:
	var bs: Dictionary = data.get("battle_stats", {})
	bs["total_battles"] = int(bs.get("total_battles", 0)) + 1
	if won:
		bs["total_victories"] = int(bs.get("total_victories", 0)) + 1
	else:
		bs["total_defeats"] = int(bs.get("total_defeats", 0)) + 1

	if won:
		var fastest: Dictionary = bs.get("fastest_victory", {})
		var key: String = str(opponent_id)
		if not fastest.has(key) or time_taken < float(fastest[key]):
			fastest[key] = time_taken
		bs["fastest_victory"] = fastest

	if max_combo > int(bs.get("highest_combo", 0)):
		bs["highest_combo"] = max_combo

	data["battle_stats"] = bs
	save_game()


func set_logout_time() -> void:
	data["last_logout_time"] = int(Time.get_unix_time_from_system())
	save_game()
