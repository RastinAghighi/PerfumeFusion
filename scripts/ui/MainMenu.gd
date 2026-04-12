extends Control

const EncyclopediaScene := preload("res://scenes/ui/Encyclopedia.tscn")
const SettingsScene := preload("res://scenes/ui/Settings.tscn")

@onready var free_play_button: Button = $Background/CenterContainer/VBox/FreePlayButton
@onready var battle_button: Button = $Background/CenterContainer/VBox/BattleButton
@onready var collection_button: Button = $Background/CenterContainer/VBox/CollectionButton
@onready var settings_button: Button = $Background/CenterContainer/VBox/SettingsButton
@onready var about_button: Button = $Background/CenterContainer/VBox/AboutButton
@onready var about_panel: Panel = $AboutPanel
@onready var about_close_button: Button = $AboutPanel/Margin/VBox/CloseButton


func _ready() -> void:
	free_play_button.pressed.connect(_on_free_play)
	battle_button.pressed.connect(_on_battle)
	collection_button.pressed.connect(_on_collection)
	settings_button.pressed.connect(_on_settings)
	about_button.pressed.connect(_on_about)
	about_close_button.pressed.connect(_on_about_close)
	for btn in [free_play_button, battle_button, collection_button, settings_button, about_button, about_close_button]:
		btn.pressed.connect(AudioManager.play_button)
	about_panel.visible = false


func _on_free_play() -> void:
	get_tree().change_scene_to_file("res://scenes/main/GameScene.tscn")


func _on_battle() -> void:
	print("Battle mode coming soon")


func _on_collection() -> void:
	var enc := EncyclopediaScene.instantiate()
	get_tree().root.add_child(enc)


func _on_settings() -> void:
	var settings := SettingsScene.instantiate()
	get_tree().root.add_child(settings)


func _on_about() -> void:
	about_panel.visible = true


func _on_about_close() -> void:
	about_panel.visible = false
