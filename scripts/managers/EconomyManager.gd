extends Node

signal essence_changed(new_amount: int)

const OFFLINE_RATES := [1, 2, 4, 8]
const OFFLINE_CAPS := [28800, 43200, 86400]

var essence: int = 0


func _ready() -> void:
	essence = int(SaveManager.data.get("essence", 0))


func calculate_offline_earnings() -> Dictionary:
	var last: int = int(SaveManager.data.get("last_logout_time", 0))
	if last <= 0:
		return {"essence": 0, "seconds": 0, "can_double": true}
	var now: int = int(Time.get_unix_time_from_system())
	var seconds_away: int = max(0, now - last)
	var rate_level: int = clamp(int(SaveManager.data.get("upgrades", {}).get("offline_rate_level", 0)), 0, OFFLINE_RATES.size() - 1)
	var cap_level: int = clamp(int(SaveManager.data.get("upgrades", {}).get("offline_cap_level", 0)), 0, OFFLINE_CAPS.size() - 1)
	var rate: int = OFFLINE_RATES[rate_level]
	var cap: int = OFFLINE_CAPS[cap_level]
	seconds_away = min(seconds_away, cap)
	return {"essence": seconds_away * rate, "seconds": seconds_away, "can_double": true}


func collect_offline_earnings(double: bool) -> void:
	var offline: Dictionary = calculate_offline_earnings()
	var amount: int = int(offline.get("essence", 0))
	if double:
		amount *= 2
	if amount > 0:
		add_essence(amount)
	SaveManager.data["last_logout_time"] = int(Time.get_unix_time_from_system())
	SaveManager.save_game()


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
