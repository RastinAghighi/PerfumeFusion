extends Control

const HUDScene := preload("res://scenes/ui/HUD.tscn")
const PerfumeItemScene := preload("res://scenes/grid/PerfumeItem.tscn")
const BattleResultScene := preload("res://scenes/ui/BattleResult.tscn")
const OpponentIntroScene := preload("res://scenes/ui/OpponentIntro.tscn")
const ScreenShakeScript := preload("res://scripts/effects/ScreenShake.gd")

@onready var grid: Node = $MarginContainer/VBoxContainer/Grid
@onready var sell_zone: Node = $MarginContainer/VBoxContainer/SellZone
@onready var hp_bar: ProgressBar = $BattleHUD/VBox/HPBar
@onready var hp_label: Label = $BattleHUD/VBox/HPBar/HPLabel
@onready var timer_label: Label = $BattleHUD/VBox/TimerLabel
@onready var opponent_name_label: Label = $BattleHUD/VBox/OpponentRow/OpponentInfo/OpponentName
@onready var opponent_title_label: Label = $BattleHUD/VBox/OpponentRow/OpponentInfo/OpponentTitle
@onready var weakness_label: Label = $BattleHUD/VBox/WeaknessRow/WeakLabel
@onready var resistance_label: Label = $BattleHUD/VBox/WeaknessRow/ResistLabel
@onready var background: Panel = $Background

var current_opponent: Dictionary = {}
var opponent_hp: float = 0.0
var opponent_max_hp: float = 0.0
var time_remaining: float = 0.0
var battle_active: bool = false

var _timer_pulse_tween: Tween = null
var _timer_scale_tween: Tween = null
var _combo_pulse_tween: Tween = null
var _combo_fade_tween: Tween = null
var _combo_layer: CanvasLayer = null
var _combo_container: Control = null
var _combo_label: Label = null
var _combo_timer_bar: ProgressBar = null
var _current_combo: int = 0

var _screen_shake: Node = null
var _hp_flash_tween: Tween = null
var _hp_pulse_tween: Tween = null
var _hp_normal_style: StyleBoxFlat = null
var _hp_flash_style: StyleBoxFlat = null
var _hp_low_style: StyleBoxFlat = null
var _bg_normal_color: Color = Color(0.08, 0.06, 0.12, 1)
var _bg_urgency_tween: Tween = null
var _bg_urgency_active: bool = false
var _super_effective_layer: CanvasLayer = null

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

	_setup_combo_ui()
	_setup_screen_shake()
	_setup_hp_styles()

	BattleManager.damage_dealt.connect(_on_damage_dealt)
	BattleManager.opponent_defeated.connect(_on_opponent_defeated)
	BattleManager.combo_updated.connect(_on_combo_updated)
	MergeManager.merge_completed.connect(_on_merge_completed)

	_show_opponent_intro()


func _process(delta: float) -> void:
	if not battle_active:
		return

	time_remaining -= delta
	_update_timer_display()

	opponent_hp = BattleManager.opponent_hp
	_update_hp_display()

	if _current_combo > 0 and _combo_timer_bar != null:
		_combo_timer_bar.value = BattleManager.combo_timer

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

	var hp_ratio: float = opponent_hp / opponent_max_hp if opponent_max_hp > 0.0 else 1.0
	if hp_ratio <= 0.25:
		_start_hp_pulse()
	else:
		_stop_hp_pulse()


func _update_timer_display() -> void:
	var t: float = max(time_remaining, 0.0)
	var minutes: int = int(t) / 60
	var seconds: int = int(t) % 60
	timer_label.text = "%d:%02d" % [minutes, seconds]

	if t > 30.0:
		timer_label.add_theme_color_override("font_color", Color(1, 1, 1, 1))
		_stop_timer_pulse()
		_stop_timer_scale_pulse()
		_stop_bg_urgency()
	elif t > 10.0:
		timer_label.add_theme_color_override("font_color", Color(1, 0.9, 0.3, 1))
		_stop_timer_pulse()
		_stop_timer_scale_pulse()
		_start_bg_urgency()
	else:
		timer_label.add_theme_color_override("font_color", Color(1, 0.3, 0.3, 1))
		_start_timer_pulse()
		_start_timer_scale_pulse()
		_start_bg_urgency()


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


