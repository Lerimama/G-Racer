extends Control


onready var RankingLine: PackedScene = preload("res://game/RankingLine.tscn")


func _ready() -> void:
	
	Ref.game_over = self
	visible = false


func open_gameover(gameover_reason: int, bolts_on_finish_line):
	
	show()
	set_scorelist(bolts_on_finish_line)
	
	
func set_scorelist(bolts_on_finish_line: Array):

	var results: VBoxContainer = $VBoxContainer/Results
	
	for bolt_on_finish_line in bolts_on_finish_line:
		
		# spawn ranking line
		var new_ranking_line = RankingLine.instance() # spawn ranking line
		# set ranking line
		var bolt_index = bolts_on_finish_line.find(bolt_on_finish_line)
		new_ranking_line.get_node("Rank").text = str(bolt_index + 1) + ". Place"
		new_ranking_line.get_node("Bolt").text = bolt_on_finish_line[0].player_name
		new_ranking_line.get_node("Result").text = bolt_on_finish_line[0].player_name
		
		# add ranking line to scene
		results.add_child(new_ranking_line)


func _on_RestartBtn_pressed() -> void:
	Ref.main_node.reload_game()


func _on_QuitBtn_pressed() -> void:
	
	Ref.main_node.game_out()
	
