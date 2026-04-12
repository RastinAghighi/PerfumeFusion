extends CanvasLayer

const FRENZY_COOLDOWN: float = 300.0
const FRENZY_DURATION: float = 30.0

const ShopScene := preload("res://scenes/ui/Shop.tscn")
const InfoCardScene := preload("res://scenes/ui/InfoCard.tscn")

@onready var essence_label: Label = $TopBar/Margin/HBox/EssenceBox/EssenceLabel
@onready var essence_icon: Panel = $TopBar/Margin/HBox/EssenceBox/EssenceIcon
@onready var menu_button: Button = $TopBar/Margin/HBox/MenuButton
@onready var shop_button: Button = $BottomBar/Margin/HBox/ShopButton
@onready var buy_button: Button = $BottomBar/Margin/HBox/BuyButton
@onready var grid_full_label: Label = $GridFullLabel
@onready var rare_drop_button: Button = $RareDropAnchor/RareDropButton
@onready var frenzy_button: Button = $FrenzyAnchor/FrenzyButton
@onready var frenzy_border: Panel = $FrenzyBorder
@onready var frenzy_countdown: Label = $FrenzyCountdown

var _rare_pulse_tween: Tween = null
var _frenzy_cooldown_left: float = 0.0
var _frenzy_time_left: float = 0.0
var _frenzy_active: bool = false
var _frenzy_awaiting_ad: bool = false
var _border_tween: Tween = null
var _cooldown_label: Label = null


func _ready() -> void:
	add_to_group("hud")
	EconomyManager.essence_changed.connect(_on_essence_changed)
	menu_button.pressed.connect(_on_menu_pressed)
	shop_button.pressed.connect(_on_shop_pressed)
	buy_button.pressed.connect(_on_buy_pressed)
	rare_drop_button.pressed.connect(_on_rare_drop_pressed)
	frenzy_button.pressed.connect(_on_frenzy_pressed)
	for btn in [menu_button, shop_button, buy_button, rare_drop_button, frenzy_button]:
		btn.pressed.connect(AudioManager.play_button)
	RareDropManager.rare_drop_available.connect(_on_rare_drop_available)
	RareDropManager.rare_drop_expired.connect(_on_rare_drop_expired)
	SpawnManager.spawn_cooldown_increased.connect(_on_spawn_cooldown_increased)
	grid_full_label.modulate.a = 0.0
	rare_drop_button.visible = false
	frenzy_border.visible = false
	frenzy_countdown.visible = false
	_create_cooldown_label()
	_update_essence_label(EconomyManager.get_essence(), false)
	_update_buy_button_text()
	_update_frenzy_button_text()


func _process(delta: float) -> void:
	if _frenzy_cooldown_left > 0.0 and not _frenzy_active:
		_frenzy_cooldown_left = max(0.0, _frenzy_cooldown_left - delta)
		_update_frenzy_button_text()

	if _frenzy_active:
		_frenzy_time_left -= delta
		if _frenzy_time_left <= 0.0:
			_end_frenzy()
		else:
			frenzy_countdown.text = "FRENZY: %ds" % int(ceil(_frenzy_time_left))

	_update_spawn_cooldown_display()


func _on_essence_changed(new_amount: int) -> void:
	_update_essence_label(new_amount, true)
	_update_buy_button_text()


func _update_essence_label(amount: int, animate: bool) -> void:
	essence_label.text = str(amount)
	if not animate:
		return
	essence_label.pivot_offset = essence_label.size * 0.5
	essence_label.scale = Vector2.ONE
	var tween := essence_label.create_tween()
	tween.tween_property(essence_label, "scale", Vector2(1.3, 1.3), 0.1)
	tween.tween_property(essence_label, "scale", Vector2.ONE, 0.15)


func _update_buy_button_text() -> void:
	var cost: int = SpawnManager.get_manual_spawn_cost()
	if cost <= 0:
		buy_button.text = "Spawn (Free)"
	else:
		buy_button.text = "Spawn ✦%d" % cost


func _on_buy_pressed() -> void:
	if SpawnManager.is_manual_on_cooldown():
		return
	if SpawnManager.grid_reference == null:
		return
	if SpawnManager.grid_reference.is_full():
		show_grid_full_message("Grid is full!")
		return
	var cost: int = SpawnManager.get_manual_spawn_cost()
	if cost > 0 and not EconomyManager.spend_essence(cost):
		return
	var perfume_data: Dictionary = SpawnManager._try_spawn()
	if not perfume_data.is_empty():
		var url: String = String(perfume_data.get("url", perfume_data.get("name", "")))
		var unlocked: Array = SaveManager.data.get("unlocked_perfumes", [])
		if url != "" and not unlocked.has(url):
			unlocked.append(url)
			SaveManager.data["unlocked_perfumes"] = unlocked
			var card := InfoCardScene.instantiate()
			get_tree().root.add_child(card)
			card.show_perfume(perfume_data, 1)
	var total: int = int(SaveManager.data.get("total_spawns", 0)) + 1
	SaveManager.data["total_spawns"] = total
	SaveManager.save_game()
	SpawnManager.start_manual_cooldown()
	_update_buy_button_text()


func show_grid_full_message(text: String = "Grid is full!") -> void:
	grid_full_label.text = text
	grid_full_label.modulate.a = 1.0
	var tween := grid_full_label.create_tween()
	tween.tween_interval(1.0)
	tween.tween_property(grid_full_label, "modulate:a", 0.0, 0.4)


