extends Control


onready var FinalRankingLine: PackedScene = preload("res://game/gui/FinalRankingLine.tscn")
onready var content: Control = $Content


func _ready() -> void:

	visible = false


func open(final_game_data):
	#	print("-")
	#	print("GO open")
	#	print(final_game_data)

	_set_scorelist(final_game_data)

	var background_fadein_transparency: float = 1

	$Menu/RestartBtn.grab_focus()

	var fade_in = get_tree().create_tween()
	fade_in.tween_callback(self, "show")
	fade_in.tween_property(self, "modulate:a", 1, 1).from(0.0)
	# fade_in.parallel().tween_callback(Global.sound_manager, "stop_music", ["game_music_on_gameover"])
	# fade_in.parallel().tween_callback(Global.sound_manager, "play_gui_sfx", [selected_gameover_jingle])
	fade_in.parallel().tween_property($Panel, "modulate:a", background_fadein_transparency, 0.5).set_delay(0.5) # a = cca 140
	fade_in.tween_callback(self, "show_gameover_menu").set_delay(2)


func _set_scorelist(final_game_data):

	var results: VBoxContainer = $Content/Results

	Mts.remove_chidren_and_get_template(results.get_children(), true)

	# uvrščeni
	var drivers_ranked: Array = []
	for driver_data in final_game_data:
		if not final_game_data[driver_data]["driver_stats"][Pfs.STATS.LEVEL_RANK] == -1:
			drivers_ranked.append(final_game_data[driver_data])
	# sortiram
	drivers_ranked.sort_custom(self, "_sort_driver_data_by_rank")
	# dodam neurvščene ... brezzaporedno
	for driver_data in final_game_data:
		if final_game_data[driver_data]["driver_stats"][Pfs.STATS.LEVEL_RANK] == -1:
			drivers_ranked.append(final_game_data[driver_data])

	# spawnam scoreline
	for ranked_driver_data in drivers_ranked:
		var new_ranking_line = FinalRankingLine.instance() # spawn ranking line
		if ranked_driver_data["driver_stats"][Pfs.STATS.LEVEL_RANK] == -1:
			new_ranking_line.get_node("Rank").text = "NN"
		else:
			new_ranking_line.get_node("Rank").text = str(ranked_driver_data["driver_stats"][Pfs.STATS.LEVEL_RANK]) + ". Place"
		new_ranking_line.get_node("Agent").text = ranked_driver_data["driver_profile"]["driver_name"]
		new_ranking_line.get_node("Result").text = Mts.get_clock_time(ranked_driver_data["driver_stats"][Pfs.STATS.LEVEL_TIME])
		results.add_child(new_ranking_line)


func _sort_driver_data_by_rank(driver_data_1: Dictionary, driver_data_2: Dictionary): # ascecnd a1 < a2
	# For two elements a and b, if the given method returns true, element b will be after element a in the array.

	var driver_1_rank: int = driver_data_1["driver_stats"][Pfs.STATS.LEVEL_RANK]
	var driver_2_rank: int = driver_data_2["driver_stats"][Pfs.STATS.LEVEL_RANK]
	if driver_1_rank < driver_2_rank:
		return true
	return false


func _on_RestartBtn_pressed() -> void:

	Rfs.main_node.reload_game()
#	Rfs.main_node.reload_game()


func _on_QuitBtn_pressed() -> void:
	$Menu/QuitBtn.set_disabled(true)
	Rfs.main_node.game_out()
#	Rfs.main_node.game_out()


func _on_QuitGameBtn_pressed() -> void:
	get_tree().quit()
