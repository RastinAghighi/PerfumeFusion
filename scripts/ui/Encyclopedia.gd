extends CanvasLayer

const InfoCardScene := preload("res://scenes/ui/InfoCard.tscn")

const PAGE_SIZE: int = 60
const CARD_MIN_SIZE := Vector2(150, 190)
const CARD_BG := Color(0.14, 0.10, 0.22, 1.0)
const CARD_LOCKED_BG := Color(0.12, 0.10, 0.16, 1.0)

@onready var back_button: Button = $Margin/VBox/TopBar/BackButton
@onready var count_label: Label = $Margin/VBox/TopBar/CountLabel
@onready var tier_all: Button = $Margin/VBox/TierFilter/TierAll
@onready var tier_1: Button = $Margin/VBox/TierFilter/Tier1
@onready var tier_2: Button = $Margin/VBox/TierFilter/Tier2
@onready var tier_3: Button = $Margin/VBox/TierFilter/Tier3
@onready var tier_4: Button = $Margin/VBox/TierFilter/Tier4
@onready var gender_all: Button = $Margin/VBox/GenderFilter/GenderAll
@onready var gender_men: Button = $Margin/VBox/GenderFilter/GenderMen
@onready var gender_women: Button = $Margin/VBox/GenderFilter/GenderWomen
@onready var gender_unisex: Button = $Margin/VBox/GenderFilter/GenderUnisex
@onready var scroll: ScrollContainer = $Margin/VBox/Scroll
@onready var grid: GridContainer = $Margin/VBox/Scroll/ScrollVBox/Grid
@onready var load_more_button: Button = $Margin/VBox/Scroll/ScrollVBox/LoadMoreButton
@onready var empty_label: Label = $Margin/VBox/Scroll/ScrollVBox/EmptyLabel

var _tier_buttons: Array[Button] = []
var _gender_buttons: Array[Button] = []
var _tier_filter: int = 0  # 0=all, 1..4 = tier brackets of 5
var _gender_filter: String = "all"

var _unlocked_set: Dictionary = {}
var _filtered: Array = []
var _shown_count: int = 0


func _ready() -> void:
	back_button.pressed.connect(_on_back_pressed)

	_tier_buttons = [tier_all, tier_1, tier_2, tier_3, tier_4]
	_gender_buttons = [gender_all, gender_men, gender_women, gender_unisex]
	for i in range(_tier_buttons.size()):
		var idx := i
		_tier_buttons[i].pressed.connect(func(): _on_tier_filter(idx))
	var gender_keys: Array[String] = ["all", "men", "women", "unisex"]
	for i in range(_gender_buttons.size()):
		var key: String = gender_keys[i]
		_gender_buttons[i].pressed.connect(func(): _on_gender_filter(key))

	load_more_button.pressed.connect(_on_load_more_pressed)

	_build_unlocked_set()
	_apply_filters()


func _build_unlocked_set() -> void:
	_unlocked_set.clear()
	var unlocked: Variant = SaveManager.data.get("unlocked_perfumes", [])
	if typeof(unlocked) != TYPE_ARRAY:
		return
	for url in unlocked:
		_unlocked_set[String(url)] = true


func _on_tier_filter(idx: int) -> void:
	_tier_filter = idx
	for i in range(_tier_buttons.size()):
		_tier_buttons[i].set_pressed_no_signal(i == idx)
	_apply_filters()


func _on_gender_filter(key: String) -> void:
	_gender_filter = key
	var keys := ["all", "men", "women", "unisex"]
	for i in range(_gender_buttons.size()):
		_gender_buttons[i].set_pressed_no_signal(keys[i] == key)
	_apply_filters()


func _apply_filters() -> void:
	_filtered.clear()
	var tier_min := 1
	var tier_max := 20
	if _tier_filter > 0:
		tier_min = (_tier_filter - 1) * 5 + 1
		tier_max = _tier_filter * 5

	for perfume in DataManager.perfumes:
		if typeof(perfume) != TYPE_DICTIONARY:
			continue
		if not perfume.has("rating"):
			continue
		if _tier_filter > 0:
			var t: int = DataManager.get_tier_for_rating(float(perfume["rating"]))
			if t < tier_min or t > tier_max:
				continue
		if _gender_filter != "all":
			var g: String = String(perfume.get("gender", "")).to_lower()
			if not _gender_matches(g, _gender_filter):
				continue
		_filtered.append(perfume)

	_update_count_label()

	for child in grid.get_children():
		child.queue_free()
	_shown_count = 0

	scroll.scroll_vertical = 0
	empty_label.visible = _filtered.is_empty()
	load_more_button.visible = not _filtered.is_empty()
	_show_next_page()


