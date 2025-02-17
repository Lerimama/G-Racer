extends Control


onready var FinalRankingLine: PackedScene = preload("res://game/gui/FinalRankingLine.tscn")
onready var content: Control = $Content


func _ready() -> void:

	visible = false


func open(final_game_data: Dictionary):
	#	print("-")
	#	print("GO open")
	#	print(final_game_data)

	_set_scorelist(final_game_data)


	var fade_in = get_tree().create_tween()
	fade_in.tween_callback(self, "show")
	fade_in.tween_property(self, "modulate:a", 1, 1).from(0.0)
	yield(fade_in, "finished")
	$Menu/ContinueBtn.grab_focus()
	$Menu/QuitBtn.set_disabled(false)
	$Menu/ContinueBtn.set_disabled(false)


func _set_scorelist(final_game_data):

	var results: VBoxContainer = $Content/Results

	Mts.remove_chidren_and_get_template(results.get_children(), true)

	# uvrščeni
	var drivers_ranked: Array = []
	for driver_data in final_game_data:
		if not final_game_data[driver_data]["driver_level_stats"][Pfs.STATS.LEVEL_RANK] == -1:
			drivers_ranked.append(final_game_data[driver_data])
	# sortiram
	drivers_ranked.sort_custom(self, "_sort_driver_data_by_rank")
	# dodam neurvščene ... brezzaporedno
	for driver_data in final_game_data:
		if final_game_data[driver_data]["driver_level_stats"][Pfs.STATS.LEVEL_RANK] == -1:
			drivers_ranked.append(final_game_data[driver_data])

	# spawnam scoreline
	for ranked_driver_data in drivers_ranked:
		var new_ranking_line = FinalRankingLine.instance() # spawn ranking line
		if ranked_driver_data["driver_level_stats"][Pfs.STATS.LEVEL_RANK] == -1:
			new_ranking_line.get_node("Rank").text = "NN"
		else:
			new_ranking_line.get_node("Rank").text = str(ranked_driver_data["driver_level_stats"][Pfs.STATS.LEVEL_RANK]) + ". Place"
		new_ranking_line.get_node("Agent").text = ranked_driver_data["driver_profile"]["driver_name"]
		new_ranking_line.get_node("Result").text = Mts.get_clock_time(ranked_driver_data["driver_level_stats"][Pfs.STATS.LEVEL_TIME])
		results.add_child(new_ranking_line)


func _on_QuitBtn_pressed() -> void:

	Rfs.main_node.game_out()
#	Rfs.main_node.game_out()
	$Menu/QuitBtn.set_disabled(true)

func _on_QuitGameBtn_pressed() -> void:
	get_tree().quit()


func _on_ContinueBtn_pressed() -> void:
	$Menu/ContinueBtn.set_disabled(true)

	var fade_out_tween = get_tree().create_tween()
	fade_out_tween.tween_property(self, "modulate:a", 0, 1)
	fade_out_tween.tween_callback(self, "hide")
	yield(fade_out_tween, "finished")
	Rfs.game_manager.level_index += 1
	Rfs.game_manager._set_game()
