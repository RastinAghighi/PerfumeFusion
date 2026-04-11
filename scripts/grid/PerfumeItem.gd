extends Control

var tier: int = 0
var perfume_data: Dictionary = {}

const DRAG_THRESHOLD: float = 10.0

var is_pressed: bool = false
var is_dragging: bool = false
var press_global_pos: Vector2 = Vector2.ZERO
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
	print("Setting up tier ", p_tier, " color: ", color)
	var style: StyleBoxFlat = $BottleShape.get_theme_stylebox("panel") as StyleBoxFlat
	if style != null:
		style = style.duplicate() as StyleBoxFlat
	else:
		style = StyleBoxFlat.new()
		style.corner_radius_top_left = 12
		style.corner_radius_top_right = 12
		style.corner_radius_bottom_right = 12
		style.corner_radius_bottom_left = 12
	style.bg_color = color
	$BottleShape.add_theme_stylebox_override("panel", style)


func _gui_input(event: InputEvent) -> void:
	if is_dragging or is_pressed:
		return
	var should_press := false
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			should_press = true
	elif event is InputEventScreenTouch:
		if event.pressed:
			should_press = true
	if should_press:
		_begin_press()
		accept_event()


func _input(event: InputEvent) -> void:
	if not is_pressed:
		return

	if not is_dragging:
		var moved: bool = false
		if event is InputEventMouseMotion or event is InputEventScreenDrag:
			var pointer := get_global_mouse_position()
			if pointer.distance_to(press_global_pos) > DRAG_THRESHOLD:
				moved = true
		if moved:
			_start_drag()

	var should_stop := false
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
			should_stop = true
	elif event is InputEventScreenTouch:
		if not event.pressed:
			should_stop = true
	if should_stop:
		_end_press()


func _process(_delta: float) -> void:
	if is_dragging:
		var pointer := get_global_mouse_position()
		global_position = pointer - size * 0.5


func _begin_press() -> void:
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
	press_global_pos = get_global_mouse_position()
	is_pressed = true


func _start_drag() -> void:
	if original_slot == null:
		return

	var saved_global_pos: Vector2 = global_position
	var saved_size: Vector2 = size

	var root := get_tree().root
	original_slot.remove_item()
	root.add_child(self)
	top_level = true
	z_index = 100
	custom_minimum_size = saved_size
	size = saved_size
	global_position = saved_global_pos

	is_dragging = true


func _end_press() -> void:
	var was_dragging: bool = is_dragging
	is_pressed = false
	is_dragging = false

	if not was_dragging:
		# Simple click — item is still in its slot, nothing to do.
		original_slot = null
		return

	z_index = 0
	top_level = false

	var pointer := get_global_mouse_position()
	var grid: Node = null
	if original_slot != null:
		grid = original_slot.get_parent()

	var target = null
	if grid != null and grid.has_method("get_slot_at_position"):
		target = grid.get_slot_at_position(pointer)

	print("Drop pointer: ", pointer)
	print("Target slot: ", target)
	print("Grid found: ", grid != null)

	if grid != null and grid.has_method("attempt_drop"):
		grid.attempt_drop(self, target)
	else:
		_force_return_to_origin()

	# Safety: if we still have no parent or are stranded outside the grid, force back.
	if not is_inside_tree() or get_parent() == null or get_parent() == get_tree().root:
		_force_return_to_origin()


func _force_return_to_origin() -> void:
	if original_slot == null:
		queue_free()
		return
	if get_parent() != null:
		get_parent().remove_child(self)
	top_level = false
	z_index = 0
	original_slot.place_item(self)
	original_slot = null
