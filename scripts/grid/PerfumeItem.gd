extends Control

var tier: int = 0
var perfume_data: Dictionary = {}

var is_dragging: bool = false
var original_slot: Node = null


func _ready() -> void:
	mouse_filter = MOUSE_FILTER_STOP
	$TierLabel.mouse_filter = MOUSE_FILTER_IGNORE
	$NameLabel.mouse_filter = MOUSE_FILTER_IGNORE
	$BrandLabel.mouse_filter = MOUSE_FILTER_IGNORE
	$BottleShape.mouse_filter = MOUSE_FILTER_IGNORE


func setup(p_tier: int, p_data: Dictionary) -> void:
	tier = p_tier
	perfume_data = p_data

	$TierLabel.text = "T" + str(tier)

	var name_text := String(p_data.get("name", "")).strip_edges()
	$NameLabel.text = name_text.capitalize()

	var brand_text := String(p_data.get("brand", "")).strip_edges()
	$BrandLabel.text = brand_text.capitalize()

	var color: Color = DataManager.get_tier_color(tier)
	var style: StyleBoxFlat = $BottleShape.get_theme_stylebox("panel")
	if style != null:
		style = style.duplicate()
		style.bg_color = color
		$BottleShape.add_theme_stylebox_override("panel", style)


func _gui_input(event: InputEvent) -> void:
	if is_dragging:
		return
	var should_start := false
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			should_start = true
	elif event is InputEventScreenTouch:
		if event.pressed:
			should_start = true
	if should_start:
		_start_drag()
		accept_event()


func _input(event: InputEvent) -> void:
	if not is_dragging:
		return
	var should_stop := false
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
			should_stop = true
	elif event is InputEventScreenTouch:
		if not event.pressed:
			should_stop = true
	if should_stop:
		_stop_drag()


func _process(_delta: float) -> void:
	if is_dragging:
		var pointer := get_global_mouse_position()
		global_position = pointer - size * 0.5


func _start_drag() -> void:
	var node: Node = get_parent()
	var found_slot: Node = null
	while node != null:
		if node.has_method("place_item") and node.has_method("remove_item"):
			found_slot = node
			break
		node = node.get_parent()
	if found_slot == null:
		return
	original_slot = found_slot

	var saved_global_pos: Vector2 = global_position
	var saved_size: Vector2 = size

	original_slot.remove_item()

	var root := get_tree().root
	root.add_child(self)
	top_level = true
	z_index = 100
	custom_minimum_size = saved_size
	size = saved_size
	global_position = saved_global_pos

	is_dragging = true


func _stop_drag() -> void:
	is_dragging = false
	z_index = 0
	top_level = false

	var pointer := get_global_mouse_position()
	var grid: Node = null
	if original_slot != null:
		grid = original_slot.get_parent()
	if grid == null or not grid.has_method("attempt_drop"):
		return
	var target = grid.get_slot_at_position(pointer)
	grid.attempt_drop(self, target)
