extends Control

@onready var spawn_button: Button = $MarginContainer/VBoxContainer/BottomBar/SpawnButton


func _ready() -> void:
	var grid: Node = $MarginContainer/VBoxContainer/Grid
	SpawnManager.set_grid(grid)
	spawn_button.pressed.connect(_on_spawn_pressed)
	SpawnManager.manual_spawn_succeeded.connect(_on_spawn_changed)
	_refresh_button()


func _on_spawn_pressed() -> void:
	SpawnManager.manual_spawn()
	_refresh_button()


func _on_spawn_changed(_remaining_free: int, _essence: int) -> void:
	_refresh_button()


func _refresh_button() -> void:
	var cost: int = SpawnManager.get_manual_spawn_cost()
	if cost == 0:
		spawn_button.text = "+\nFREE"
	else:
		spawn_button.text = "+\n%d" % cost
