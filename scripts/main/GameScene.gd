extends Control

const HUDScene := preload("res://scenes/ui/HUD.tscn")
const WelcomeBackScene := preload("res://scenes/ui/WelcomeBack.tscn")
const PerfumeItemScene := preload("res://scenes/grid/PerfumeItem.tscn")


func _ready() -> void:
	SaveManager.data = SaveManager.load_game()
	var grid: Node = $MarginContainer/VBoxContainer/Grid
	SpawnManager.set_grid(grid)
	EconomyManager.essence = int(SaveManager.data.get("essence", 0))

	call_deferred("_restore_grid_state", grid)

	add_child(HUDScene.instantiate())
	AudioManager.register_bgm_player($BGM)

	if OS.has_feature("web"):
		AdManager.init_poki()

	_check_offline_earnings()


func _restore_grid_state(grid: Node) -> void:
	var grid_state: Array = SaveManager.data.get("grid_state", [])
	if grid_state == null:
		return
	for i in range(grid_state.size()):
		var entry = grid_state[i]
		if entry == null or typeof(entry) != TYPE_DICTIONARY:
			continue
		var slot = grid.get_slot(i)
		if slot == null or not slot.is_empty():
			continue
		var tier: int = int(entry.get("tier", 1))
		var url: String = String(entry.get("url", ""))
		var name: String = String(entry.get("name", ""))
		var brand: String = String(entry.get("brand", ""))
		var p_data: Dictionary = DataManager.find_perfume(url, name, brand)
		if p_data.is_empty():
			p_data = {"name": name, "brand": brand, "url": url}
		var item := PerfumeItemScene.instantiate()
		slot.place_item(item)
		item.setup(tier, p_data)


func _check_offline_earnings() -> void:
	var offline: Dictionary = EconomyManager.calculate_offline_earnings()
	var amount: int = int(offline.get("essence", 0))
	if amount <= 0:
		return
	var popup := WelcomeBackScene.instantiate()
	popup.setup(amount)
	add_child(popup)


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_EXIT_TREE:
		SaveManager.set_logout_time()
