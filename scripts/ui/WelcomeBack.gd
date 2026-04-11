extends CanvasLayer

@onready var earned_label: Label = $Panel/VBox/EarnedLabel
@onready var collect_button: Button = $Panel/VBox/Buttons/CollectButton
@onready var double_button: Button = $Panel/VBox/Buttons/DoubleButton

var _amount: int = 0
var _awaiting_ad: bool = false


func setup(amount: int) -> void:
	_amount = amount
	if is_node_ready():
		earned_label.text = "You earned %d Essence while away!" % amount


func _ready() -> void:
	collect_button.pressed.connect(_on_collect_pressed)
	double_button.pressed.connect(_on_double_pressed)
	earned_label.text = "You earned %d Essence while away!" % _amount


func _on_collect_pressed() -> void:
	EconomyManager.collect_offline_earnings(false)
	queue_free()


func _on_double_pressed() -> void:
	if _awaiting_ad:
		return
	_awaiting_ad = true
	double_button.disabled = true
	AdManager.show_rewarded_ad(func(success: bool) -> void:
		_awaiting_ad = false
		if not is_inside_tree():
			return
		if success:
			EconomyManager.collect_offline_earnings(true)
			queue_free()
		else:
			double_button.disabled = false
	)
