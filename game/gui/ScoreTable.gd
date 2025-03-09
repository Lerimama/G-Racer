extends VBoxContainer


onready var FinalRankingLine: PackedScene = preload("res://game/gui/ScoreLine.tscn")

var rank_scoreline_path: String = "Rank/Rank"
var avatar_scoreline_path: String = "Id/Line/Avatar"
var name_scoreline_path: String = "Id/Line/Name"
var result_scoreline_path: String = "Result/Result"
var wins_scoreline_path: String = "Stats/Line/StatWins"
var reward_scoreline_path: String = "Stats/Line/Reward"


func _ready() -> void:

	# reset
	for child in get_children(): child.queue_free()


func set_scorelist(drivers_data: Dictionary):

	for child in get_children(): child.queue_free()

	for driver_id in drivers_data:
		var new_ranking_line = FinalRankingLine.instance() # spawn ranking line
		add_child(new_ranking_line)

	yield(get_tree(),"idle_frame") # more bit, da apdejta zmage
	update_scorelines(drivers_data)


func update_scorelines(drivers_data):
	# za vsak scoreline poiščem driver data po ranku

	var updated_scorelines_count: int = 0

	# uvrščeni ... fixed
	for driver_id in drivers_data:
		if "driver_stats" in drivers_data[driver_id]:
			var driver_rank: int = drivers_data[driver_id]["driver_stats"][Pfs.STATS.LEVEL_RANK]
			if driver_rank > 0:
				update_ranked_scoreline_data(get_child(driver_rank - 1), drivers_data, driver_id)
				updated_scorelines_count += 1

	# še v igri ... se apdejta ko umrje ali pride v cilj
	for driver_id in drivers_data:
		if not "driver_stats" in drivers_data[driver_id]:
			var updated_scoreline: Control = get_child(updated_scorelines_count)
			updated_scoreline.get_node(rank_scoreline_path).text = "."
			updated_scoreline.get_node(avatar_scoreline_path).texture = drivers_data[driver_id]["driver_profile"]["driver_avatar"]
			updated_scoreline.get_node(name_scoreline_path).text = str(driver_id)
			updated_scoreline.get_node(result_scoreline_path).text = "WAITING"
			updated_scorelines_count += 1

	# diskvalificirani ... fixed
	for driver_id in drivers_data:
		if "driver_stats" in drivers_data[driver_id]:
			var driver_rank: int = drivers_data[driver_id]["driver_stats"][Pfs.STATS.LEVEL_RANK]
			if driver_rank == -1:
				var updated_scoreline: Control = get_child(updated_scorelines_count)
				updated_scoreline.get_node(rank_scoreline_path).text = "/"
				updated_scoreline.get_node(avatar_scoreline_path).texture = drivers_data[driver_id]["driver_profile"]["driver_avatar"]
				updated_scoreline.get_node(name_scoreline_path).text = str(driver_id)
				updated_scoreline.get_node(result_scoreline_path).text = "OUT"
				updated_scoreline.get_node(wins_scoreline_path).stat_value = [drivers_data[driver_id]["driver_stats"][Pfs.STATS.WINS].size(), Sts.wins_goal_count]
				updated_scoreline.get_node(reward_scoreline_path).text = "$%d" % drivers_data[driver_id]["driver_stats"][Pfs.STATS.CASH]
				updated_scorelines_count += 1


func update_ranked_scoreline_data(scoreline, drivers_data, ranked_driver_id):

	var ranked_driver_data = drivers_data[ranked_driver_id]
	var drivers_rank: int = ranked_driver_data["driver_stats"][Pfs.STATS.LEVEL_RANK]

	scoreline.get_node(avatar_scoreline_path).texture = ranked_driver_data["driver_profile"]["driver_avatar"]
	scoreline.get_node(rank_scoreline_path).text = str(drivers_rank)# + ". Place"
	scoreline.get_node(name_scoreline_path).text = str(ranked_driver_id)
	scoreline.get_node(result_scoreline_path).text = Mts.get_clock_time_string(ranked_driver_data["driver_stats"][Pfs.STATS.LEVEL_TIME])
	scoreline.get_node(wins_scoreline_path).stat_value = [ranked_driver_data["driver_stats"][Pfs.STATS.WINS].size(), Sts.wins_goal_count]
	scoreline.get_node(reward_scoreline_path).text = "$%d" % ranked_driver_data["driver_stats"][Pfs.STATS.CASH]
