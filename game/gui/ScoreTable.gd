extends VBoxContainer


onready var FinalRankingLine: PackedScene = preload("res://game/gui/ScoreLine.tscn")

var rank_label_path: String = "Rank/Rank"
var avatar_rect_path: String = "Id/Line/Avatar"
var name_label_path: String = "Id/Line/Name"
var result_label_path: String = "Result/Result"
var stat_icons_path: String = "Stats/Line/StatIcons"
var stat_label_path: String = "Stats/Line/StatText"


func _ready() -> void:

	# reset
	for child in get_children():
		child.queue_free()


func set_scoretable(drivers_data: Dictionary, rank_by: int, for_summary: bool):

	for child in get_children():
		child.queue_free()

	for driver_id in drivers_data:
		var new_ranking_line = FinalRankingLine.instance() # spawn ranking line
		add_child(new_ranking_line)

	yield(get_tree(),"idle_frame") # more bit, da se vsebina pravilno apdejta

	if for_summary:
		_update_scorelines_for_summary(drivers_data)
	else:
		_update_scorelines_for_level(drivers_data, rank_by)


func _update_scorelines_for_summary(drivers_data: Dictionary):

#	print("after")
#	print(drivers_data)
	var summary_data: Dictionary ={}
	var tournament_ranking_arrays: Array = []
	for driver_id in drivers_data:
		var driver_array: Array = [driver_id, drivers_data[driver_id]["tournament_stats"][Pros.STAT.TOURNAMENT_POINTS]]
		tournament_ranking_arrays.append(driver_array)
	tournament_ranking_arrays.sort_custom(self, "_sort_ranking_on_points")

	for ranked_array in tournament_ranking_arrays:
		var ranked_array_index: int = tournament_ranking_arrays.find(ranked_array)
		var ranked_driver_id: String = ranked_array[0]
		var driver_data: Dictionary = drivers_data[ranked_driver_id]
		var updated_scoreline: Control = get_child(ranked_array_index)
		updated_scoreline.get_node(rank_label_path).text = str(ranked_array_index + 1)
		updated_scoreline.get_node(avatar_rect_path).texture = drivers_data[ranked_driver_id]["driver_profile"]["driver_avatar"]
		updated_scoreline.get_node(name_label_path).text = ranked_array[0]
		updated_scoreline.get_node(result_label_path).text = str(ranked_array[1])
		updated_scoreline.get_node(stat_label_path).text = "ALL $%d" % driver_data["driver_stats"][Pros.STAT.CASH]


func _sort_ranking_on_points(ranking_array_1: Array, ranking_array_2: Array):

	if ranking_array_1[1] > ranking_array_2[1]:
		return true
	return false


func _sort_on_ranking(ranking_array_1: Array, ranking_array_2: Array):

	if ranking_array_1[1] < ranking_array_2[1]:
		return true
	return false


