extends Control

var tier: int = 0
var perfume_data: Dictionary = {}


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
