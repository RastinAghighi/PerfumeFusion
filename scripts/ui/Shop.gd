extends CanvasLayer

const CARD_BG := Color(0.14, 0.10, 0.22, 1.0)
const CARD_BORDER := Color(0.4, 0.32, 0.6, 0.6)

@onready var back_button: Button = $Margin/VBox/TopBar/BackButton
@onready var essence_label: Label = $Margin/VBox/TopBar/EssenceLabel
@onready var cards_vbox: VBoxContainer = $Margin/VBox/Scroll/CardsVBox

var _upgrades: Array = []
var _card_nodes: Array = []


func _ready() -> void:
	back_button.pressed.connect(_on_back_pressed)
	EconomyManager.essence_changed.connect(_on_essence_changed)
	_upgrades = _build_upgrade_defs()
	_build_cards()
	_refresh()


func _build_upgrade_defs() -> Array:
	return [
		{
			"key": "spawn_speed_level",
			"name": "Faster Spawns",
			"desc": "Perfumes appear more frequently",
			"effect": "3.0s → 2.5s → 2.0s → 1.5s",
			"costs": [500, 2000, 8000],
			"max_level": 3,
			"is_bool": false,
		},
		{
			"key": "offline_rate_level",
			"name": "Offline Earnings",
			"desc": "Earn more while you're away",
			"effect": "1/s → 2/s → 4/s → 8/s",
			"costs": [300, 1200, 5000],
			"max_level": 3,
			"is_bool": false,
		},
		{
			"key": "offline_cap_level",
			"name": "Offline Storage",
			"desc": "Store more offline earnings",
			"effect": "8h → 12h → 24h",
			"costs": [1000, 5000],
			"max_level": 2,
			"is_bool": false,
		},
		{
			"key": "lucky_merge_level",
			"name": "Lucky Merges",
			"desc": "Chance to jump 2 tiers on merge",
			"effect": "0% → 10% → 20%",
			"costs": [2000, 8000],
			"max_level": 2,
			"is_bool": false,
		},
		{
			"key": "extra_grid",
			"name": "Extra Columns",
			"desc": "More room to merge",
			"effect": "25 slots → 30 slots",
			"costs": [50000],
			"max_level": 1,
			"is_bool": true,
		},
	]


func _build_cards() -> void:
	_card_nodes.clear()
	for child in cards_vbox.get_children():
		child.queue_free()
	for i in range(_upgrades.size()):
		var def: Dictionary = _upgrades[i]
		var card := _make_card(def, i)
		cards_vbox.add_child(card)
		_card_nodes.append(card)


func _make_card(def: Dictionary, idx: int) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(0, 96)
	var sb := StyleBoxFlat.new()
	sb.bg_color = CARD_BG
	sb.corner_radius_top_left = 12
	sb.corner_radius_top_right = 12
	sb.corner_radius_bottom_left = 12
	sb.corner_radius_bottom_right = 12
	sb.border_width_left = 1
	sb.border_width_top = 1
	sb.border_width_right = 1
	sb.border_width_bottom = 1
	sb.border_color = CARD_BORDER
	sb.content_margin_left = 16
	sb.content_margin_right = 16
	sb.content_margin_top = 12
	sb.content_margin_bottom = 12
	panel.add_theme_stylebox_override("panel", sb)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 16)
	panel.add_child(hbox)

	var left := VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.add_theme_constant_override("separation", 4)
	hbox.add_child(left)

	var name_label := Label.new()
	name_label.text = String(def["name"])
	name_label.add_theme_font_size_override("font_size", 20)
	name_label.add_theme_color_override("font_color", Color(1, 0.95, 0.85, 1))
	left.add_child(name_label)

	var desc_label := Label.new()
	desc_label.text = String(def["desc"])
	desc_label.add_theme_font_size_override("font_size", 14)
	desc_label.add_theme_color_override("font_color", Color(0.75, 0.7, 0.88, 1))
	left.add_child(desc_label)

	var effect_label := Label.new()
	effect_label.name = "EffectLabel"
	effect_label.add_theme_font_size_override("font_size", 13)
	effect_label.add_theme_color_override("font_color", Color(0.6, 0.55, 0.75, 1))
	left.add_child(effect_label)

	var right := VBoxContainer.new()
	right.alignment = BoxContainer.ALIGNMENT_CENTER
	right.custom_minimum_size = Vector2(200, 0)
	right.add_theme_constant_override("separation", 6)
	hbox.add_child(right)

	var level_label := Label.new()
	level_label.name = "LevelLabel"
	level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	level_label.add_theme_font_size_override("font_size", 14)
	level_label.add_theme_color_override("font_color", Color(0.85, 0.78, 0.95, 1))
	right.add_child(level_label)

	var buy_button := Button.new()
	buy_button.name = "BuyButton"
	buy_button.custom_minimum_size = Vector2(180, 44)
	buy_button.add_theme_font_size_override("font_size", 16)
	buy_button.pressed.connect(func(): _on_buy_pressed(idx))
	right.add_child(buy_button)

	return panel