func _update_scorelines_for_level(drivers_data: Dictionary, rank_by: int):
	# dodam uvrščene ... razporedim po ranku (drivers data ni nujno zaporedno)
	# dodam čakane
	# dodam neuvrščene

	var level_ranking_arrays: Array = []
	for driver_id in drivers_data:
		var driver_array: Array = [driver_id, drivers_data[driver_id]["driver_stats"][Pros.STAT.LEVEL_RANK]]
		level_ranking_arrays.append(driver_array)
	level_ranking_arrays.sort_custom(self, "_sort_on_ranking")

	var _temp_reward_per: int = 1000

	# result
	match rank_by:
		Levs.RANK_BY.POINTS:
			var updated_scorelines_count: int = 0
			for ranking_array in level_ranking_arrays:
				var driver_id: String = ranking_array[0]
				var ranked_driver_rank: int = ranking_array[1]
				var driver_rank: int = drivers_data[driver_id]["driver_stats"][Pros.STAT.LEVEL_RANK]
				var updated_scoreline: Control = get_child(updated_scorelines_count)
				updated_scoreline.get_node(rank_label_path).text = str(driver_rank) + "_P"
				updated_scoreline.get_node(avatar_rect_path).texture = drivers_data[driver_id]["driver_profile"]["driver_avatar"]
				updated_scoreline.get_node(name_label_path).text = str(driver_id)

				# result
				drivers_data[driver_id]["driver_stats"][Pros.STAT.POINTS] = _temp_reward_per * drivers_data[driver_id]["driver_stats"][Pros.STAT.GOALS_REACHED].size()
				updated_scoreline.get_node(result_label_path).text = "%d" % drivers_data[driver_id]["driver_stats"][Pros.STAT.POINTS]

				# reward
				if driver_rank > Sets.level_cash_rewards.size():
					updated_scoreline.get_node(stat_label_path).text = "RWD $0"
				else:
					updated_scoreline.get_node(stat_label_path).text = "RWD $%d" % Sets.level_cash_rewards[driver_rank - 1]
				updated_scorelines_count += 1

		Levs.RANK_BY.SCALPS:
			var updated_scorelines_count: int = 0
			for ranking_array in level_ranking_arrays:
				var driver_id: String = ranking_array[0]
				var ranked_driver_rank: int = ranking_array[1]
				var driver_rank: int = drivers_data[driver_id]["driver_stats"][Pros.STAT.LEVEL_RANK]
				var updated_scoreline: Control = get_child(updated_scorelines_count)
				updated_scoreline.get_node(rank_label_path).text = str(driver_rank) + "_S"
				updated_scoreline.get_node(avatar_rect_path).texture = drivers_data[driver_id]["driver_profile"]["driver_avatar"]
				updated_scoreline.get_node(name_label_path).text = str(driver_id)

				# result
				drivers_data[driver_id]["driver_stats"][Pros.STAT.POINTS] = _temp_reward_per * drivers_data[driver_id]["driver_stats"][Pros.STAT.SCALPS].size()
				updated_scoreline.get_node(result_label_path).text = "%d" % drivers_data[driver_id]["driver_stats"][Pros.STAT.SCALPS].size()

				# reward
				if driver_rank > Sets.level_cash_rewards.size():
					updated_scoreline.get_node(stat_label_path).text = "RWD $0"
				else:
					updated_scoreline.get_node(stat_label_path).text = "RWD $%d" % Sets.level_cash_rewards[driver_rank - 1]
				updated_scorelines_count += 1
		Levs.RANK_BY.TIME:
			#			var level_ranking_arrays: Array = []
			#			for driver_id in drivers_data:
			#				var driver_array: Array = [driver_id, drivers_data[driver_id]["driver_stats"][Pros.STAT.LEVEL_RANK]]
			#				level_ranking_arrays.append(driver_array)
			#			level_ranking_arrays.sort_custom(self, "_sort_on_ranking")
			var updated_scorelines_count: int = 0
			# uvrščeni
			for ranking_array in level_ranking_arrays:
				var driver_id: String = ranking_array[0]
				var ranked_driver_rank: int = ranking_array[1]
				var driver_rank: int = drivers_data[driver_id]["driver_stats"][Pros.STAT.LEVEL_RANK]
				if driver_rank > 0:
					var updated_scoreline: Control = get_child(updated_scorelines_count)
					updated_scoreline.get_node(rank_label_path).text = str(driver_rank)
					updated_scoreline.get_node(avatar_rect_path).texture = drivers_data[driver_id]["driver_profile"]["driver_avatar"]
					updated_scoreline.get_node(name_label_path).text = str(driver_id)
					updated_scoreline.get_node(result_label_path).text = Mets.get_clock_time_string(drivers_data[driver_id]["driver_stats"][Pros.STAT.LEVEL_FINISHED_TIME])
					# reward
					if driver_rank > Sets.level_cash_rewards.size():
						updated_scoreline.get_node(stat_label_path).text = "RWD $0"
					else:
						updated_scoreline.get_node(stat_label_path).text = "RWD $%d" % Sets.level_cash_rewards[driver_rank - 1]
					updated_scorelines_count += 1
			# čakani
			for driver_id in drivers_data:
				var driver_rank: int = drivers_data[driver_id]["driver_stats"][Pros.STAT.LEVEL_RANK]
				if driver_rank == 0:
					var updated_scoreline: Control = get_child(updated_scorelines_count)
					updated_scoreline.get_node(rank_label_path).text = "."
					updated_scoreline.get_node(avatar_rect_path).texture = drivers_data[driver_id]["driver_profile"]["driver_avatar"]
					updated_scoreline.get_node(name_label_path).text = str(driver_id)
					updated_scoreline.get_node(result_label_path).text = "WAITING"
					updated_scoreline.get_node(stat_label_path).text = "RWD $?"
					updated_scorelines_count += 1
			# disq
			for driver_id in drivers_data:
				var driver_rank: int = drivers_data[driver_id]["driver_stats"][Pros.STAT.LEVEL_RANK]
				if driver_rank == -1:
					var updated_scoreline: Control = get_child(updated_scorelines_count)
					updated_scoreline.get_node(rank_label_path).text = "/"
					updated_scoreline.get_node(avatar_rect_path).texture = drivers_data[driver_id]["driver_profile"]["driver_avatar"]
					updated_scoreline.get_node(name_label_path).text = str(driver_id)
					updated_scoreline.get_node(result_label_path).text = "DISQ"
					updated_scoreline.get_node(stat_label_path).text = "RWD $0"
					updated_scorelines_count += 1

