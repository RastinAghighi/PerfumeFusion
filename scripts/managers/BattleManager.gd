extends Node

signal damage_dealt(amount: float, is_super_effective: bool, is_resisted: bool)
signal opponent_defeated
signal battle_timeout
signal combo_updated(combo_count: int, time_remaining: float)

var is_battle_active: bool = false
var current_opponent: Dictionary = {}
var opponent_hp: float = 0.0
var opponent_max_hp: float = 0.0

var combo_count: int = 0
var combo_timer: float = 0.0
const COMBO_WINDOW: float = 3.0


func _process(delta: float) -> void:
	if is_battle_active and combo_count > 0:
		combo_timer -= delta
		if combo_timer <= 0.0:
			combo_count = 0
			emit_signal("combo_updated", 0, 0.0)


func start_battle(opponent: Dictionary) -> void:
	current_opponent = opponent
	opponent_max_hp = float(opponent.get("hp", 100))
	opponent_hp = opponent_max_hp
	combo_count = 0
	combo_timer = 0.0
	is_battle_active = true


func end_battle() -> void:
	is_battle_active = false
	combo_count = 0
	combo_timer = 0.0


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


func _get_combo_multiplier() -> float:
	match combo_count:
		1: return 1.0
		2: return 1.2
		3: return 1.5
		4: return 1.8
		_: return 2.0 if combo_count >= 5 else 1.0


func deal_damage(tier: int, perfume_data: Dictionary) -> void:
	if not is_battle_active:
		return

	combo_count += 1
	combo_timer = COMBO_WINDOW

	var result: Dictionary = calculate_damage(tier, perfume_data)
	var damage: float = result.damage
	var is_super: bool = result.is_super_effective
	var is_res: bool = result.is_resisted

	var multiplier: float = _get_combo_multiplier()
	damage *= multiplier

	opponent_hp -= damage
	opponent_hp = max(opponent_hp, 0.0)

	emit_signal("damage_dealt", damage, is_super, is_res)
	emit_signal("combo_updated", combo_count, combo_timer)

	if combo_count > 1:
		print("Combo x%d! Damage: %d (x%.1f multiplier)" % [combo_count, int(damage), multiplier])
	elif is_super and not is_res:
		print("Dealt %d damage! (super effective)" % int(damage))
	elif is_res and not is_super:
		print("Dealt %d damage (resisted)" % int(damage))
	else:
		print("Dealt %d damage" % int(damage))

	if opponent_hp <= 0.0:
		emit_signal("opponent_defeated")