func _start_timer_scale_pulse() -> void:
	if _timer_scale_tween != null and _timer_scale_tween.is_valid():
		return
	timer_label.pivot_offset = timer_label.size * 0.5
	_timer_scale_tween = create_tween().set_loops()
	_timer_scale_tween.tween_property(timer_label, "scale", Vector2(1.15, 1.15), 0.25)
	_timer_scale_tween.tween_property(timer_label, "scale", Vector2(1.0, 1.0), 0.25)


func _stop_timer_scale_pulse() -> void:
	if _timer_scale_tween != null and _timer_scale_tween.is_valid():
		_timer_scale_tween.kill()
		_timer_scale_tween = null
	timer_label.scale = Vector2(1.0, 1.0)


func _setup_screen_shake() -> void:
	_screen_shake = Node.new()
	_screen_shake.set_script(ScreenShakeScript)
	add_child(_screen_shake)
	_screen_shake.setup(self)


func _setup_hp_styles() -> void:
	_hp_normal_style = StyleBoxFlat.new()
	_hp_normal_style.bg_color = Color(0.85, 0.25, 0.2, 1)
	_hp_normal_style.corner_radius_top_left = 6
	_hp_normal_style.corner_radius_top_right = 6
	_hp_normal_style.corner_radius_bottom_right = 6
	_hp_normal_style.corner_radius_bottom_left = 6

	_hp_flash_style = StyleBoxFlat.new()
	_hp_flash_style.bg_color = Color(1.0, 1.0, 1.0, 1)
	_hp_flash_style.corner_radius_top_left = 6
	_hp_flash_style.corner_radius_top_right = 6
	_hp_flash_style.corner_radius_bottom_right = 6
	_hp_flash_style.corner_radius_bottom_left = 6

	_hp_low_style = StyleBoxFlat.new()
	_hp_low_style.bg_color = Color(0.5, 0.1, 0.1, 1)
	_hp_low_style.corner_radius_top_left = 6
	_hp_low_style.corner_radius_top_right = 6
	_hp_low_style.corner_radius_bottom_right = 6
	_hp_low_style.corner_radius_bottom_left = 6


func _flash_hp_bar() -> void:
	if _hp_flash_tween != null and _hp_flash_tween.is_valid():
		_hp_flash_tween.kill()
	hp_bar.add_theme_stylebox_override("fill", _hp_flash_style)
	_hp_flash_tween = create_tween()
	_hp_flash_tween.tween_interval(0.1)
	_hp_flash_tween.tween_callback(_restore_hp_style)


func _restore_hp_style() -> void:
	var hp_ratio: float = opponent_hp / opponent_max_hp if opponent_max_hp > 0.0 else 1.0
	if hp_ratio <= 0.25:
		hp_bar.add_theme_stylebox_override("fill", _hp_low_style)
	else:
		hp_bar.add_theme_stylebox_override("fill", _hp_normal_style)


func _start_hp_pulse() -> void:
	if _hp_pulse_tween != null and _hp_pulse_tween.is_valid():
		return
	hp_bar.add_theme_stylebox_override("fill", _hp_low_style)
	_hp_pulse_tween = create_tween().set_loops()
	_hp_pulse_tween.tween_method(_set_hp_bar_color, Color(0.5, 0.1, 0.1, 1), Color(0.7, 0.15, 0.12, 1), 0.4)
	_hp_pulse_tween.tween_method(_set_hp_bar_color, Color(0.7, 0.15, 0.12, 1), Color(0.5, 0.1, 0.1, 1), 0.4)


func _stop_hp_pulse() -> void:
	if _hp_pulse_tween != null and _hp_pulse_tween.is_valid():
		_hp_pulse_tween.kill()
		_hp_pulse_tween = null
	if _hp_normal_style != null:
		hp_bar.add_theme_stylebox_override("fill", _hp_normal_style)


func _set_hp_bar_color(color: Color) -> void:
	_hp_low_style.bg_color = color


func _start_bg_urgency() -> void:
	if _bg_urgency_active:
		return
	_bg_urgency_active = true
	var bg_style: StyleBoxFlat = background.get_theme_stylebox("panel").duplicate() if background.has_theme_stylebox_override("panel") else StyleBoxFlat.new()
	bg_style.bg_color = Color(0.15, 0.04, 0.04, 1)
	background.add_theme_stylebox_override("panel", bg_style)


func _stop_bg_urgency() -> void:
	if not _bg_urgency_active:
		return
	_bg_urgency_active = false
	var bg_style := StyleBoxFlat.new()
	bg_style.bg_color = _bg_normal_color
	background.add_theme_stylebox_override("panel", bg_style)


