extends CanvasLayer

@onready var music_slider: HSlider = $Panel/Margin/VBox/MusicRow/MusicSlider
@onready var sfx_slider: HSlider = $Panel/Margin/VBox/SfxRow/SfxSlider
@onready var mute_check: CheckButton = $Panel/Margin/VBox/MuteRow/MuteCheck
@onready var reset_button: Button = $Panel/Margin/VBox/ResetButton
@onready var close_button: Button = $Panel/Margin/VBox/CloseButton
@onready var confirm_dialog: ConfirmationDialog = $ConfirmDialog


func _ready() -> void:
	music_slider.value = AudioManager.music_volume * 100.0
	sfx_slider.value = AudioManager.sfx_volume * 100.0
	mute_check.button_pressed = AudioManager.muted

	music_slider.value_changed.connect(_on_music_changed)
	sfx_slider.value_changed.connect(_on_sfx_changed)
	mute_check.toggled.connect(_on_mute_toggled)
	reset_button.pressed.connect(_on_reset_pressed)
	close_button.pressed.connect(_on_close_pressed)
	confirm_dialog.confirmed.connect(_on_reset_confirmed)

	for btn in [reset_button, close_button]:
		btn.pressed.connect(AudioManager.play_button)


func _on_music_changed(value: float) -> void:
	AudioManager.set_music_volume(value / 100.0)


func _on_sfx_changed(value: float) -> void:
	AudioManager.set_sfx_volume(value / 100.0)


func _on_mute_toggled(pressed: bool) -> void:
	AudioManager.set_mute(pressed)


func _on_reset_pressed() -> void:
	confirm_dialog.popup_centered()


func _on_reset_confirmed() -> void:
	SaveManager.data = SaveManager.get_default_data()
	SaveManager.save_game()
	get_tree().reload_current_scene()


func _on_close_pressed() -> void:
	queue_free()
