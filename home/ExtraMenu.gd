extends HBoxContainer


func _ready() -> void:

	$AiBtn.pressed = 	Sts.default_game_settings["enemies_mode"]
	$EasyBtn.pressed = Sts.default_game_settings["easy_mode"]


func _on_AiBtn_toggled(button_pressed: bool) -> void:

	Sts.default_game_settings["enemies_mode"] = button_pressed


func _on_EasyBtn_toggled(button_pressed: bool) -> void:

	Sts.default_game_settings["easy_mode"] = button_pressed