func _flash_super_effective() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 55
	add_child(layer)

	var overlay := ColorRect.new()
	overlay.color = Color(0.2, 0.9, 0.3, 0.25)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(overlay)

	var tween := overlay.create_tween()
	tween.tween_interval(0.15)
	tween.tween_property(overlay, "color:a", 0.0, 0.2)
	tween.tween_callback(layer.queue_free)


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

	# Screen shake
	if is_super_effective and not is_resisted:
		_screen_shake.shake(8.0, 0.25)
	elif BattleManager.combo_count >= 5:
		_screen_shake.shake(12.0, 0.3)
	else:
		_screen_shake.shake(3.0, 0.15)

	# HP bar flash
	_flash_hp_bar()

	# Super effective screen flash
	if is_super_effective and not is_resisted:
		_flash_super_effective()


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


func _show_opponent_intro() -> void:
	var intro := OpponentIntroScene.instantiate()
	add_child(intro)
	intro.setup(current_opponent)
	intro.intro_finished.connect(_on_intro_finished)


func _on_intro_finished() -> void:
	BattleManager.start_battle(current_opponent)
	battle_active = true


func _setup_combo_ui() -> void:
	_combo_layer = CanvasLayer.new()
	_combo_layer.layer = 50
	add_child(_combo_layer)

	_combo_container = Control.new()
	_combo_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	_combo_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_combo_layer.add_child(_combo_container)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.anchor_top = 0.35
	center.anchor_bottom = 0.5
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_combo_container.add_child(center)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.add_child(vbox)

	_combo_label = Label.new()
	_combo_label.text = ""
	_combo_label.add_theme_font_size_override("font_size", 48)
	_combo_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2, 1.0))
	_combo_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	_combo_label.add_theme_constant_override("outline_size", 6)
	_combo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_combo_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_combo_label.pivot_offset = Vector2(0, 0)
	vbox.add_child(_combo_label)

	_combo_timer_bar = ProgressBar.new()
	_combo_timer_bar.custom_minimum_size = Vector2(120, 6)
	_combo_timer_bar.max_value = BattleManager.COMBO_WINDOW
	_combo_timer_bar.value = 0.0
	_combo_timer_bar.show_percentage = false
	_combo_timer_bar.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_combo_timer_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var bar_style := StyleBoxFlat.new()
	bar_style.bg_color = Color(1.0, 0.85, 0.2, 0.9)
	bar_style.corner_radius_top_left = 3
	bar_style.corner_radius_top_right = 3
	bar_style.corner_radius_bottom_right = 3
	bar_style.corner_radius_bottom_left = 3
	_combo_timer_bar.add_theme_stylebox_override("fill", bar_style)
	vbox.add_child(_combo_timer_bar)

	_combo_container.modulate.a = 0.0


func _on_combo_updated(count: int, _time_left: float) -> void:
	_current_combo = count

	if count == 0:
		if _combo_fade_tween != null and _combo_fade_tween.is_valid():
			_combo_fade_tween.kill()
		_combo_fade_tween = create_tween()
		_combo_fade_tween.tween_property(_combo_container, "modulate:a", 0.0, 0.3)
		return

	if count < 2:
		_combo_container.modulate.a = 0.0
		return

	_combo_label.text = "x%d COMBO!" % count
	_combo_timer_bar.value = BattleManager.COMBO_WINDOW
	_combo_container.modulate.a = 1.0

	if _combo_fade_tween != null and _combo_fade_tween.is_valid():
		_combo_fade_tween.kill()

	if _combo_pulse_tween != null and _combo_pulse_tween.is_valid():
		_combo_pulse_tween.kill()
	_combo_label.scale = Vector2(1.0, 1.0)
	_combo_pulse_tween = create_tween()
	_combo_pulse_tween.tween_property(_combo_label, "scale", Vector2(1.3, 1.3), 0.1)
	_combo_pulse_tween.tween_property(_combo_label, "scale", Vector2(1.0, 1.0), 0.15)


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
	_stop_timer_scale_pulse()
	_stop_hp_pulse()
	_stop_bg_urgency()
	var result := BattleResultScene.instantiate()
	add_child(result)
	result.show_victory(current_opponent, _build_stats())


func _battle_lost() -> void:
	battle_active = false
	BattleManager.end_battle()
	_stop_timer_pulse()
	_stop_timer_scale_pulse()
	_stop_hp_pulse()
	_stop_bg_urgency()
	var result := BattleResultScene.instantiate()
	add_child(result)
	result.show_defeat(current_opponent, _build_stats())


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_EXIT_TREE:
		SaveManager.set_logout_time()
