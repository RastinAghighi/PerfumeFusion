extends Control


func _ready() -> void:
	var grid: Node = $MarginContainer/VBoxContainer/Grid
	SpawnManager.set_grid(grid)
