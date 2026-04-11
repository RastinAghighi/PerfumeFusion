extends Node

signal essence_changed(new_amount: int)

var essence: int = 0


func _ready() -> void:
	essence = int(SaveManager.data.get("essence", 0))


func add_essence(amount: int) -> void:
	essence += amount
	SaveManager.data["essence"] = essence
	emit_signal("essence_changed", essence)


func spend_essence(amount: int) -> bool:
	if essence < amount:
		return false
	essence -= amount
	SaveManager.data["essence"] = essence
	emit_signal("essence_changed", essence)
	return true


func get_essence() -> int:
	return essence


func get_merge_reward(tier: int) -> int:
	return 10 * tier


func get_manual_buy_cost(tier: int) -> int:
	match tier:
		1:
			return 10
		2:
			return 50
		3:
			return 200
		4:
			return 800
		_:
			return int(800 * pow(3, tier - 4))
