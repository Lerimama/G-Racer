extends HBoxContainer


func _ready() -> void:

	$AiBtn.pressed = Sts.enemies_mode
	$EasyBtn.pressed = Sts.easy_mode


func _on_AiBtn_toggled(button_pressed: bool) -> void:

	Sts.enemies_mode = button_pressed


func _on_EasyBtn_toggled(button_pressed: bool) -> void:

	Sts.easy_mode = button_pressed
