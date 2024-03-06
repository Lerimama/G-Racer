extends Node



func _on_ConfirmBtn_pressed() -> void:
	
	Set.set_game_settings(Set.Levels.TRAINING)
	Ref.main_node.home_out()


func _on_ConfirmBtn2_pressed() -> void:
	
	Set.set_game_settings(Set.Levels.NITRO)
	Ref.main_node.home_out()


func _on_ConfirmBtn3_pressed() -> void:
	Set.set_game_settings(Set.Levels.DUEL)
	Ref.main_node.home_out()
