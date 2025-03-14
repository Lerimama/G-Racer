extends HBoxContainer


func _ready() -> void:

	$AiBtn.pressed = Sets.enemies_mode
	$EasyBtn.pressed = Sets.easy_mode


func _on_AiBtn_toggled(button_pressed: bool) -> void:

	Sets.enemies_mode = button_pressed


func _on_EasyBtn_toggled(button_pressed: bool) -> void:

	Sets.easy_mode = button_pressed