func _refresh() -> void:
	essence_label.text = "✦ %d" % EconomyManager.get_essence()
	var upgrades_data: Dictionary = SaveManager.data.get("upgrades", {})
	for i in range(_upgrades.size()):
		var def: Dictionary = _upgrades[i]
		var card: PanelContainer = _card_nodes[i]
		var level_label: Label = _find_label(card, "LevelLabel")
		var effect_label: Label = _find_label(card, "EffectLabel")
		var buy_button: Button = _find_button(card, "BuyButton")
		var max_level: int = int(def["max_level"])
		var is_bool: bool = bool(def["is_bool"])
		var current_level: int = 0
		if is_bool:
			current_level = 1 if bool(upgrades_data.get(def["key"], false)) else 0
		else:
			current_level = int(upgrades_data.get(def["key"], 0))

		var segments: PackedStringArray = String(def["effect"]).split(" → ")
		var is_maxed: bool = current_level >= max_level
		if is_maxed:
			if segments.size() > 0:
				effect_label.text = "Current: %s" % segments[segments.size() - 1]
			else:
				effect_label.text = ""
		else:
			var cur_idx: int = min(current_level, segments.size() - 1)
			var next_idx: int = min(current_level + 1, segments.size() - 1)
			effect_label.text = "%s → %s" % [segments[cur_idx], segments[next_idx]]

		if is_bool:
			level_label.text = "Owned" if is_maxed else "Not Owned"
		else:
			level_label.text = "MAX" if is_maxed else "Lv. %d" % current_level

		if is_maxed:
			buy_button.text = "MAX"
			buy_button.disabled = true
			buy_button.modulate = Color(0.7, 0.7, 0.7, 1)
		else:
			var cost: int = int((def["costs"] as Array)[current_level])
			buy_button.text = "Buy  ✦%d" % cost
			buy_button.disabled = false
			buy_button.modulate = Color(1, 1, 1, 1)


func _find_label(root: Node, node_name: String) -> Label:
	for child in _iter_descendants(root):
		if child is Label and child.name == node_name:
			return child
	return null


func _find_button(root: Node, node_name: String) -> Button:
	for child in _iter_descendants(root):
		if child is Button and child.name == node_name:
			return child
	return null


func _iter_descendants(root: Node) -> Array:
	var out: Array = []
	var stack: Array = [root]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		for c in n.get_children():
			out.append(c)
			stack.append(c)
	return out


func _on_buy_pressed(idx: int) -> void:
	var def: Dictionary = _upgrades[idx]
	var upgrades_data: Dictionary = SaveManager.data.get("upgrades", {})
	var is_bool: bool = bool(def["is_bool"])
	var max_level: int = int(def["max_level"])
	var current_level: int = 0
	if is_bool:
		current_level = 1 if bool(upgrades_data.get(def["key"], false)) else 0
	else:
		current_level = int(upgrades_data.get(def["key"], 0))

	if current_level >= max_level:
		return

	var cost: int = int((def["costs"] as Array)[current_level])
	if not EconomyManager.spend_essence(cost):
		_flash_button_red(idx)
		return

	if is_bool:
		upgrades_data[def["key"]] = true
	else:
		upgrades_data[def["key"]] = current_level + 1
	SaveManager.data["upgrades"] = upgrades_data
	SaveManager.save_game()
	_refresh()


func _flash_button_red(idx: int) -> void:
	var card: PanelContainer = _card_nodes[idx]
	var buy_button: Button = _find_button(card, "BuyButton")
	if buy_button == null:
		return
	buy_button.modulate = Color(1, 0.3, 0.3, 1)
	var tween := buy_button.create_tween()
	tween.tween_property(buy_button, "modulate", Color(1, 1, 1, 1), 0.5)


func _on_essence_changed(_amount: int) -> void:
	_refresh()


func _on_back_pressed() -> void:
	queue_free()
