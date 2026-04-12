extends Control

@onready var card_container: VBoxContainer = $Background/MainVBox/ScrollContainer/CardContainer
@onready var essence_label: Label = $Background/MainVBox/TopBar/EssenceLabel
@onready var back_button: Button = $Background/MainVBox/TopBar/BackButton

const ACCORD_COLORS := {
	"floral": Color(0.4, 0.75, 0.45),
	"sweet": Color(0.9, 0.5, 0.65),
	"woody": Color(0.6, 0.42, 0.25),
	"musky": Color(0.55, 0.45, 0.6),
	"citrus": Color(0.95, 0.8, 0.2),
	"fresh": Color(0.3, 0.75, 0.85),
	"amber": Color(0.85, 0.6, 0.2),
	"spicy": Color(0.85, 0.3, 0.2),
	"aquatic": Color(0.2, 0.55, 0.85),
	"fruity": Color(0.9, 0.45, 0.55),
	"powdery": Color(0.8, 0.7, 0.85),
	"earthy": Color(0.5, 0.4, 0.3),
	"vanilla": Color(0.95, 0.88, 0.6),
}


func _ready() -> void:
	back_button.pressed.connect(_on_back)
	back_button.pressed.connect(AudioManager.play_button)
	essence_label.text = "%d Essence" % EconomyManager.get_essence()
	EconomyManager.essence_changed.connect(func(amt: int) -> void: essence_label.text = "%d Essence" % amt)
	_build_card_list()


func _build_card_list() -> void:
	for child in card_container.get_children():
		child.queue_free()

	var all_opponents: Array = OpponentManager.get_all_opponents()
	var unlocked: Array = OpponentManager.get_unlocked_opponents()
	var unlocked_ids: Array = []
	for o in unlocked:
		unlocked_ids.append(int(o["id"]))

	for opponent in all_opponents:
		var oid: int = int(opponent["id"])
		var is_unlocked: bool = oid in unlocked_ids
		var is_beaten: bool = OpponentManager.is_opponent_beaten(oid)
		var card := _create_card(opponent, is_unlocked, is_beaten)
		card_container.add_child(card)


