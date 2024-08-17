extends Control


onready var FinalRankingLine: PackedScene = preload("res://game/ui/FinalRankingLine.tscn")
onready var content: Control = $Content


func _ready() -> void:
	
	Ref.level_completed = self
	visible = false


func open(bolts_on_finish_line: Array, bolts_on_start: Array):
	
	set_scorelist(bolts_on_finish_line, bolts_on_start)
	
	
	var fade_in = get_tree().create_tween()
	fade_in.tween_callback(self, "show")
	fade_in.tween_property(self, "modulate:a", 1, 1).from(0.0)
	yield(fade_in, "finished")
	$Menu/ContinueBtn.grab_focus()
	$Menu/QuitBtn.set_disabled(false)
	$Menu/ContinueBtn.set_disabled(false)

	
	
func set_scorelist(bolts_on_finish_line: Array, bolts_on_start: Array):

	var results: VBoxContainer = $Content/Results
	# če je še od prejšnjega levela
	if not results.get_children().empty():
		for result_line in results.get_children():
			result_line.queue_free()
			
	# uvrščeni
	for bolt in bolts_on_finish_line:
		# spawn ranking line
		var new_ranking_line = FinalRankingLine.instance() # spawn ranking line
		# set ranking line
		var bolt_index = bolts_on_finish_line.find(bolt)
		new_ranking_line.get_node("Rank").text = str(bolt_index + 1) + ". Place"
		new_ranking_line.get_node("Bolt").text = bolt.player_name
		new_ranking_line.get_node("Result").text = Met.get_clock_time(bolt.bolt_stats["level_time"])
		results.add_child(new_ranking_line)
		
		# izbrišem iz arraya, da ga ne upoštevam pri pisanju neuvrščenih
		if bolts_on_start.has(bolt):
			bolts_on_start.erase(bolt)
			
	# neuvrščeni
	for bolt in bolts_on_start: # array je že brez uvrščenih
		if not bolts_on_finish_line.has(bolt):
			var new_ranking_line = FinalRankingLine.instance() # spawn ranking line
			new_ranking_line.get_node("Rank").text = "NN"
			new_ranking_line.get_node("Bolt").text = str(bolt.player_name)
			new_ranking_line.get_node("Result").text = "did no finish"
			results.add_child(new_ranking_line)
			

func _on_QuitBtn_pressed() -> void:
	Ref.main_node.game_out()
	$Menu/QuitBtn.set_disabled(true)

func _on_QuitGameBtn_pressed() -> void:
	get_tree().quit()


func _on_ContinueBtn_pressed() -> void:
	$Menu/ContinueBtn.set_disabled(true)
	
	var fade_out_tween = get_tree().create_tween()
	fade_out_tween.tween_property(self, "modulate:a", 0, 1)
	fade_out_tween.tween_callback(self, "hide")
	yield(fade_out_tween, "finished")
	Ref.game_manager.set_next_level()
	
