extends CanvasLayer

var _opponent: Dictionary = {}

@onready var result_label: Label = $Background/PanelContainer/VBox/ResultLabel
@onready var opponent_label: Label = $Background/PanelContainer/VBox/OpponentLabel
@onready var time_stat: Label = $Background/PanelContainer/VBox/StatsBox/TimeStat
@onready var merges_stat: Label = $Background/PanelContainer/VBox/StatsBox/MergesStat
@onready var tier_stat: Label = $Background/PanelContainer/VBox/StatsBox/TierStat
@onready var damage_stat: Label = $Background/PanelContainer/VBox/StatsBox/DamageStat
@onready var rewards_box: VBoxContainer = $Background/PanelContainer/VBox/RewardsBox
@onready var rewards_label: Label = $Background/PanelContainer/VBox/RewardsBox/RewardsTitle
@onready var essence_label: Label = $Background/PanelContainer/VBox/RewardsBox/EssenceReward
@onready var unlock_label: Label = $Background/PanelContainer/VBox/RewardsBox/UnlockReward
@onready var left_button: Button = $Background/PanelContainer/VBox/ButtonRow/LeftButton
@onready var right_button: Button = $Background/PanelContainer/VBox/ButtonRow/RightButton


func show_victory(opponent: Dictionary, stats: Dictionary) -> void:
	_opponent = opponent

	result_label.text = "VICTORY!"
	result_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3, 1.0))

	var opp_name: String = str(opponent.get("name", "???"))
	opponent_label.text = "You defeated %s!" % opp_name

	_populate_stats(stats, true)

	var reward: int = int(opponent.get("reward_essence", 100))
	EconomyManager.add_essence(reward)

	rewards_box.visible = true
	essence_label.text = "+%d Essence" % reward

	var opp_id: int = int(opponent.get("id", -1))
	var was_beaten: bool = SaveManager.is_opponent_beaten(opp_id)
	SaveManager.mark_opponent_beaten(opp_id)
	SaveManager.update_battle_stats(opp_id, true, stats.get("time_taken", 0.0), int(stats.get("max_combo", 0)))

	if not was_beaten:
		unlock_label.text = "NEW! Next opponent unlocked!"
		unlock_label.visible = true
	else:
		unlock_label.visible = false

	left_button.text = "Continue"
	right_button.text = "Replay"
	left_button.pressed.connect(_go_battle_select)
	right_button.pressed.connect(_replay)


func show_defeat(opponent: Dictionary, stats: Dictionary) -> void:
	_opponent = opponent

	result_label.text = "DEFEAT"
	result_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3, 1.0))

	var opp_name: String = str(opponent.get("name", "???"))
	opponent_label.text = "%s wins..." % opp_name

	_populate_stats(stats, false)

	var opp_id: int = int(opponent.get("id", -1))
	SaveManager.update_battle_stats(opp_id, false, 0.0, int(stats.get("max_combo", 0)))

	rewards_box.visible = false

	left_button.text = "Try Again"
	right_button.text = "Back"
	left_button.pressed.connect(_replay)
	right_button.pressed.connect(_go_battle_select)


func _populate_stats(stats: Dictionary, is_victory: bool) -> void:
	if is_victory:
		var t: float = stats.get("time_taken", 0.0)
		var minutes: int = int(t) / 60
		var seconds: int = int(t) % 60
		time_stat.text = "Time: %d:%02d" % [minutes, seconds]
	else:
		time_stat.text = "Time: Time's up!"

	merges_stat.text = "Merges: %d" % int(stats.get("total_merges", 0))
	tier_stat.text = "Highest Tier: %d" % int(stats.get("highest_tier", 0))
	damage_stat.text = "Damage Dealt: %d / %d HP" % [int(stats.get("damage_dealt", 0)), int(stats.get("max_hp", 0))]


func _go_battle_select() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/BattleSelect.tscn")


func _replay() -> void:
	get_tree().change_scene_to_file("res://scenes/main/BattleScene.tscn")