func _gender_matches(gender_value: String, filter_key: String) -> bool:
	match filter_key:
		"men":
			return gender_value == "men" or gender_value == "male"
		"women":
			return gender_value == "women" or gender_value == "female"
		"unisex":
			return gender_value == "unisex" or gender_value == "" or gender_value == "u"
		_:
			return true


func _update_count_label() -> void:
	var discovered := _unlocked_set.size()
	var total: int = DataManager.perfumes.size()
	count_label.text = "%s / %s" % [_format_number(discovered), _format_number(total)]


func _format_number(n: int) -> String:
	var s := str(n)
	var out := ""
	var count := 0
	for i in range(s.length() - 1, -1, -1):
		out = s[i] + out
		count += 1
		if count % 3 == 0 and i > 0:
			out = "," + out
	return out


func _show_next_page() -> void:
	var end: int = min(_shown_count + PAGE_SIZE, _filtered.size())
	for i in range(_shown_count, end):
		var perfume: Dictionary = _filtered[i]
		grid.add_child(_make_card(perfume))
	_shown_count = end
	load_more_button.visible = _shown_count < _filtered.size()


func _on_load_more_pressed() -> void:
	_show_next_page()


func _make_card(perfume: Dictionary) -> Control:
	var url := String(perfume.get("url", ""))
	var unlocked: bool = _unlocked_set.has(url) and url != ""

	var card := Button.new()
	card.custom_minimum_size = CARD_MIN_SIZE
	card.toggle_mode = false
	card.focus_mode = Control.FOCUS_NONE
	card.flat = true

	var sb := StyleBoxFlat.new()
	sb.bg_color = CARD_BG if unlocked else CARD_LOCKED_BG
	sb.corner_radius_top_left = 12
	sb.corner_radius_top_right = 12
	sb.corner_radius_bottom_left = 12
	sb.corner_radius_bottom_right = 12
	sb.border_width_left = 1
	sb.border_width_top = 1
	sb.border_width_right = 1
	sb.border_width_bottom = 1
	sb.border_color = Color(0.4, 0.32, 0.6, 0.6) if unlocked else Color(0.25, 0.22, 0.34, 0.6)
	sb.content_margin_left = 8
	sb.content_margin_right = 8
	sb.content_margin_top = 10
	sb.content_margin_bottom = 10
	card.add_theme_stylebox_override("normal", sb)
	card.add_theme_stylebox_override("hover", sb)
	card.add_theme_stylebox_override("pressed", sb)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 6)
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	card.add_child(vbox)

	var bottle := ColorRect.new()
	bottle.custom_minimum_size = Vector2(80, 100)
	bottle.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	bottle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if unlocked:
		bottle.color = _perfume_color(perfume)
	else:
		bottle.color = Color(0.18, 0.16, 0.24, 1.0)
	vbox.add_child(bottle)

	var name_label := Label.new()
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_label.clip_text = true
	name_label.add_theme_font_size_override("font_size", 12)
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if unlocked:
		name_label.text = _prettify(String(perfume.get("name", "Unknown")))
		name_label.add_theme_color_override("font_color", Color(1, 0.95, 0.85, 1))
	else:
		name_label.text = "???"
		name_label.add_theme_color_override("font_color", Color(0.55, 0.5, 0.65, 1))
	vbox.add_child(name_label)

	if unlocked:
		card.pressed.connect(func(): _open_info_card(perfume))

	return card


func _perfume_color(perfume: Dictionary) -> Color:
	var accords: Variant = perfume.get("accords", [])
	if typeof(accords) == TYPE_ARRAY and (accords as Array).size() > 0:
		return DataManager.get_accord_color(String(accords[0]))
	return Color(0.6, 0.5, 0.8, 1.0)


func _prettify(s: String) -> String:
	return s.replace("-", " ").replace("_", " ").capitalize()


func _open_info_card(perfume: Dictionary) -> void:
	var card := InfoCardScene.instantiate()
	var tier: int = DataManager.get_tier_for_rating(float(perfume.get("rating", 0.0)))
	get_tree().root.add_child(card)
	card.show_perfume(perfume, tier)


func _on_back_pressed() -> void:
	queue_free()