func _create_card(opponent: Dictionary, is_unlocked: bool, is_beaten: bool) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(0, 110)

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.14, 0.11, 0.22, 1) if is_unlocked else Color(0.1, 0.1, 0.1, 0.8)
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	if is_beaten:
		style.border_color = Color(0.3, 0.75, 0.4, 0.8)
	elif is_unlocked:
		style.border_color = Color(0.45, 0.32, 0.7, 0.6)
	else:
		style.border_color = Color(0.3, 0.3, 0.3, 0.4)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	panel.add_theme_stylebox_override("panel", style)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 12)
	panel.add_child(hbox)

	# Left section — number or checkmark
	var left_panel := PanelContainer.new()
	left_panel.custom_minimum_size = Vector2(60, 60)
	var left_style := StyleBoxFlat.new()
	left_style.corner_radius_top_left = 30
	left_style.corner_radius_top_right = 30
	left_style.corner_radius_bottom_left = 30
	left_style.corner_radius_bottom_right = 30
	if is_beaten:
		left_style.bg_color = Color(0.2, 0.6, 0.3, 1)
	elif is_unlocked:
		left_style.bg_color = Color(0.25, 0.18, 0.45, 1)
	else:
		left_style.bg_color = Color(0.15, 0.15, 0.15, 1)
	left_panel.add_theme_stylebox_override("panel", left_style)

	var num_label := Label.new()
	num_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	num_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	num_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	num_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	num_label.add_theme_font_size_override("font_size", 22)
	if is_beaten:
		num_label.text = "✓"
		num_label.add_theme_color_override("font_color", Color(1, 1, 1))
	else:
		num_label.text = "#%d" % int(opponent["id"])
		num_label.add_theme_color_override("font_color", Color(0.7, 0.65, 0.8) if is_unlocked else Color(0.4, 0.4, 0.4))
	left_panel.add_child(num_label)
	hbox.add_child(left_panel)

	# Middle section
	var mid_vbox := VBoxContainer.new()
	mid_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mid_vbox.add_theme_constant_override("separation", 4)
	hbox.add_child(mid_vbox)

	if not is_unlocked:
		var lock_label := Label.new()
		lock_label.text = "🔒 Defeat opponent #%d to unlock" % int(opponent["unlock_requirement"])
		lock_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		lock_label.add_theme_font_size_override("font_size", 16)
		mid_vbox.add_child(lock_label)

		var name_label := Label.new()
		name_label.text = opponent["name"]
		name_label.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4))
		name_label.add_theme_font_size_override("font_size", 18)
		mid_vbox.add_child(name_label)
	else:
		var name_label := Label.new()
		name_label.text = opponent["name"]
		name_label.add_theme_color_override("font_color", Color(1, 0.95, 0.85))
		name_label.add_theme_font_size_override("font_size", 20)
		mid_vbox.add_child(name_label)

		var title_label := Label.new()
		title_label.text = opponent["title"]
		title_label.add_theme_color_override("font_color", Color(0.6, 0.55, 0.7))
		title_label.add_theme_font_size_override("font_size", 14)
		mid_vbox.add_child(title_label)

		var weakness_row := HBoxContainer.new()
		weakness_row.add_theme_constant_override("separation", 6)
		mid_vbox.add_child(weakness_row)
		for accord in opponent.get("weakness", []):
			weakness_row.add_child(_make_accord_tag(accord, false))

		var resist_row := HBoxContainer.new()
		resist_row.add_theme_constant_override("separation", 6)
		mid_vbox.add_child(resist_row)
		for accord in opponent.get("resistance", []):
			resist_row.add_child(_make_accord_tag(accord, true))

	# Right section
	var right_vbox := VBoxContainer.new()
	right_vbox.custom_minimum_size = Vector2(110, 0)
	right_vbox.add_theme_constant_override("separation", 2)
	hbox.add_child(right_vbox)

	var dim := not is_unlocked
	var text_color: Color = Color(0.4, 0.4, 0.4) if dim else Color(0.85, 0.8, 0.95)

	var hp_label := Label.new()
	hp_label.text = "HP: %d" % int(opponent["hp"])
	hp_label.add_theme_color_override("font_color", text_color)
	hp_label.add_theme_font_size_override("font_size", 14)
	hp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	right_vbox.add_child(hp_label)

	var time_label := Label.new()
	var secs: int = int(opponent["time_limit"])
	time_label.text = "%d:%02d" % [secs / 60, secs % 60]
	time_label.add_theme_color_override("font_color", text_color)
	time_label.add_theme_font_size_override("font_size", 14)
	time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	right_vbox.add_child(time_label)

	var reward_label := Label.new()
	reward_label.text = "%d Essence" % int(opponent["reward_essence"])
	reward_label.add_theme_color_override("font_color", Color(0.35, 0.35, 0.35) if dim else Color(0.95, 0.8, 0.2))
	reward_label.add_theme_font_size_override("font_size", 14)
	reward_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	right_vbox.add_child(reward_label)

	if is_unlocked:
		var btn := Button.new()
		btn.text = "Fight!" if not is_beaten else "Rematch"
		btn.custom_minimum_size = Vector2(100, 34)
		btn.add_theme_font_size_override("font_size", 14)
		btn.add_theme_color_override("font_color", Color(1, 1, 1))
		var btn_style := StyleBoxFlat.new()
		btn_style.bg_color = Color(0.55, 0.22, 0.28) if not is_beaten else Color(0.22, 0.5, 0.35)
		btn_style.corner_radius_top_left = 8
		btn_style.corner_radius_top_right = 8
		btn_style.corner_radius_bottom_left = 8
		btn_style.corner_radius_bottom_right = 8
		btn.add_theme_stylebox_override("normal", btn_style)
		var btn_hover := StyleBoxFlat.new()
		btn_hover.bg_color = btn_style.bg_color.lightened(0.15)
		btn_hover.corner_radius_top_left = 8
		btn_hover.corner_radius_top_right = 8
		btn_hover.corner_radius_bottom_left = 8
		btn_hover.corner_radius_bottom_right = 8
		btn.add_theme_stylebox_override("hover", btn_hover)
		btn.add_theme_stylebox_override("pressed", btn_style)
		var oid: int = int(opponent["id"])
		btn.pressed.connect(func() -> void: _on_opponent_selected(oid))
		btn.pressed.connect(AudioManager.play_button)
		right_vbox.add_child(btn)

	return panel


func _make_accord_tag(accord: String, is_resist: bool) -> PanelContainer:
	var tag := PanelContainer.new()
	var tag_style := StyleBoxFlat.new()
	var color: Color = ACCORD_COLORS.get(accord, Color(0.5, 0.5, 0.5))
	if is_resist:
		color = color.lerp(Color(0.7, 0.15, 0.15), 0.5)
	tag_style.bg_color = Color(color.r, color.g, color.b, 0.3)
	tag_style.corner_radius_top_left = 6
	tag_style.corner_radius_top_right = 6
	tag_style.corner_radius_bottom_left = 6
	tag_style.corner_radius_bottom_right = 6
	tag_style.content_margin_left = 8
	tag_style.content_margin_right = 8
	tag_style.content_margin_top = 2
	tag_style.content_margin_bottom = 2
	tag.add_theme_stylebox_override("panel", tag_style)

	var lbl := Label.new()
	lbl.text = accord if not is_resist else "✕ " + accord
	lbl.add_theme_color_override("font_color", color)
	lbl.add_theme_font_size_override("font_size", 12)
	tag.add_child(lbl)
	return tag


func _on_opponent_selected(opponent_id: int) -> void:
	var opponent: Dictionary = OpponentManager.get_opponent(opponent_id)
	if opponent.is_empty():
		return
	print("Starting battle against: " + str(opponent["name"]))


func _on_back() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/MainMenu.tscn")
