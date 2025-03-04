extends Node


var game_level: Level
var drivers_in_game: Array # all valid and activated ki jih trackam, all ranked, tud non-actve
onready var game: Node2D = get_parent()


func _process(delta: float) -> void:

	# beleženje prisotnosti
	drivers_in_game = []
	for driver in get_tree().get_nodes_in_group(Rfs.group_drivers):
		if is_instance_valid(driver) and driver.is_active and not driver.is_queued_for_deletion():
			drivers_in_game.append(driver)

	# ranking
	if game.game_stage == game.GAME_STAGE.PLAYING:

		if drivers_in_game.size() > 1:
			_update_ranking()

		# camera leader
		if Sts.one_screen_mode:
			var new_camera_leader: Node2D = null
			for driver in drivers_in_game:
				if driver.is_in_group(Rfs.group_players):
					new_camera_leader = driver
					break
			game.camera_leader = new_camera_leader


		yield(get_tree(), "idle_frame")

		for driver in drivers_in_game:
			driver.update_stat(Pfs.STATS.LAP_TIME, game.hud.game_timer.game_time_hunds)


func _update_ranking():
	# najprej po poziciji znotraj kroga, potem po številu krogov

	var unranked_drivers: Array = drivers_in_game.duplicate()
	var drivers_ranked: Array = []

	# RACING
	if game.level_profile["rank_by"] == Pfs.RANK_BY.TIME:
		# tracking
		if game_level.level_track:
			# najprej rangiram trackerje
			var all_driver_trackers: Array = []
			for unranked_driver in unranked_drivers: all_driver_trackers.append(unranked_driver.driver_tracker)
			all_driver_trackers.sort_custom(self, "_sort_trackers_by_offset")
			# pol napolnim drivers_ranked glede na rankg trackerja
			for driver_tracker in all_driver_trackers: drivers_ranked.append(driver_tracker.tracking_target)
		# goals
		elif not game_level.level_goals.empty():
			drivers_ranked = unranked_drivers
			drivers_ranked.sort_custom(self, "_sort_drivers_by_goals_reached")
		# pol rangirane po trackerju rangiram po prevoženih krogih
		if game.level_profile["level_laps"] > 1:
			drivers_ranked.sort_custom(self, "_sort_drivers_by_laps")

	# BATTLE
	else:
		# rangiram po točkah
		drivers_ranked = unranked_drivers
		drivers_ranked.sort_custom(self, "_sort_drivers_by_points")

	# ranking stats
	var players_ranked: Array = []
	for ranked_driver in drivers_ranked:
		var prev_rank: int = ranked_driver.driver_stats[Pfs.STATS.LEVEL_RANK]
		var new_rank: int = drivers_ranked.find(ranked_driver) + 1
		if not new_rank == prev_rank:
			ranked_driver.update_stat(Pfs.STATS.LEVEL_RANK, new_rank)
		if ranked_driver.is_in_group(Rfs.group_players):
			players_ranked.append(ranked_driver)

	if not players_ranked[0] == game.camera_leader:
		game.camera_leader = players_ranked[0]

	drivers_in_game = drivers_ranked


# SORING ------------------------------------------------------------------------------------------------------------


func _sort_drivers_by_laps(driver_1: Node2D, driver_2: Node2D): # desc
	# For two elements a and b, if the given method returns true, element b will be after element a in the array.

	var driver_1_lap_count: int = driver_1.driver_stats[Pfs.STATS.LAP_COUNT].size()
	var driver_2_lap_count: int = driver_2.driver_stats[Pfs.STATS.LAP_COUNT].size()
	if driver_1_lap_count > driver_2_lap_count:
		return true
	return false


func _sort_trackers_by_offset(driver_tracker_1, driver_tracker_2): # asc
	# For two elements a and b, if the given method returns true, element b will be after element a in the array.

	if driver_tracker_1.offset > driver_tracker_2.offset:
		return true
	return false


func _sort_drivers_by_goals_reached(driver_1: Node2D, driver_2: Node2D):# desc
	# For two elements a and b, if the given method returns true, element b will be after element a in the array.

	var driver_1_goals_to_reach_size: int = driver_1.driver.goals_to_reach.size()
	var driver_2_goals_to_reach_size: int = driver_2.driver.goals_to_reach.size()
	if driver_1_goals_to_reach_size < driver_2_goals_to_reach_size:
		return true
	return false


func _sort_drivers_by_points(driver_1: Node2D, driver_2: Node2D):# desc
	# For two elements a and b, if the given method returns true, element b will be after element a in the array.

	var driver_1_points: int = driver_1.driver_stats[Pfs.STATS.POINTS]
	var driver_2_points: int = driver_2.driver_stats[Pfs.STATS.POINTS]
	if driver_1_points > driver_2_points:
		return true
	return false


func _sort_drivers_by_speed(driver_1 , driver_2): # desc ... ne uporabljam

	if driver_1.velocity.length() > driver_2.velocity.length():
	    return true
	return false
