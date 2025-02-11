extends Control


onready var FinalRankingLine: PackedScene = preload("res://game/gui/FinalRankingLine.tscn")
onready var content: Control = $Content

func _ready() -> void:

	Rfs.game_over = self
	visible = false


func open_gameover(agents_on_finish_line: Array, agents_on_start: Array):

	set_scorelist(agents_on_finish_line, agents_on_start)

	var background_fadein_transparency: float = 1

	$Menu/RestartBtn.grab_focus()

	var fade_in = get_tree().create_tween()
	fade_in.tween_callback(self, "show")
	fade_in.tween_property(self, "modulate:a", 1, 1).from(0.0)
	# fade_in.parallel().tween_callback(Global.sound_manager, "stop_music", ["game_music_on_gameover"])
	# fade_in.parallel().tween_callback(Global.sound_manager, "play_gui_sfx", [selected_gameover_jingle])
	fade_in.parallel().tween_property($Panel, "modulate:a", background_fadein_transparency, 0.5).set_delay(0.5) # a = cca 140
	fade_in.tween_callback(self, "show_gameover_menu").set_delay(2)


func set_scorelist(agents_on_finish_line: Array, agents_on_start: Array):

	var results: VBoxContainer = $Content/Results

	# zazih
	for child in results.get_children():
		if not child.name == "Title":
			child.queue_free()

	# uvrščeni
	for agent in agents_on_finish_line:
		# spawn ranking line
		var new_ranking_line = FinalRankingLine.instance() # spawn ranking line
		# set ranking line
		var agent_index = agents_on_finish_line.find(agent)
		new_ranking_line.get_node("Rank").text = str(agent_index + 1) + ". Place"
		print(agent.name)
		new_ranking_line.get_node("Agent").text = agent.driver_profile["driver_name"]
#		new_ranking_line.get_node("Result").text = Mts.get_clock_time(agent.driver_stats["level_time"])
		new_ranking_line.get_node("Result").text = Mts.get_clock_time(Rfs.game_manager.level_stats[agent.driver_index][Pfs.STATS.LEVEL_TIME])
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

func _on_RestartBtn_pressed() -> void:
	Rfs.main_node.reload_game()


func _on_QuitBtn_pressed() -> void:
	$Menu/QuitBtn.set_disabled(true)
	Rfs.main_node.game_out()


func _on_QuitGameBtn_pressed() -> void:
	get_tree().quit()
