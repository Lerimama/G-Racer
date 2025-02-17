extends Node


var game_level: Level

var agents_in_game: Array # live data ... tekom igre so v ranked zaporedju (glede na distanco)
var players_in_game: Array # live data ... tekom igre so v ranked zaporedju (glede na distanco)
var ais_in_game: Array # live data ... tekom igre so v ranked zaporedju (glede na distanco)
var agents_in_game_ranked: Array = []
var agents_in_game_active: Array = []

onready var game_parent: Game = get_parent()


func _process(delta: float) -> void:

	if game_level:
		# beleženje prisotnosti
		agents_in_game = get_tree().get_nodes_in_group(Rfs.group_agents)
		players_in_game = []
		ais_in_game = []
		for agent in agents_in_game:
			if is_instance_valid(agent) and agent.is_active:
				agents_in_game_active.append(agent)
				if get_tree().get_nodes_in_group(Rfs.group_players).has(agent): players_in_game.append(agent)
				if get_tree().get_nodes_in_group(Rfs.group_ai).has(agent): ais_in_game.append(agent)

			if not is_instance_valid(agent):
				agents_in_game.erase(agent)

		# ranking
		if agents_in_game.size() > 1:
			agents_in_game_ranked = _update_ranking(agents_in_game)
		else:
			agents_in_game_ranked = agents_in_game


func _update_ranking(unranked_agents: Array):
	# najprej po poziciji znotraj kroga, potem po številu krogov

	var agents_ranked: Array = []

	# RACING
	if game_level.level_type == Pfs.BASE_TYPE.RACING:
		# tracking
		if game_level.level_track:
			# najprej rangiram trackerje
			var all_agent_trackers: Array = []
			for unranked_agent in unranked_agents: all_agent_trackers.append(unranked_agent.agent_tracker)
			all_agent_trackers.sort_custom(self, "_sort_trackers_by_offset")
			# pol napolnim agents_ranked glede na rankg trackerja
			for agent_tracker in all_agent_trackers: agents_ranked.append(agent_tracker.tracking_target)
		# goals
		elif not game_level.level_goals.empty():
			agents_ranked = unranked_agents.duplicate()
			agents_ranked.sort_custom(self, "_sort_agents_by_goals_reached")
			pass
		# pol rangirane po trackerju rangiram po prevoženih krogih
		if game_parent.level_profile["level_laps"] > 1: agents_ranked.sort_custom(self, "_sort_agents_by_laps")
		agents_in_game = agents_ranked

	# BATTLE
	elif game_level.level_type == Pfs.BASE_TYPE.BATTLE:
		# rangiram po točkah
		agents_ranked = unranked_agents.duplicate()
		agents_ranked.sort_custom(self, "_sort_agents_by_points")


	# ranking stats
	var players_ranked: Array = []
	for ranked_agent in agents_ranked:
		var prev_rank: int = game_parent.level_stats[ranked_agent.driver_index][Pfs.STATS.LEVEL_RANK]
		var new_rank: int = agents_ranked.find(ranked_agent) + 1
		if not new_rank == prev_rank:
			game_parent.level_stats[ranked_agent.driver_index][Pfs.STATS.LEVEL_RANK] = new_rank
			game_parent.hud.update_agent_level_stats(ranked_agent.driver_index, Pfs.STATS.LEVEL_RANK, new_rank)
		if ranked_agent.is_in_group(Rfs.group_players):
			players_ranked.append(ranked_agent)

	if not players_ranked[0] == game_parent.game_reactor.camera_leader:
		game_parent.game_reactor.camera_leader = players_ranked[0]

	return agents_ranked



# SORING ------------------------------------------------------------------------------------------------------------


func _sort_agents_by_laps(agent_1: Node2D, agent_2: Node2D): # desc
	# For two elements a and b, if the given method returns true, element b will be after element a in the array.

	var agent_1_lap_count: int = game_parent.level_stats[agent_1.driver_index][Pfs.STATS.LAPS_FINISHED].size()
	var agent_2_lap_count: int = game_parent.level_stats[agent_2.driver_index][Pfs.STATS.LAPS_FINISHED].size()
	if agent_1_lap_count > agent_2_lap_count:
		return true
	return false


func _sort_trackers_by_offset(agent_tracker_1, agent_tracker_2):# desc
	# For two elements a and b, if the given method returns true, element b will be after element a in the array.

	if agent_tracker_1.offset > agent_tracker_2.offset:
		return true
	return false


func _sort_agents_by_goals_reached(agent_1: Node2D, agent_2: Node2D):# desc
	# For two elements a and b, if the given method returns true, element b will be after element a in the array.

	var agent_1_goals_to_reach_size: int = agent_1.controller.goals_to_reach.size()
	var agent_2_goals_to_reach_size: int = agent_2.controller.goals_to_reach.size()
	if agent_1_goals_to_reach_size < agent_2_goals_to_reach_size:
		return true
	return false


func _sort_agents_by_points(agent_1: Node2D, agent_2: Node2D):# desc
	# For two elements a and b, if the given method returns true, element b will be after element a in the array.

	var agent_1_points: int = agent_1.driver_stats[Pfs.STATS.POINTS]
	var agent_2_points: int = agent_2.driver_stats[Pfs.STATS.POINTS]
	if agent_1_points > agent_2_points:
		return true
	return false


func _sort_trackers_by_speed(agent_1, agent_2): # desc ... ne uporabljam

	if agent_1.velocity.length() > agent_2.velocity.length():
	    return true
	return false
