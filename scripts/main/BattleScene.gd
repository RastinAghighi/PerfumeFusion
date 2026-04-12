extends Control

const HUDScene := preload("res://scenes/ui/HUD.tscn")
const PerfumeItemScene := preload("res://scenes/grid/PerfumeItem.tscn")
const BattleResultScene := preload("res://scenes/ui/BattleResult.tscn")

@onready var grid: Node = $MarginContainer/VBoxContainer/Grid
@onready var sell_zone: Node = $MarginContainer/VBoxContainer/SellZone
@onready var hp_bar: ProgressBar = $BattleHUD/VBox/HPBar
@onready var hp_label: Label = $BattleHUD/VBox/HPBar/HPLabel
@onready var timer_label: Label = $BattleHUD/VBox/TimerLabel
@onready var opponent_name_label: Label = $BattleHUD/VBox/OpponentRow/OpponentInfo/OpponentName
@onready var opponent_title_label: Label = $BattleHUD/VBox/OpponentRow/OpponentInfo/OpponentTitle
@onready var weakness_label: Label = $BattleHUD/VBox/WeaknessRow/WeakLabel
@onready var resistance_label: Label = $BattleHUD/VBox/WeaknessRow/ResistLabel

var current_opponent: Dictionary = {}
var opponent_hp: float = 0.0
var opponent_max_hp: float = 0.0
var time_remaining: float = 0.0
var battle_active: bool = false

var _timer_pulse_tween: Tween = null

var _stat_total_merges: int = 0
var _stat_highest_tier: int = 0
var _stat_damage_dealt: float = 0.0


func _ready() -> void:
	current_opponent = OpponentManager.get_opponent(OpponentManager.selected_opponent_id)
	if current_opponent.is_empty():
		push_error("BattleScene: no opponent selected")
		return

	grid.sell_zone = sell_zone
	SpawnManager.set_grid(grid)
	EconomyManager.essence = int(SaveManager.data.get("essence", 0))

	opponent_max_hp = float(current_opponent.get("hp", 100))
	opponent_hp = opponent_max_hp
	time_remaining = float(current_opponent.get("time_limit", 120))

	_setup_battle_hud()
	_spawn_starting_perfumes()

	var hud := HUDScene.instantiate()
	add_child(hud)

	AudioManager.register_bgm_player($BGM)

	BattleManager.start_battle(current_opponent)
	BattleManager.damage_dealt.connect(_on_damage_dealt)
	BattleManager.opponent_defeated.connect(_on_opponent_defeated)
	MergeManager.merge_completed.connect(_on_merge_completed)

	battle_active = true


func _process(delta: float) -> void:
	if not battle_active:
		return

	time_remaining -= delta
	_update_timer_display()

	opponent_hp = BattleManager.opponent_hp
	_update_hp_display()

	if time_remaining <= 0.0:
		time_remaining = 0.0
		_battle_lost()


func _setup_battle_hud() -> void:
	opponent_name_label.text = str(current_opponent.get("name", "???"))
	opponent_title_label.text = str(current_opponent.get("title", ""))

	var weaknesses: Array = current_opponent.get("weakness", [])
	var resistances: Array = current_opponent.get("resistance", [])
	weakness_label.text = "Weak: %s" % ", ".join(weaknesses) if weaknesses.size() > 0 else ""
	resistance_label.text = "Resists: %s" % ", ".join(resistances) if resistances.size() > 0 else ""

	hp_bar.max_value = opponent_max_hp
	hp_bar.value = opponent_hp
	_update_hp_display()
	_update_timer_display()


func _update_hp_display() -> void:
	hp_bar.value = opponent_hp
	hp_label.text = "%d / %d HP" % [int(max(opponent_hp, 0)), int(opponent_max_hp)]


func _update_timer_display() -> void:
	var t: float = max(time_remaining, 0.0)
	var minutes: int = int(t) / 60
	var seconds: int = int(t) % 60
	timer_label.text = "%d:%02d" % [minutes, seconds]

	if t > 30.0:
		timer_label.add_theme_color_override("font_color", Color(1, 1, 1, 1))
		_stop_timer_pulse()
	elif t > 10.0:
		timer_label.add_theme_color_override("font_color", Color(1, 0.9, 0.3, 1))
		_stop_timer_pulse()
	else:
		timer_label.add_theme_color_override("font_color", Color(1, 0.3, 0.3, 1))
		_start_timer_pulse()


func _start_timer_pulse() -> void:
	if _timer_pulse_tween != null and _timer_pulse_tween.is_valid():
		return
	_timer_pulse_tween = create_tween().set_loops()
	_timer_pulse_tween.tween_property(timer_label, "modulate:a", 0.4, 0.3)
	_timer_pulse_tween.tween_property(timer_label, "modulate:a", 1.0, 0.3)


