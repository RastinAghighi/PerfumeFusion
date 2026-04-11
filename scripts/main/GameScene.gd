extends Control

const SPAWN_COOLDOWN: float = 3.0

@onready var spawn_button: Button = $MarginContainer/VBoxContainer/BottomBar/SpawnButton

var cooldown_left: float = 0.0


func _ready() -> void:
	DirAccess.remove_absolute("user://save_data.json")
	SaveManager.data = SaveManager.load_game()
	var grid: Node = $MarginContainer/VBoxContainer/Grid
	SpawnManager.set_grid(grid)
	spawn_button.pressed.connect(_on_spawn_pressed)
	SpawnManager.manual_spawn_succeeded.connect(_on_spawn_succeeded)
	set_process(true)
	_refresh_button()


func _process(delta: float) -> void:
	if cooldown_left > 0.0:
		cooldown_left = max(0.0, cooldown_left - delta)
		_refresh_button()


func _on_spawn_pressed() -> void:
	print("SPAWN BUTTON PRESSED")
	var grid: Node = $MarginContainer/VBoxContainer/Grid
	var cost: int = SpawnManager.get_manual_spawn_cost()
	print("Cooldown active: ", cooldown_left > 0.0)
	print("Grid full: ", grid.is_full())
	print("Essence: ", SaveManager.data.get("essence", 0))
	print("Spawn cost: ", cost)
	if cooldown_left > 0.0:
		return
	SpawnManager.manual_spawn()


func _on_spawn_succeeded(_remaining_free: int, _essence: int) -> void:
	cooldown_left = SPAWN_COOLDOWN
	_refresh_button()


func _refresh_button() -> void:
	if cooldown_left > 0.0:
		spawn_button.disabled = true
		spawn_button.text = "%.1fs" % cooldown_left
		return

	spawn_button.disabled = false
	var cost: int = SpawnManager.get_manual_spawn_cost()
	if cost == 0:
		spawn_button.text = "+\nFREE"
	else:
		spawn_button.text = "+\n%d" % cost
