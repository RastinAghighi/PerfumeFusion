extends Node

var _original_position: Vector2 = Vector2.ZERO
var _shake_tween: Tween = null
var _target: Control = null


func setup(target: Control) -> void:
	_target = target
	_original_position = _target.position


func shake(intensity: float, duration: float) -> void:
	if _target == null:
		return

	if _shake_tween != null and _shake_tween.is_valid():
		_shake_tween.kill()
	_target.position = _original_position

	var steps: int = int(duration / 0.02)
	_shake_tween = _target.create_tween()
	for i in range(steps):
		var progress: float = float(i) / float(steps)
		var current_intensity: float = intensity * (1.0 - progress)
		var offset := Vector2(
			randf_range(-current_intensity, current_intensity),
			randf_range(-current_intensity, current_intensity)
		)
		_shake_tween.tween_property(_target, "position", _original_position + offset, 0.02)
	_shake_tween.tween_property(_target, "position", _original_position, 0.02)
