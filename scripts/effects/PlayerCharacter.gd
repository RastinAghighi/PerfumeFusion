extends Node2D

@export var move_speed: float = 0.3

var current_progress: float = 0.0
var target_progress: float = 0.0
var road_path: Node = null

@onready var _body: Node2D = $Body
@onready var _label: Label = $Label


func setup(path: Node) -> void:
	road_path = path
	if road_path != null:
		position = road_path.get_position_at_progress(0.0)


func advance(amount: float) -> void:
	target_progress = clamp(current_progress + amount, 0.0, 1.0)


func set_progress(value: float) -> void:
	current_progress = clamp(value, 0.0, 1.0)
	target_progress = current_progress
	if road_path != null:
		position = road_path.get_position_at_progress(current_progress)


func _process(delta: float) -> void:
	if road_path == null:
		return
	if current_progress < target_progress:
		var prev_pos := position
		current_progress = move_toward(current_progress, target_progress, move_speed * delta)
		var new_pos: Vector2 = road_path.get_position_at_progress(current_progress)
		_update_facing(new_pos - prev_pos)
		position = new_pos
	elif current_progress > target_progress:
		var prev_pos := position
		current_progress = move_toward(current_progress, target_progress, move_speed * delta)
		var new_pos: Vector2 = road_path.get_position_at_progress(current_progress)
		_update_facing(new_pos - prev_pos)
		position = new_pos


func _update_facing(delta_vec: Vector2) -> void:
	if _body == null:
		return
	if delta_vec.length() < 0.01:
		return
	if abs(delta_vec.x) > abs(delta_vec.y):
		# Moving horizontally: flip when moving right
		_body.scale.x = -1.0 if delta_vec.x > 0.0 else 1.0
	# Vertical movement: no flip change
