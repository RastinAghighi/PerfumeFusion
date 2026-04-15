extends Control

signal intro_finished

@onready var vbox: VBoxContainer = $Center/VBox


func _ready() -> void:
	_fix_mouse_filters(self)
	var fb: Button = vbox.get_node("FightButton") as Button
	fb.mouse_filter = Control.MOUSE_FILTER_STOP
	($Background as Control).mouse_filter = Control.MOUSE_FILTER_STOP
	if not fb.pressed.is_connected(_on_fight_pressed):
		fb.pressed.connect(_on_fight_pressed)


func _fix_mouse_filters(node: Node) -> void:
	if node is Control and not (node is Button):
		(node as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
	for child in node.get_children():
		_fix_mouse_filters(child)


func setup(opponent: Dictionary) -> void:
	var opp_name: String = str(opponent.get("name", "???"))
	var title: String = str(opponent.get("title", ""))
	var description: String = str(opponent.get("description", ""))
	var hp: int = int(opponent.get("hp", 100))
	var time_limit: int = int(opponent.get("time_limit", 120))
	var weaknesses: Array = opponent.get("weakness", [])
	var resistances: Array = opponent.get("resistance", [])

	var initials: String = ""
	for p in opp_name.split(" "):
		if p.length() > 0:
			initials += p[0].to_upper()
	if initials.length() == 0:
		initials = "?"
	vbox.get_node("Portrait/InitialsLabel").text = initials

	vbox.get_node("NameLabel").text = opp_name
	vbox.get_node("TitleLabel").text = '"%s"' % title if title != "" else ""
	vbox.get_node("DescLabel").text = description

	var minutes: int = time_limit / 60
	var seconds: int = time_limit % 60
	vbox.get_node("StatsLabel").text = "HP: %d | Time: %d:%02d" % [hp, minutes, seconds]

	var weak_text: String = _join_list(weaknesses)
	var resist_text: String = _join_list(resistances)
	vbox.get_node("TagsLabel").text = "Weak: %s  |  Resists: %s" % [weak_text, resist_text]


func _join_list(items: Array) -> String:
	if items.size() == 0:
		return "—"
	var parts: PackedStringArray = []
	for item in items:
		parts.append(str(item))
	return ", ".join(parts)


func _on_fight_pressed() -> void:
	(vbox.get_node("FightButton") as Button).disabled = true
	emit_signal("intro_finished")
	queue_free()
