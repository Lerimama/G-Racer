extends HBoxContainer


func _ready() -> void:
	pass # Replace with function body.


func _on_PlayBtn_pressed() -> void:
	Rfs.main_node.home_out()


func _on_SettingsBtn_pressed() -> void:
	pass # Replace with function body.


func _on_AboutBtn_pressed() -> void:
	pass # Replace with function body.


func _on_QuitBtn_pressed() -> void:
	get_tree().quit()
