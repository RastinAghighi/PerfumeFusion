extends Control

const HUDScene := preload("res://scenes/ui/HUD.tscn")
const PerfumeItemScene := preload("res://scenes/grid/PerfumeItem.tscn")

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
	battle_active = true


func _process(delta: float) -> void:
	if not battle_active:
		return

	time_remaining -= delta
	_update_timer_display()
	_update_hp_display()

	if time_remaining <= 0.0:
		time_remaining = 0.0
		_battle_lost()
	elif opponent_hp <= 0.0:
		opponent_hp = 0.0
		_battle_won()


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


func deal_damage(amount: float) -> void:
	if not battle_active:
		return
	opponent_hp -= amount
	_update_hp_display()


func _battle_won() -> void:
	battle_active = false
	_stop_timer_pulse()


func _battle_lost() -> void:
	battle_active = false
	_stop_timer_pulse()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_EXIT_TREE:
		SaveManager.set_logout_time()
