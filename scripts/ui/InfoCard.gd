extends CanvasLayer

@onready var holder: Control = $Holder
@onready var name_label: Label = $Holder/Card/Margin/VBox/NameLabel
@onready var brand_label: Label = $Holder/Card/Margin/VBox/BrandLabel
@onready var rating_label: Label = $Holder/Card/Margin/VBox/RatingRow/RatingLabel
@onready var votes_label: Label = $Holder/Card/Margin/VBox/RatingRow/VotesLabel
@onready var gender_row: HBoxContainer = $Holder/Card/Margin/VBox/GenderRow
@onready var gender_badge: Panel = $Holder/Card/Margin/VBox/GenderRow/GenderBadge
@onready var gender_label: Label = $Holder/Card/Margin/VBox/GenderRow/GenderBadge/GenderLabel
@onready var top_notes_label: Label = $Holder/Card/Margin/VBox/TopNotesValue
@onready var heart_notes_label: Label = $Holder/Card/Margin/VBox/HeartNotesValue
@onready var base_notes_label: Label = $Holder/Card/Margin/VBox/BaseNotesValue
@onready var accord_box: HBoxContainer = $Holder/Card/Margin/VBox/AccordBox
@onready var nice_button: Button = $Holder/Card/Margin/VBox/NiceButton

var _pending_data: Dictionary = {}
var _pending_tier: int = 0


func _ready() -> void:
	nice_button.pressed.connect(_on_nice_pressed)
	if not _pending_data.is_empty():
		_populate(_pending_data, _pending_tier)
	_animate_in()


func show_perfume(perfume_data: Dictionary, tier: int) -> void:
	if is_node_ready():
		_populate(perfume_data, tier)
	else:
		_pending_data = perfume_data
		_pending_tier = tier


func _populate(perfume_data: Dictionary, _tier: int) -> void:
	name_label.text = _prettify(String(perfume_data.get("name", "Unknown")))
	brand_label.text = _prettify(String(perfume_data.get("brand", "")))

	var rating: float = float(perfume_data.get("rating", 0.0))
	rating_label.text = "★ %.2f" % rating
	var votes: int = int(perfume_data.get("votes", 0))
	votes_label.text = "(%s votes)" % _format_number(votes)

	var gender: String = String(perfume_data.get("gender", "")).to_lower()
	_apply_gender_badge(gender)

	top_notes_label.text = _join_notes(perfume_data.get("notes_top", []))
	heart_notes_label.text = _join_notes(perfume_data.get("notes_middle", []))
	base_notes_label.text = _join_notes(perfume_data.get("notes_base", []))

	_populate_accords(perfume_data.get("accords", []))


func _join_notes(notes: Variant) -> String:
	if typeof(notes) != TYPE_ARRAY or (notes as Array).is_empty():
		return "—"
	var pretty: Array[String] = []
	for note in notes:
		pretty.append(_prettify(String(note)))
	return ", ".join(pretty)


func _prettify(s: String) -> String:
	return s.replace("-", " ").replace("_", " ").capitalize()


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


func _apply_gender_badge(gender: String) -> void:
	var text := "⚤ Unisex"
	var color := Color("#7E57C2")
	if gender == "men" or gender == "male":
		text = "♂ Men"
		color = Color("#1E88E5")
	elif gender == "women" or gender == "female":
		text = "♀ Women"
		color = Color("#E91E63")
	gender_label.text = text
	var sb := StyleBoxFlat.new()
	sb.bg_color = color
	sb.corner_radius_top_left = 12
	sb.corner_radius_top_right = 12
	sb.corner_radius_bottom_left = 12
	sb.corner_radius_bottom_right = 12
	sb.content_margin_left = 14
	sb.content_margin_right = 14
	sb.content_margin_top = 6
	sb.content_margin_bottom = 6
	gender_badge.add_theme_stylebox_override("panel", sb)


func _populate_accords(accords: Variant) -> void:
	for child in accord_box.get_children():
		child.queue_free()
	if typeof(accords) != TYPE_ARRAY:
		return
	for accord in accords:
		var name_str := String(accord)
		var tag := _make_accord_tag(name_str)
		accord_box.add_child(tag)


func _make_accord_tag(accord_name: String) -> Control:
	var color: Color = DataManager.get_accord_color(accord_name)
	var sb := StyleBoxFlat.new()
	sb.bg_color = color
	sb.corner_radius_top_left = 10
	sb.corner_radius_top_right = 10
	sb.corner_radius_bottom_left = 10
	sb.corner_radius_bottom_right = 10
	sb.content_margin_left = 12
	sb.content_margin_right = 12
	sb.content_margin_top = 6
	sb.content_margin_bottom = 6

	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", sb)

	var label := Label.new()
	label.text = _prettify(accord_name)
	label.add_theme_font_size_override("font_size", 14)
	var fg := Color.WHITE if color.get_luminance() < 0.6 else Color(0.1, 0.08, 0.16, 1)
	label.add_theme_color_override("font_color", fg)
	panel.add_child(label)
	return panel


func _animate_in() -> void:
	holder.modulate.a = 0.0
	holder.position.y = 240.0
	var tw := create_tween().set_parallel(true)
	tw.tween_property(holder, "position:y", 0.0, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(holder, "modulate:a", 1.0, 0.2)


func _on_nice_pressed() -> void:
	nice_button.disabled = true
	var tw := create_tween().set_parallel(true)
	tw.tween_property(holder, "position:y", 240.0, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_property(holder, "modulate:a", 0.0, 0.25)
	await tw.finished
	queue_free()
