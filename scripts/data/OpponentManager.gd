extends Node

var opponents: Array = []
var selected_opponent_id: int = -1


func _ready() -> void:
	var file := FileAccess.open("res://data/opponents.json", FileAccess.READ)
	if file == null:
		push_error("OpponentManager: failed to load opponents.json")
		return
	var text := file.get_as_text()
	file.close()
	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_ARRAY:
		push_error("OpponentManager: opponents.json is not an array")
		return
	opponents = parsed
	print("OpponentManager loaded. %d opponents." % opponents.size())


func get_opponent(id: int) -> Dictionary:
	for opponent in opponents:
		if int(opponent["id"]) == id:
			return opponent
	return {}


func get_all_opponents() -> Array:
	return opponents


func get_unlocked_opponents() -> Array:
	var beaten_count: int = SaveManager.data.get("beaten_opponents", []).size()
	var unlocked: Array = []
	for opponent in opponents:
		if int(opponent["unlock_requirement"]) <= beaten_count:
			unlocked.append(opponent)
	return unlocked


func is_opponent_beaten(id: int) -> bool:
	var beaten: Array = SaveManager.data.get("beaten_opponents", [])
	return id in beaten
