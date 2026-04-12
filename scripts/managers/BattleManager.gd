extends Node

signal damage_dealt(amount: float, is_super_effective: bool, is_resisted: bool)
signal opponent_defeated
signal battle_timeout

var is_battle_active: bool = false
var current_opponent: Dictionary = {}
var opponent_hp: float = 0.0
var opponent_max_hp: float = 0.0


func start_battle(opponent: Dictionary) -> void:
	current_opponent = opponent
	opponent_max_hp = float(opponent.get("hp", 100))
	opponent_hp = opponent_max_hp
	is_battle_active = true


func end_battle() -> void:
	is_battle_active = false


func calculate_damage(tier: int, perfume_data: Dictionary) -> Dictionary:
	var damage: float = 0.0
	if tier <= 5:
		damage = tier * 3.0
	elif tier <= 10:
		damage = 15.0 + (tier - 5) * 5.0
	elif tier <= 15:
		damage = 40.0 + (tier - 10) * 10.0
	else:
		damage = 90.0 + (tier - 15) * 25.0

	var is_super_effective: bool = false
	var is_resisted: bool = false

	var opponent_id: int = int(current_opponent.get("id", 0))
	if opponent_id != 20:
		var accords: Array = perfume_data.get("accords", [])
		var weaknesses: Array = current_opponent.get("weakness", [])
		var resistances: Array = current_opponent.get("resistance", [])

		for accord in accords:
			var accord_name: String = ""
			if accord is Dictionary:
				accord_name = str(accord.get("name", "")).to_lower()
			else:
				accord_name = str(accord).to_lower()
			if accord_name == "":
				continue
			for w in weaknesses:
				if str(w).to_lower() == accord_name:
					is_super_effective = true
					break
			for r in resistances:
				if str(r).to_lower() == accord_name:
					is_resisted = true
					break

		if is_super_effective and is_resisted:
			pass
		elif is_super_effective:
			damage *= 2.0
		elif is_resisted:
			damage *= 0.5

	return {
		"damage": damage,
		"is_super_effective": is_super_effective,
		"is_resisted": is_resisted
	}


func deal_damage(tier: int, perfume_data: Dictionary) -> void:
	if not is_battle_active:
		return

	var result: Dictionary = calculate_damage(tier, perfume_data)
	var damage: float = result.damage
	var is_super: bool = result.is_super_effective
	var is_res: bool = result.is_resisted

	opponent_hp -= damage
	opponent_hp = max(opponent_hp, 0.0)

	emit_signal("damage_dealt", damage, is_super, is_res)

	if is_super and not is_res:
		print("Dealt %d damage! (super effective)" % int(damage))
	elif is_res and not is_super:
		print("Dealt %d damage (resisted)" % int(damage))
	else:
		print("Dealt %d damage" % int(damage))

	if opponent_hp <= 0.0:
		emit_signal("opponent_defeated")