func _on_menu_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/MainMenu.tscn")


func _on_shop_pressed() -> void:
	var shop := ShopScene.instantiate()
	get_tree().root.add_child(shop)


func _on_rare_drop_available() -> void:
	rare_drop_button.visible = true
	rare_drop_button.pivot_offset = rare_drop_button.size * 0.5
	rare_drop_button.scale = Vector2.ONE
	rare_drop_button.modulate = Color(1, 1, 1, 1)
	if _rare_pulse_tween != null and _rare_pulse_tween.is_valid():
		_rare_pulse_tween.kill()
	_rare_pulse_tween = create_tween().set_loops()
	_rare_pulse_tween.tween_property(rare_drop_button, "scale", Vector2(1.12, 1.12), 0.45)
	_rare_pulse_tween.tween_property(rare_drop_button, "scale", Vector2(1.0, 1.0), 0.45)


func _on_rare_drop_expired() -> void:
	rare_drop_button.visible = false
	if _rare_pulse_tween != null and _rare_pulse_tween.is_valid():
		_rare_pulse_tween.kill()
		_rare_pulse_tween = null
	rare_drop_button.scale = Vector2.ONE


func _on_rare_drop_pressed() -> void:
	_on_rare_drop_expired()
	RareDropManager.claim()


func _on_frenzy_pressed() -> void:
	if _frenzy_active or _frenzy_awaiting_ad or _frenzy_cooldown_left > 0.0:
		return
	_frenzy_awaiting_ad = true
	frenzy_button.disabled = true
	AdManager.show_rewarded_ad(func(success: bool) -> void:
		_frenzy_awaiting_ad = false
		if success:
			_start_frenzy()
		else:
			frenzy_button.disabled = false
			_update_frenzy_button_text()
	)


func _start_frenzy() -> void:
	_frenzy_active = true
	_frenzy_time_left = FRENZY_DURATION
	_frenzy_cooldown_left = FRENZY_COOLDOWN
	SpawnManager.start_frenzy(FRENZY_DURATION)
	frenzy_countdown.visible = true
	frenzy_countdown.text = "FRENZY: %ds" % int(FRENZY_DURATION)
	frenzy_border.visible = true
	frenzy_border.modulate = Color(1, 1, 1, 1)
	if _border_tween != null and _border_tween.is_valid():
		_border_tween.kill()
	_border_tween = create_tween().set_loops()
	_border_tween.tween_property(frenzy_border, "modulate:a", 0.35, 0.5)
	_border_tween.tween_property(frenzy_border, "modulate:a", 1.0, 0.5)
	frenzy_button.disabled = true
	_update_frenzy_button_text()


func _end_frenzy() -> void:
	_frenzy_active = false
	_frenzy_time_left = 0.0
	frenzy_countdown.visible = false
	frenzy_border.visible = false
	if _border_tween != null and _border_tween.is_valid():
		_border_tween.kill()
		_border_tween = null
	_update_frenzy_button_text()


func _update_frenzy_button_text() -> void:
	if _frenzy_active:
		frenzy_button.text = "⚡ Active"
		frenzy_button.disabled = true
		return
	if _frenzy_cooldown_left > 0.0:
		frenzy_button.text = "⚡ %s" % _format_cooldown(_frenzy_cooldown_left)
		frenzy_button.disabled = true
		return
	frenzy_button.text = "⚡ Frenzy"
	if not _frenzy_awaiting_ad:
		frenzy_button.disabled = false


func _create_cooldown_label() -> void:
	_cooldown_label = Label.new()
	_cooldown_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_cooldown_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_cooldown_label.add_theme_font_size_override("font_size", 14)
	_cooldown_label.add_theme_color_override("font_color", Color(0.75, 0.7, 0.88, 1))
	_cooldown_label.anchor_left = 0.5
	_cooldown_label.anchor_right = 0.5
	_cooldown_label.anchor_top = 1.0
	_cooldown_label.anchor_bottom = 1.0
	_cooldown_label.offset_left = -60.0
	_cooldown_label.offset_right = 60.0
	_cooldown_label.offset_top = -120.0
	_cooldown_label.offset_bottom = -104.0
	_cooldown_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_cooldown_label)
	_cooldown_label.text = "Cooldown: %.1fs" % SpawnManager.get_manual_cooldown()


func _update_spawn_cooldown_display() -> void:
	if SpawnManager.is_manual_on_cooldown():
		buy_button.disabled = true
		buy_button.text = "Spawn %.1fs" % SpawnManager.manual_cooldown_left
		if _cooldown_label != null:
			_cooldown_label.text = "Cooldown: %.1fs" % SpawnManager.get_manual_cooldown()
	else:
		buy_button.disabled = false
		_update_buy_button_text()
		if _cooldown_label != null:
			_cooldown_label.text = "Cooldown: %.1fs" % SpawnManager.get_manual_cooldown()


func _on_spawn_cooldown_increased() -> void:
	show_grid_full_message("Spawning slowed! Upgrade in Shop.")


func _format_cooldown(seconds: float) -> String:
	var total: int = int(ceil(seconds))
	var m: int = total / 60
	var s: int = total % 60
	return "%d:%02d" % [m, s]
