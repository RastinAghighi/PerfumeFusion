extends CanvasLayer

var current_screen := 0
var screens: Array[Dictionary] = []
var overlay: ColorRect
var panel: PanelContainer
var title_label: Label
var body_label: Label
var button: Button
var arrow_label: Label

func _ready() -> void:
	layer = 10
	_build_screens()
	_build_ui()
	_show_screen(0)

func _build_screens() -> void:
	screens = [
		{
			"title": "Welcome to PerfumeFusion!",
			"body": "Discover the world's finest fragrances",
			"arrow": "",
			"arrow_pos": Vector2.ZERO,
			"button_text": "Next",
		},
		{
			"title": "Spawn Perfumes",
			"body": "Tap here to create new perfumes",
			"arrow": "▼",
			"arrow_pos": Vector2(0.5, 1.0),
			"arrow_offset": Vector2(0, -160),
			"button_text": "Next",
		},
		{
			"title": "Fuse Perfumes",
			"body": "Drag matching perfumes together\nto fuse them into rarer ones",
			"arrow": "",
			"arrow_pos": Vector2.ZERO,
			"button_text": "Next",
		},
		{
			"title": "Earn Essence",
			"body": "Earn Essence from every fusion.\nSpend it to spawn more perfumes\nor buy upgrades",
			"arrow": "▼",
			"arrow_pos": Vector2(0.15, 0.0),
			"arrow_offset": Vector2(0, 70),
			"button_text": "Next",
		},
		{
			"title": "Sell Perfumes",
			"body": "Don't need a perfume?\nDrag it here to sell for Essence",
			"arrow": "▼",
			"arrow_pos": Vector2(0.5, 1.0),
			"arrow_offset": Vector2(0, -220),
			"button_text": "Next",
		},
		{
			"title": "Discover All 200 Fragrances",
			"body": "Good luck!",
			"arrow": "",
			"arrow_pos": Vector2.ZERO,
			"button_text": "Let's Go!",
		},
	]

func _build_ui() -> void:
	overlay = ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.75)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(overlay)

	panel = PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.anchor_left = 0.1
	panel.anchor_right = 0.9
	panel.anchor_top = 0.3
	panel.anchor_bottom = 0.7
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.09, 0.18, 0.95)
	style.border_color = Color(0.45, 0.32, 0.7)
	style.set_border_width_all(2)
	style.set_corner_radius_all(12)
	style.set_content_margin_all(24)
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 16)
	panel.add_child(vbox)

	title_label = Label.new()
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 28)
	title_label.add_theme_color_override("font_color", Color(0.95, 0.78, 0.32))
	vbox.add_child(title_label)

	body_label = Label.new()
	body_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body_label.add_theme_font_size_override("font_size", 18)
	body_label.add_theme_color_override("font_color", Color(0.9, 0.85, 0.95))
	body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(body_label)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 8)
	vbox.add_child(spacer)

	button = Button.new()
	button.custom_minimum_size = Vector2(160, 48)
	button.add_theme_font_size_override("font_size", 20)
	var btn_normal := StyleBoxFlat.new()
	btn_normal.bg_color = Color(0.18, 0.14, 0.28)
	btn_normal.border_color = Color(0.45, 0.32, 0.7)
	btn_normal.set_border_width_all(2)
	btn_normal.set_corner_radius_all(10)
	btn_normal.set_content_margin_all(8)
	button.add_theme_stylebox_override("normal", btn_normal)
	var btn_hover := StyleBoxFlat.new()
	btn_hover.bg_color = Color(0.26, 0.2, 0.4)
	btn_hover.border_color = Color(0.65, 0.48, 0.95)
	btn_hover.set_border_width_all(2)
	btn_hover.set_corner_radius_all(10)
	btn_hover.set_content_margin_all(8)
	button.add_theme_stylebox_override("hover", btn_hover)
	var btn_pressed := StyleBoxFlat.new()
	btn_pressed.bg_color = Color(0.12, 0.09, 0.2)
	btn_pressed.border_color = Color(0.55, 0.4, 0.85)
	btn_pressed.set_border_width_all(2)
	btn_pressed.set_corner_radius_all(10)
	btn_pressed.set_content_margin_all(8)
	button.add_theme_stylebox_override("pressed", btn_pressed)
	button.pressed.connect(_on_next)
	vbox.add_child(button)

	arrow_label = Label.new()
	arrow_label.add_theme_font_size_override("font_size", 48)
	arrow_label.add_theme_color_override("font_color", Color(0.95, 0.78, 0.32))
	arrow_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	arrow_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	add_child(arrow_label)

func _show_screen(index: int) -> void:
	var screen: Dictionary = screens[index]
	title_label.text = screen["title"]
	body_label.text = screen["body"]
	button.text = screen["button_text"]

	var arrow_text: String = screen["arrow"]
	arrow_label.text = arrow_text
	arrow_label.visible = arrow_text != ""

	if arrow_text != "":
		var vp_size: Vector2 = get_viewport().get_visible_rect().size
		var pos: Vector2 = screen["arrow_pos"]
		var offset: Vector2 = screen.get("arrow_offset", Vector2.ZERO)
		arrow_label.position = Vector2(pos.x * vp_size.x, pos.y * vp_size.y) + offset
		arrow_label.position.x -= 24

func _on_next() -> void:
	current_screen += 1
	if current_screen >= screens.size():
		_complete_tutorial()
	else:
		_show_screen(current_screen)

func _complete_tutorial() -> void:
	SaveManager.data["tutorial_completed"] = true
	SaveManager.save_game()
	queue_free()
