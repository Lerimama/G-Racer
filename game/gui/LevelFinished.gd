extends Control


onready var FinalRankingLine: PackedScene = preload("res://game/gui/FinalRankingLine.tscn")
onready var content: Control = $Content


func _ready() -> void:

	Rfs.level_completed = self
	visible = false


func open_level_finished(agents_on_finish_line: Array, agents_on_start: Array):

	set_scorelist(agents_on_finish_line, agents_on_start)


	var fade_in = get_tree().create_tween()
	fade_in.tween_callback(self, "show")
	fade_in.tween_property(self, "modulate:a", 1, 1).from(0.0)
	yield(fade_in, "finished")
	$Menu/ContinueBtn.grab_focus()
	$Menu/QuitBtn.set_disabled(false)
	$Menu/ContinueBtn.set_disabled(false)



func set_scorelist(agents_on_finish_line: Array, agents_on_start: Array):

	var results: VBoxContainer = $Content/Results
	# če je še od prejšnjega levela
	if not results.get_children().empty():
		for result_line in results.get_children():
			result_line.queue_free()

	# uvrščeni
	for agent in agents_on_finish_line:
		# spawn ranking line
		var new_ranking_line = FinalRankingLine.instance() # spawn ranking line
		# set ranking line
		var agent_index = agents_on_finish_line.find(agent)
		new_ranking_line.get_node("Rank").text = str(agent_index + 1) + ". Place"
		new_ranking_line.get_node("Agent").text = agent.driver_profile["driver_name"]
#		new_ranking_line.get_node("Result").text = Mts.get_clock_time(agent.driver_stats["level_time"])
		new_ranking_line.get_node("Result").text = Mts.get_clock_time(agent.driver_stats[Pfs.STATS.LEVEL_TIME])
		results.add_child(new_ranking_line)

		# izbrišem iz arraya, da ga ne upoštevam pri pisanju neuvrščenih
		if agents_on_start.has(agent):
			agents_on_start.erase(agent)

	# neuvrščeni
	for agent in agents_on_start: # array je že brez uvrščenih
		if not agents_on_finish_line.has(agent):
			var new_ranking_line = FinalRankingLine.instance() # spawn ranking line
			new_ranking_line.get_node("Rank").text = "NN"
			new_ranking_line.get_node("Agent").text = str(agent.driver_profile["driver_name"])
			new_ranking_line.get_node("Result").text = "did no finish"
			results.add_child(new_ranking_line)


func _on_QuitBtn_pressed() -> void:
	Rfs.main_node.game_out()
	$Menu/QuitBtn.set_disabled(true)

func _on_QuitGameBtn_pressed() -> void:
	get_tree().quit()


func _on_ContinueBtn_pressed() -> void:
	$Menu/ContinueBtn.set_disabled(true)

	var fade_out_tween = get_tree().create_tween()
	fade_out_tween.tween_property(self, "modulate:a", 0, 1)
	fade_out_tween.tween_callback(self, "hide")
	yield(fade_out_tween, "finished")
	Rfs.game_manager.set_next_level()

