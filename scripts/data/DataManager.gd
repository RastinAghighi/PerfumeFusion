extends Node

const PERFUMES_PATH := "res://data/perfumes.json"
const TIER_COUNT := 20

var perfumes: Array = []
var tier_brackets: Dictionary = {}

const ACCORD_COLORS := {
	"floral": Color("#E91E63"),
	"woody": Color("#795548"),
	"citrus": Color("#FFC107"),
	"musky": Color("#9E9E9E"),
	"musk": Color("#9E9E9E"),
	"sweet": Color("#FFE0B2"),
	"vanilla": Color("#FFE0B2"),
	"fresh": Color("#03A9F4"),
	"aquatic": Color("#03A9F4"),
	"spicy": Color("#F44336"),
	"amber": Color("#FF9800"),
	"fruity": Color("#9C27B0"),
}
const DEFAULT_COLOR := Color("#FFFFFF")


func _ready() -> void:
	for i in range(1, TIER_COUNT + 1):
		tier_brackets[i] = []

	_load_perfumes()
	_bucket_perfumes()
	_print_summary()


func _load_perfumes() -> void:
	if not FileAccess.file_exists(PERFUMES_PATH):
		push_error("DataManager: perfumes.json not found at %s" % PERFUMES_PATH)
		return

	var file := FileAccess.open(PERFUMES_PATH, FileAccess.READ)
	var text := file.get_as_text()
	file.close()

	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_ARRAY:
		push_error("DataManager: perfumes.json did not parse to an Array")
		return

	perfumes = parsed


func _bucket_perfumes() -> void:
	for perfume in perfumes:
		if typeof(perfume) != TYPE_DICTIONARY:
			continue
		if not perfume.has("rating"):
			continue
		var rating: float = float(perfume["rating"])
		var tier := get_tier_for_rating(rating)
		if tier >= 1 and tier <= TIER_COUNT:
			tier_brackets[tier].append(perfume)


func _print_summary() -> void:
	var parts: Array[String] = []
	var total := 0
	for i in range(1, TIER_COUNT + 1):
		var c: int = tier_brackets[i].size()
		total += c
		parts.append("Tier %d: %d perfumes" % [i, c])
	print("DataManager loaded. %s. Total: %d" % [", ".join(parts), total])


func get_random_perfume(tier: int) -> Dictionary:
	if not tier_brackets.has(tier):
		return {}
	var bracket: Array = tier_brackets[tier]
	if bracket.is_empty():
		return {}
	return bracket[randi() % bracket.size()]


func get_tier_for_rating(rating: float) -> int:
	if rating < 1.50: return 1
	if rating < 1.80: return 2
	if rating < 2.10: return 3
	if rating < 2.40: return 4
	if rating < 2.60: return 5
	if rating < 2.80: return 6
	if rating < 3.00: return 7
	if rating < 3.15: return 8
	if rating < 3.30: return 9
	if rating < 3.45: return 10
	if rating < 3.60: return 11
	if rating < 3.75: return 12
	if rating < 3.90: return 13
	if rating < 4.05: return 14
	if rating < 4.20: return 15
	if rating < 4.35: return 16
	if rating < 4.50: return 17
	if rating < 4.65: return 18
	if rating < 4.80: return 19
	return 20


func get_tier_color(tier: int) -> Color:
	if not tier_brackets.has(tier):
		return DEFAULT_COLOR
	var bracket: Array = tier_brackets[tier]
	if bracket.is_empty():
		return DEFAULT_COLOR

	var counts: Dictionary = {}
	for perfume in bracket:
		if typeof(perfume) != TYPE_DICTIONARY:
			continue
		var accords: Variant = perfume.get("accords", [])
		if typeof(accords) != TYPE_ARRAY:
			continue
		for accord in accords:
			var key := String(accord).to_lower().strip_edges()
			if key.is_empty():
				continue
			counts[key] = int(counts.get(key, 0)) + 1

	if counts.is_empty():
		return DEFAULT_COLOR

	var best_key := ""
	var best_count := -1
	for key in counts.keys():
		var c: int = counts[key]
		if c > best_count:
			best_count = c
			best_key = key

	if ACCORD_COLORS.has(best_key):
		return ACCORD_COLORS[best_key]
	for token in ACCORD_COLORS.keys():
		if best_key.find(token) != -1:
			return ACCORD_COLORS[token]
	return DEFAULT_COLOR


func get_tier_count(tier: int) -> int:
	if not tier_brackets.has(tier):
		return 0
	return (tier_brackets[tier] as Array).size()