func _stop_timer_pulse() -> void:
	if _timer_pulse_tween != null and _timer_pulse_tween.is_valid():
		_timer_pulse_tween.kill()
		_timer_pulse_tween = null
	timer_label.modulate.a = 1.0


func _spawn_starting_perfumes() -> void:
	for i in range(3):
		var empty_slots: Array = grid.get_empty_slots()
		if empty_slots.is_empty():
			break
		var slot = empty_slots[randi() % empty_slots.size()]
		var perfume_data: Dictionary = DataManager.get_random_perfume(1)
		if perfume_data.is_empty():
			continue
		var item := PerfumeItemScene.instantiate()
		slot.place_item(item)
		item.setup(1, perfume_data)


func _on_merge_completed(_new_item, tier: int) -> void:
	if not battle_active:
		return
	_stat_total_merges += 1
	if tier > _stat_highest_tier:
		_stat_highest_tier = tier


func _on_damage_dealt(amount: float, is_super_effective: bool, is_resisted: bool) -> void:
	if not battle_active:
		return
	_stat_damage_dealt += amount
	opponent_hp = BattleManager.opponent_hp
	_update_hp_display()
	_show_damage_number(amount, is_super_effective, is_resisted)


func _on_opponent_defeated() -> void:
	_battle_won()


func _show_damage_number(amount: float, is_super_effective: bool, is_resisted: bool) -> void:
	var layer := CanvasLayer.new()
	layer.layer = 60
	add_child(layer)

	var container := Control.new()
	container.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(container)

	var damage_label := Label.new()
	damage_label.text = str(int(amount))
	damage_label.add_theme_font_size_override("font_size", 48)
	damage_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	damage_label.add_theme_constant_override("outline_size", 6)
	damage_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	if is_super_effective and not is_resisted:
		damage_label.add_theme_color_override("font_color", Color(0.3, 1.0, 0.3, 1.0))
	elif is_resisted and not is_super_effective:
		damage_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6, 1.0))
	else:
		damage_label.add_theme_color_override("font_color", Color(1, 1, 1, 1))

	damage_label.anchor_left = 0.5
	damage_label.anchor_right = 0.5
	damage_label.anchor_top = 0.08
	damage_label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	container.add_child(damage_label)

	var tween := damage_label.create_tween()
	tween.set_parallel(true)
	tween.tween_property(damage_label, "position:y", damage_label.position.y - 60.0, 0.8)
	tween.tween_property(damage_label, "modulate:a", 0.0, 0.8).set_delay(0.2)

	if is_super_effective and not is_resisted:
		var effect_label := Label.new()
		effect_label.text = "SUPER EFFECTIVE!"
		effect_label.add_theme_font_size_override("font_size", 32)
		effect_label.add_theme_color_override("font_color", Color(0.3, 1.0, 0.3, 1.0))
		effect_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
		effect_label.add_theme_constant_override("outline_size", 4)
		effect_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		effect_label.anchor_left = 0.5
		effect_label.anchor_right = 0.5
		effect_label.anchor_top = 0.14
		effect_label.grow_horizontal = Control.GROW_DIRECTION_BOTH
		container.add_child(effect_label)

		var etween := effect_label.create_tween()
		etween.tween_interval(0.4)
		etween.tween_property(effect_label, "modulate:a", 0.0, 0.4)
	elif is_resisted and not is_super_effective:
		var effect_label := Label.new()
		effect_label.text = "RESISTED..."
		effect_label.add_theme_font_size_override("font_size", 32)
		effect_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6, 1.0))
		effect_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
		effect_label.add_theme_constant_override("outline_size", 4)
		effect_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		effect_label.anchor_left = 0.5
		effect_label.anchor_right = 0.5
		effect_label.anchor_top = 0.14
		effect_label.grow_horizontal = Control.GROW_DIRECTION_BOTH
		container.add_child(effect_label)

		var etween := effect_label.create_tween()
		etween.tween_interval(0.4)
		etween.tween_property(effect_label, "modulate:a", 0.0, 0.4)

	tween.chain().tween_callback(layer.queue_free)


func _build_stats() -> Dictionary:
	return {
		"time_taken": float(current_opponent.get("time_limit", 120)) - time_remaining,
		"total_merges": _stat_total_merges,
		"highest_tier": _stat_highest_tier,
		"damage_dealt": _stat_damage_dealt,
		"max_hp": opponent_max_hp,
	}


func _battle_won() -> void:
	battle_active = false
	BattleManager.end_battle()
	_stop_timer_pulse()
	var result := BattleResultScene.instantiate()
	add_child(result)
	result.show_victory(current_opponent, _build_stats())


func _battle_lost() -> void:
	battle_active = false
	BattleManager.end_battle()
	_stop_timer_pulse()
	var result := BattleResultScene.instantiate()
	add_child(result)
	result.show_defeat(current_opponent, _build_stats())


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_EXIT_TREE:
		SaveManager.set_logout_time()
