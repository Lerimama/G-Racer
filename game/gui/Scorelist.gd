extends VBoxContainer


onready var FinalRankingLine: PackedScene = preload("res://game/gui/Scoreline.tscn")


func _ready() -> void:

	# reset
	for child in get_children(): child.queue_free()


func set_scorelist(final_level_data: Dictionary):

	for driver_id in final_level_data:
		var new_ranking_line = FinalRankingLine.instance() # spawn ranking line
		add_child(new_ranking_line)
	yield(get_tree(),"idle_frame") # more bit, da apdejta zmage
	update_scorelines(final_level_data)


func update_scorelines(final_level_data):
	# za vsak scoreline poiščem driver data po ranku

	var updated_scorelines_count: int = 0

	# uvrščeni
	for driver_id in final_level_data:
		if not final_level_data[driver_id].empty():
			var driver_rank: int = final_level_data[driver_id]["driver_stats"][Pfs.STATS.LEVEL_RANK]
			if driver_rank > 0:
				update_ranked_scoreline_data(get_child(driver_rank - 1), final_level_data, driver_id)
				updated_scorelines_count += 1
	# še v igri
	for driver_id in final_level_data:
		if final_level_data[driver_id].empty():
			get_child(updated_scorelines_count).get_node("Name").text = str(driver_id)
			get_child(updated_scorelines_count).get_node("Rank").text = "..."
			get_child(updated_scorelines_count).get_node("Result").text = "... waiting"
			updated_scorelines_count += 1

	# diskvalificirani
	for driver_id in final_level_data:
		if not final_level_data[driver_id].empty():
			var driver_rank: int = final_level_data[driver_id]["driver_stats"][Pfs.STATS.LEVEL_RANK]
			if driver_rank == -1:
				get_child(updated_scorelines_count).get_node("Name").text = str(driver_id)
				get_child(updated_scorelines_count).get_node("Rank").text = "NN"
				get_child(updated_scorelines_count).get_node("Result").text = "disqualified"
				updated_scorelines_count += 1


func update_ranked_scoreline_data(scoreline, final_level_data, ranked_driver_id):

	var ranked_driver_data = final_level_data[ranked_driver_id]
	var drivers_rank: int = ranked_driver_data["driver_stats"][Pfs.STATS.LEVEL_RANK]

	scoreline.get_node("Rank").text = str(drivers_rank) + ". Place"
	scoreline.get_node("Name").text = str(ranked_driver_id)
	scoreline.get_node("Result").text = Mts.get_clock_time(ranked_driver_data["driver_stats"][Pfs.STATS.LEVEL_TIME])
	scoreline.get_node("StatWins").stat_value = [ranked_driver_data["driver_stats"][Pfs.STATS.WINS].size(), Sts.wins_goal_count]
	scoreline.get_node("Reward").text = "$%d" % ranked_driver_data["driver_stats"][Pfs.STATS.CASH]

