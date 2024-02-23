extends Control


func _ready() -> void:
	visible = false
#	$Menu/RestartBtn.focu


func _on_RestartBtn_pressed() -> void:
	Ref.main_node.reload_game()


func _on_QuitBtn_pressed() -> void:
	
	Ref.main_node.game_out()
