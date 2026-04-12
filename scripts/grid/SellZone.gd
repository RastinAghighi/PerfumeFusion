extends Panel

var _normal_style: StyleBoxFlat
var _highlight_style: StyleBoxFlat


func _ready() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE
	$Label.mouse_filter = MOUSE_FILTER_IGNORE

	_normal_style = StyleBoxFlat.new()
	_normal_style.bg_color = Color(0.15, 0.12, 0.2, 0.8)
	_normal_style.corner_radius_top_left = 12
	_normal_style.corner_radius_top_right = 12
	_normal_style.corner_radius_bottom_left = 12
	_normal_style.corner_radius_bottom_right = 12
	_normal_style.border_width_left = 2
	_normal_style.border_width_top = 2
	_normal_style.border_width_right = 2
	_normal_style.border_width_bottom = 2
	_normal_style.border_color = Color(0.4, 0.3, 0.2, 0.5)

	_highlight_style = _normal_style.duplicate()
	_highlight_style.bg_color = Color(0.25, 0.18, 0.08, 0.9)
	_highlight_style.border_color = Color(1.0, 0.8, 0.3, 1.0)
	_highlight_style.border_width_left = 3
	_highlight_style.border_width_top = 3
	_highlight_style.border_width_right = 3
	_highlight_style.border_width_bottom = 3

	add_theme_stylebox_override("panel", _normal_style)


func highlight() -> void:
	add_theme_stylebox_override("panel", _highlight_style)


func unhighlight() -> void:
	add_theme_stylebox_override("panel", _normal_style)


func get_sell_value(tier: int) -> int:
	if tier <= 0:
		return 0
	if tier <= 5:
		return [0, 3, 8, 18, 35, 60][tier]
	elif tier <= 10:
		return 60 + (tier - 5) * 50
	elif tier <= 15:
		return 310 + (tier - 10) * 100
	else:
		return 810 + (tier - 15) * 250


func show_sell_text(amount: int) -> void:
	var label := Label.new()
	label.text = "+" + str(amount) + " Essence"
	label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	label.add_theme_font_size_override("font_size", 20)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.size = Vector2(size.x, 30)
	label.position = Vector2(0, -10)
	add_child(label)

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position:y", -50.0, 0.8).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "modulate:a", 0.0, 0.8).set_delay(0.2)
	tween.set_parallel(false)
	tween.tween_callback(label.queue_free)
