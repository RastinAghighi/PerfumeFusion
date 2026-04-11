extends CanvasLayer

const BUY_COST: int = 10
const EncyclopediaScene := preload("res://scenes/ui/Encyclopedia.tscn")

@onready var essence_label: Label = $TopBar/Margin/HBox/EssenceBox/EssenceLabel
@onready var essence_icon: Panel = $TopBar/Margin/HBox/EssenceBox/EssenceIcon
@onready var settings_button: Button = $TopBar/Margin/HBox/SettingsButton
@onready var collection_button: Button = $BottomBar/Margin/HBox/CollectionButton
@onready var shop_button: Button = $BottomBar/Margin/HBox/ShopButton
@onready var buy_button: Button = $BottomBar/Margin/HBox/BuyButton
@onready var grid_full_label: Label = $GridFullLabel


func _ready() -> void:
	EconomyManager.essence_changed.connect(_on_essence_changed)
	collection_button.pressed.connect(_on_collection_pressed)
	shop_button.pressed.connect(_on_shop_pressed)
	buy_button.pressed.connect(_on_buy_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	grid_full_label.modulate.a = 0.0
	_update_essence_label(EconomyManager.get_essence(), false)


func _on_essence_changed(new_amount: int) -> void:
	_update_essence_label(new_amount, true)


func _update_essence_label(amount: int, animate: bool) -> void:
	essence_label.text = str(amount)
	if not animate:
		return
	essence_label.pivot_offset = essence_label.size * 0.5
	essence_label.scale = Vector2.ONE
	var tween := essence_label.create_tween()
	tween.tween_property(essence_label, "scale", Vector2(1.3, 1.3), 0.1)
	tween.tween_property(essence_label, "scale", Vector2.ONE, 0.15)


func _on_buy_pressed() -> void:
	if SpawnManager.grid_reference == null:
		return
	if SpawnManager.grid_reference.is_full():
		_show_grid_full()
		return
	if not EconomyManager.spend_essence(BUY_COST):
		return
	SpawnManager._try_spawn()
	SaveManager.save_game()


func _show_grid_full() -> void:
	grid_full_label.text = "Grid is full!"
	grid_full_label.modulate.a = 1.0
	var tween := grid_full_label.create_tween()
	tween.tween_interval(1.0)
	tween.tween_property(grid_full_label, "modulate:a", 0.0, 0.4)


func _on_collection_pressed() -> void:
	var enc := EncyclopediaScene.instantiate()
	get_tree().root.add_child(enc)


func _on_shop_pressed() -> void:
	print("open shop")


func _on_settings_pressed() -> void:
	print("open settings")
