extends Control

const HUDScene := preload("res://scenes/ui/HUD.tscn")
const WelcomeBackScene := preload("res://scenes/ui/WelcomeBack.tscn")


func _ready() -> void:
	SaveManager.data = SaveManager.load_game()
	var grid: Node = $MarginContainer/VBoxContainer/Grid
	SpawnManager.set_grid(grid)
	EconomyManager.essence = int(SaveManager.data.get("essence", 0))

	add_child(HUDScene.instantiate())
	AudioManager.register_bgm_player($BGM)

	if OS.has_feature("web"):
		AdManager.init_poki()

	_check_offline_earnings()


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
