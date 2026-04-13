extends Node

const PERFUMES_PATH := "res://data/perfumes_filtered.json"
const TIER_COUNT := 20

var perfumes: Array = []
var tier_brackets: Dictionary = {}
var tier_rating_bounds: Array = []

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
	var valid: Array = []
	for perfume in perfumes:
		if typeof(perfume) != TYPE_DICTIONARY:
			continue
		if not perfume.has("rating"):
			continue
		valid.append(perfume)

	valid.sort_custom(func(a, b): return float(a["rating"]) < float(b["rating"]))

	tier_rating_bounds.clear()
	var n: int = valid.size()
	if n == 0:
		return

	for i in range(1, TIER_COUNT + 1):
		var start: int = int(floor(float((i - 1) * n) / float(TIER_COUNT)))
		var end: int = int(floor(float(i * n) / float(TIER_COUNT)))
		if end > n:
			end = n
		var slice: Array = valid.slice(start, end)
		slice.sort_custom(func(a, b): return int(a.get("votes", 0)) > int(b.get("votes", 0)))
		if slice.size() > 10:
			slice = slice.slice(0, 10)
		tier_brackets[i] = slice
		if i < TIER_COUNT and end < n:
			tier_rating_bounds.append(float(valid[end]["rating"]))


func _print_summary() -> void:
	var parts: Array[String] = []
	var total := 0
	for i in range(1, TIER_COUNT + 1):
		var bracket: Array = tier_brackets[i]
		var c: int = bracket.size()
		total += c
		var lo: String = "-inf"
		var hi: String = "+inf"
		if c > 0:
			lo = "%.2f" % float(bracket[0]["rating"])
			hi = "%.2f" % float(bracket[c - 1]["rating"])
		parts.append("T%d [%s-%s]: %d" % [i, lo, hi, c])
	print("DataManager tier distribution: %s. Total: %d" % [", ".join(parts), total])


func get_random_perfume(tier: int) -> Dictionary:
	if not tier_brackets.has(tier):
		return {}
	var bracket: Array = tier_brackets[tier]
	if bracket.is_empty():
		return {}
	return bracket[randi() % bracket.size()]


func get_tier_for_rating(rating: float) -> int:
	for i in range(tier_rating_bounds.size()):
		if rating < float(tier_rating_bounds[i]):
			return i + 1
	return TIER_COUNT


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


func get_accord_color(accord: String) -> Color:
	var key := accord.to_lower().strip_edges()
	if key.is_empty():
		return DEFAULT_COLOR
	if ACCORD_COLORS.has(key):
		return ACCORD_COLORS[key]
	for token in ACCORD_COLORS.keys():
		if key.find(token) != -1:
			return ACCORD_COLORS[token]
	return DEFAULT_COLOR


func find_perfume(url: String, name: String, brand: String) -> Dictionary:
	var url_key := url.strip_edges()
	var name_key := name.strip_edges().to_lower()
	var brand_key := brand.strip_edges().to_lower()
	for i in range(1, TIER_COUNT + 1):
		var bracket: Array = tier_brackets.get(i, [])
		for perfume in bracket:
			if typeof(perfume) != TYPE_DICTIONARY:
				continue
			if url_key != "" and String(perfume.get("url", "")) == url_key:
				return perfume
			if name_key != "" and String(perfume.get("name", "")).to_lower() == name_key \
				and (brand_key == "" or String(perfume.get("brand", "")).to_lower() == brand_key):
				return perfume
	return {}


func get_tier_count(tier: int) -> int:
	if not tier_brackets.has(tier):
		return 0
	return (tier_brackets[tier] as Array).size()
