extends Control

signal intro_finished

@onready var vbox: VBoxContainer = $ScrollContainer/CenterMargin/Center/VBox


func _ready() -> void:
	print("OpponentIntro _ready — children of VBox:")
	for child in vbox.get_children():
		print("  ", child.name, " - ", child.get_class())
	var fb: Button = vbox.get_node("FightButton") as Button
	print("FightButton found: ", fb, " connections: ", fb.pressed.get_connections())
	if not fb.pressed.is_connected(_on_fight_pressed):
		fb.pressed.connect(_on_fight_pressed)
		print("Connected FightButton.pressed in _ready")


func setup(opponent: Dictionary) -> void:
	var opp_name: String = str(opponent.get("name", "???"))
	var title: String = str(opponent.get("title", ""))
	var description: String = str(opponent.get("description", ""))
	var hp: int = int(opponent.get("hp", 100))
	var time_limit: int = int(opponent.get("time_limit", 120))
	var weaknesses: Array = opponent.get("weakness", [])
	var resistances: Array = opponent.get("resistance", [])

	# Initials for portrait placeholder
	var initials: String = ""
	var parts: PackedStringArray = opp_name.split(" ")
	for p in parts:
		if p.length() > 0:
			initials += p[0].to_upper()
	if initials.length() == 0:
		initials = "?"
	vbox.get_node("Portrait/InitialsLabel").text = initials

	vbox.get_node("NameLabel").text = opp_name

	if title != "":
		vbox.get_node("TitleLabel").text = '"%s"' % title
	else:
		vbox.get_node("TitleLabel").text = ""

	vbox.get_node("DescLabel").text = description

	vbox.get_node("StatsRow/HPBox/HPValue").text = str(hp)

	var minutes: int = time_limit / 60
	var seconds: int = time_limit % 60
	vbox.get_node("StatsRow/TimeBox/TimeValue").text = "%d:%02d" % [minutes, seconds]

	# Weakness tags
	var weak_row: HBoxContainer = vbox.get_node("WeakRow")
	for w in weaknesses:
		var tag := _create_tag(str(w), Color(0.3, 0.85, 0.3, 1.0), Color(0.15, 0.3, 0.15, 1.0))
		weak_row.add_child(tag)
		weak_row.move_child(tag, weak_row.get_child_count() - 2)
	if weaknesses.size() == 0:
		weak_row.visible = false

	# Resistance tags
	var resist_row: HBoxContainer = vbox.get_node("ResistRow")
	for r in resistances:
		var tag := _create_tag(str(r), Color(1.0, 0.45, 0.45, 1.0), Color(0.35, 0.15, 0.15, 1.0))
		resist_row.add_child(tag)
		resist_row.move_child(tag, resist_row.get_child_count() - 2)
	if resistances.size() == 0:
		resist_row.visible = false


func _create_tag(text: String, font_color: Color, bg_color: Color) -> PanelContainer:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = bg_color
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_right = 6
	style.corner_radius_bottom_left = 6
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 4
	style.content_margin_bottom = 4
	panel.add_theme_stylebox_override("panel", style)

	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 13)
	label.add_theme_color_override("font_color", font_color)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(label)

	return panel


func _on_fight_pressed() -> void:
	print("FIGHT button pressed")
	print("FIGHT! Starting battle...")
	vbox.get_node("FightButton").disabled = true
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	tween.tween_callback(_finish)


func _finish() -> void:
	emit_signal("intro_finished")
	queue_free()
