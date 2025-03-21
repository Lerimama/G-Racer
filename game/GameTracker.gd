extends Node

var game: Game # poda GM na ready
var game_level: Level

# drivers
var drivers_in_game: Array # all valid and activated ki jih trackam, all ranked, tud non-actve
var camera_leader: Node2D = null
var drivers_finished: Array # driverji v cilju, predvsem za določanje ranka v cilju (ki ni isti kot med tekmo

# game
var slomo_in_progress: bool = false
var current_pull_positions: Array # že zasedene pozicije za preventanje nalaganja driverjev druga na drugega


func _ready() -> void:

	Refs.game_tracker = self


func _process(delta: float) -> void:

	# beleženje prisotnosti
	drivers_in_game = []
	for driver in get_tree().get_nodes_in_group(Refs.group_drivers):
		if is_instance_valid(driver) and driver.is_active and not driver.is_queued_for_deletion():
			drivers_in_game.append(driver)

	# ranking
	if game.game_stage == game.GAME_STAGE.PLAYING:

		if drivers_in_game.size() > 1 and not game.level_profile["rank_by"] == Pros.RANK_BY.NONE:
			_update_ranking()

		# camera leader
		if Sets.mono_view_mode:
			var new_camera_leader: Node2D = null
			for driver in drivers_in_game:
				if driver.is_in_group(Refs.group_players):
					new_camera_leader = driver
					break
			_update_camera_leader(new_camera_leader)

		yield(get_tree(), "idle_frame")

		# per frame RACING stats
		if game.level_profile["rank_by"] == Pros.RANK_BY.TIME:
			for driver in drivers_in_game:
				driver.update_stat(Pros.STATS.LAP_TIME, game.gui.hud.game_timer.game_time_hunds)
				if game_level.tracking_line.is_enabled:
					driver.update_stat(Pros.STATS.LEVEL_PROGRESS, driver.driver_tracker.unit_offset)


func _update_ranking():
	# najprej po poziciji znotraj kroga, potem po številu krogov
	# Pros.RANK_BY.NODE ne kliče te funkcije

	var unranked_drivers: Array = drivers_in_game.duplicate()
	var drivers_ranked: Array = []

	if game.level_profile["rank_by"] == Pros.RANK_BY.TIME:
		# tracking
		if game_level.tracking_line.is_enabled:
			# najprej rangiram trackerje
			var all_driver_trackers: Array = []
			for unranked_driver in unranked_drivers:
				all_driver_trackers.append(unranked_driver.driver_tracker)
			all_driver_trackers.sort_custom(self, "_sort_trackers_by_offset")
			# pol napolnim drivers_ranked glede na rankg trackerja
			for driver_tracker in all_driver_trackers:
				drivers_ranked.append(driver_tracker.tracking_target)
		# goals
		elif not game_level.level_goals.empty():
			drivers_ranked = unranked_drivers
			drivers_ranked.sort_custom(self, "_sort_drivers_by_goals_reached")
		# pol rangirane po trackerju rangiram po prevoženih krogih
		if game.level_profile["level_laps"] > 1:
			drivers_ranked.sort_custom(self, "_sort_drivers_by_laps")

	elif game.level_profile["rank_by"] == Pros.RANK_BY.POINTS:
		# rangiram po točkah
		drivers_ranked = unranked_drivers
		drivers_ranked.sort_custom(self, "_sort_drivers_by_points")

	# update stats
	var allready_finished_count: int = drivers_finished.size() # adaptacija ranka, ker so tisti v cilju neaktivni
	var players_ranked: Array = []
	for ranked_driver in drivers_ranked:
		var prev_rank: int = ranked_driver.driver_stats[Pros.STATS.LEVEL_RANK]
		var new_rank: int = drivers_ranked.find(ranked_driver) + 1 + allready_finished_count
		if not new_rank == prev_rank:
			ranked_driver.update_stat(Pros.STATS.LEVEL_RANK, new_rank)
		if ranked_driver.is_in_group(Refs.group_players):
			players_ranked.append(ranked_driver)

	# drivers in game
	drivers_in_game = drivers_ranked


func _check_for_game_end():
	# igre je konec, ko so v cilju vsi plejerji, ki so še aktivni
	# SUCCES je, če je vsaj en plejer v cilju
	# FAIL je če ni nobenega

	if game.game_stage == game.GAME_STAGE.PLAYING:
		var continue_game: bool = false

		# preverim, če kakšen plejer še dirka
		for player in get_tree().get_nodes_in_group(Refs.group_players):
			if player.is_active and not player in drivers_finished:
				continue_game = true
				break

		# preverim succes, če je konec
		if not continue_game:
			_update_camera_leader(null)
			var is_successful: bool = false
			for player in get_tree().get_nodes_in_group(Refs.group_players):
				if player in drivers_finished:
					is_successful = true
					break
			if is_successful:
				game.game_stage = game.GAME_STAGE.END_SUCCESS
			else:
				game.game_stage = game.GAME_STAGE.END_FAIL


# REAKT ------------------------------------------------------------------------------------------------------


func _update_camera_leader(new_camera_leader: Node2D):

	if not new_camera_leader == camera_leader:
		camera_leader = new_camera_leader
		get_tree().set_group(Refs.group_player_cameras, "follow_target", camera_leader)


func _pull_vehicle_on_field(vehicle_to_pull: Vehicle): # temp ... Vehicle class

	if game.game_stage == game.GAME_STAGE.PLAYING:# and Sets.mono_view_mode:

		if vehicle_to_pull.is_active and camera_leader:
			var pull_position: Vector2 = _get_pull_position(vehicle_to_pull.global_position)
			vehicle_to_pull.pull_on_screen(pull_position)

			# poenotim level goals/laps stats ... če ni pulan točno preko cilja, pa bi moral bit
			var lap_count_diff: int = camera_leader.driver_stats[Pros.STATS.LAP_COUNT].size() - vehicle_to_pull.driver_stats[Pros.STATS.LAP_COUNT].size()
			for count in lap_count_diff:
				var uncounted_lap_time: float = 0
				vehicle_to_pull.update_stat(Pros.STATS.LAP_COUNT, uncounted_lap_time)
			# poenotim goals ... mogoče nebi mel ... bomo videli po testu
			for goal in camera_leader.driver_stats[Pros.STATS.GOALS_REACHED]:
				if not goal in vehicle_to_pull.driver_stats[Pros.STATS.GOALS_REACHED]:
					vehicle_to_pull.update_stat(Pros.STATS.GOALS_REACHED, goal)


func _get_pull_position(vehicle_to_pull_position: Vector2):

	# točna leading pozicija
	#			var pull_position: Vector2 = vehicle_to_pull_position + vector_to_leading_player
	# near raduis - closest
	#			var vector_to_leading_player: Vector2 = camera_leader.global_position - vehicle_to_pull_position
	#			var distance_with_near_radius_adapt: float = vector_to_leading_player.length() - camera_leader.near_radius
	#			var pull_position: Vector2 = vehicle_to_pull_position + vector_to_leading_player.normalized() * distance_with_near_radius_adapt
	# near raduis - vzporedna
	var leader_left_near_position: Vector2 = camera_leader.global_position + Vector2.UP.rotated(camera_leader.global_rotation) * camera_leader.near_radius
	var leader_right_near_position: Vector2 = camera_leader.global_position + Vector2.DOWN.rotated(camera_leader.global_rotation) * camera_leader.near_radius
	var vector_to_left_position: Vector2 = leader_left_near_position - vehicle_to_pull_position
	var vector_to_right_position: Vector2 = leader_right_near_position - vehicle_to_pull_position
	var vector_to_pull_position: Vector2 = Vector2.ZERO
	if vector_to_left_position.length() < vector_to_right_position.length():
		vector_to_pull_position = vector_to_left_position
	else:
		vector_to_pull_position = vector_to_right_position

	return vehicle_to_pull_position + vector_to_pull_position


func animate_day_night():

	var day_length: float = 10
	var day_start_direction: Vector2 = Vector2.LEFT

	var day_night_tween = get_tree().create_tween()
	for shadow in get_tree().get_nodes_in_group(Refs.group_shadows):
		if shadow is Polygon2D:
			day_night_tween.parallel().tween_property(shadow, "shadow_rotation_deg", 0, day_length).from(-180).set_ease(Tween.EASE_IN_OUT)


func apply_slomo(affector: Node2D, affectee: Node2D ):
	# tukaj je odločeno ali slomo ali ne
	# manjka ...da se čas slomo povečuje ob multuplih klicih

	if Sets.slomo_fx_on and not slomo_in_progress:
		var apply_slomo: bool = false
		# če je driver pošlje driverja in se odloči glede na zdravje
		if "driver_stats" in affectee:
			if not affectee.driver_stats[Pros.STATS.HEALTH] - affector.hit_damage > 0:
				apply_slomo = true
		# drugače se odloča glede na vrsto
		elif affectee.has_method("on_hit"):
			apply_slomo = true
		if apply_slomo:
			get_tree().set_group(Refs.group_player_cameras, "dynamic_zoom_on", false)
			get_tree().set_group(Refs.group_player_cameras, "shake_camera_on", false)
			slomo_in_progress = true
			var new_time_scale: float = Sets.slomo_time_scale
			var slomo_fx_time: float = 2 * Sets.slomo_time_scale # prilagotim, ker v slomo je čas počasnejši
			var slomo_transition_time: float = 0.1
			var slomo_tween = get_tree().create_tween()
			slomo_tween.tween_property(Engine, "time_scale", new_time_scale, slomo_transition_time)
			#			Engine.time_scale = new_time_scale
			yield(get_tree().create_timer(slomo_fx_time), "timeout")
			#			Engine.time_scale = 1
			var back_to_normal_tween = get_tree().create_tween()
			back_to_normal_tween.tween_property(Engine, "time_scale", 1, slomo_transition_time * 2)
			yield(back_to_normal_tween, "finished")
			get_tree().set_group(Refs.group_player_cameras, "shake_camera_on", true) # _temp ... kaj pa če noče?
			get_tree().set_group(Refs.group_player_cameras, "dynamic_zoom_on", true) # _temp ... kaj pa če noče?
			slomo_in_progress = false



# SIGNALI ------------------------------------------------------------------------------------------------------


func _on_game_time_is_up():

	# če je potekel čas je verjetno še kdo v igri
	for driver in drivers_in_game:
		driver.is_active = false

	_check_for_game_end()


func _on_fx_finished(finished_fx: Node): # Node, ker je lahko audio

	if is_instance_valid(finished_fx):
		finished_fx.queue_free()


func _on_goal_reached(reached_goal: Node, reaching_driver: Vehicle): # level poveže  # temp ... Vehicle class
#	prints ("GOAL", reached_goal)
	# reagirata driver in igra
	# če je finish line v goalih, im ta vseeno svojo funkcijo

	if game.game_stage >= game.GAME_STAGE.PLAYING:

		# če je goal med level goali in če ni že dosežen
		if reached_goal.name in game.level_profile["level_goals"] \
		and not reached_goal in reaching_driver.driver_stats[Pros.STATS.GOALS_REACHED]:

			# dodam med dosežene
			reaching_driver.update_stat(Pros.STATS.GOALS_REACHED, reached_goal)
			if reaching_driver.controller.has_method("on_goal_reached"):# is_in_group(Refs.group_ai):
				reaching_driver.controller.on_goal_reached(reached_goal, game.game_level.finish_line)

			# preverim če so doseženi vsi cilji ... razen finish line
			var all_goals_reached: bool = true
			for goal in game_level.level_goals:
				if not goal in reaching_driver.driver_stats[Pros.STATS.GOALS_REACHED]:
					all_goals_reached = false
					break

			if not all_goals_reached:
				game.game_sound.little_horn.play()
			else:
				reaching_driver.update_stat(Pros.STATS.LAP_COUNT, game.gui.hud.game_timer.game_time_hunds)
				var all_laps_finished: bool = false
				if reaching_driver.driver_stats[Pros.STATS.LAP_COUNT].size() >= game.level_profile["level_laps"]:
					all_laps_finished = true
				# goals reset for next lap
				if not all_laps_finished:
					reaching_driver.driver_stats[Pros.STATS.GOALS_REACHED] = []
					game.game_sound.little_horn.play()
				# finish level
				else:

					game.game_sound.big_horn.play()
					reaching_driver.update_stat(Pros.STATS.LEVEL_TIME, game.gui.hud.game_timer.game_time_hunds) # more bit pred drive out
					drivers_finished.append(reaching_driver)
					reaching_driver.motion_manager.drive_out(Vector2.ZERO) # ga tudi deaktivira


func _on_finish_crossed(finish_line: Node2D, crossing_driver: Vehicle): # sproži finish line  # temp ... Vehicle class
#	prints("over finish lined", crossing_driver)

	if game.game_stage >= game.GAME_STAGE.PLAYING:# >= da ai lahko pride v cilj po igri

		# LAP
		var has_lap_conditions: bool = false
		if crossing_driver.driver_stats[Pros.STATS.GOALS_REACHED].size() >= game_level.level_goals.size(): # lahko ji ima več ker se goali lahko kvefrijajo
			# če ni igra z goali je 0 == 0 => true
			has_lap_conditions = true
		if game_level.tracking_line.is_enabled:
			if game_level.tracking_line.checkpoints_count == 0:
				has_lap_conditions = true
			elif crossing_driver.driver_tracker.all_checkpoints_reached:
				has_lap_conditions = true

		if has_lap_conditions:
			crossing_driver.update_stat(Pros.STATS.LAP_COUNT, game.gui.hud.game_timer.game_time_hunds)

			# FINISH
			var all_laps_finished: bool = false
			if game_level.level_type == game_level.LEVEL_TYPE.RACING_GOALS and game_level.level_goals.empty():
				# če so bili vsi cilji kvefrijani, ni več krogov ...
				# možnost tega ni dobra praksa ... pazi pri postavljanju levelov
				all_laps_finished = true
			if crossing_driver.driver_stats[Pros.STATS.LAP_COUNT].size() >= game.level_profile["level_laps"]:
				all_laps_finished = true
			# cilj
			if all_laps_finished:
				game.game_sound.big_horn.play()
				crossing_driver.update_stat(Pros.STATS.LEVEL_TIME, game.gui.hud.game_timer.game_time_hunds) # more bit pred drive out
				drivers_finished.append(crossing_driver)
				var drive_out_position: Vector2 = Vector2.ZERO
				if game_level.finish_line.is_enabled:
					drive_out_position = game_level.finish_line.drive_out_position_2d.global_position
				crossing_driver.motion_manager.drive_out(drive_out_position) # ga tudi deaktivira
			# nov krog
			else:
				game.game_sound.little_horn.play()
				# restirajo za nov krog
				crossing_driver.driver_stats[Pros.STATS.GOALS_REACHED] = []
				crossing_driver.driver_tracker.checked_checkpoints.clear()


func _on_goal_exiting_tree(exiting_goal: Node2D):
	# brišem iz level_goals na levelu, ker uporabljam tracking igre
	# brišem iz ai, ker uporabljam za njegovo obnašanje
	# ne biršem izlevel_profila, ker uporabljam samo za display
	# ne apdejtam (prikaza) statsov

	#	prints("goal exit", exiting_goal)
	game_level.level_goals.erase(exiting_goal)
	for driver in drivers_in_game:
		if driver.is_in_group(Refs.group_ai):
			driver.controller.goals_to_reach.erase(exiting_goal)
	#	prints("level goals after", game_level.level_goals)


func _on_player_exited_playing_field(player_vehicle: Node) -> void:
	# playingfield kolajda samo s plejerji

	_pull_vehicle_on_field(player_vehicle)


func _on_vehicle_deactivated(driver_vehicle: Vehicle):
#	printt("deactivated", driver_vehicle, drivers_in_game.has(driver_vehicle))

	# finale data za vse ki so še v igri
	if driver_vehicle in drivers_finished:
		var finished_driver_rank: int = drivers_finished.size()
		driver_vehicle.driver_stats[Pros.STATS.LEVEL_RANK] = finished_driver_rank
		# dodam zmago
		if finished_driver_rank == 1: # zmaga
			# curr/max ... popravi hud, veh update stats, veh spawn, veh deact
			driver_vehicle.update_stat(Pros.STATS.WINS, game.level_index)
			#			driver_vehicle.update_stat(Pros.STATS.WINS, 1) # temp WINS pozicija
		# dodam cash nagrado
		if not finished_driver_rank > Sets.ranking_cash_rewards.size() and not finished_driver_rank == -1:
			driver_vehicle.update_stat(Pros.STATS.CASH, Sets.ranking_cash_rewards[finished_driver_rank - 1])
	else:
		driver_vehicle.driver_stats[Pros.STATS.LEVEL_RANK] = -1

	game.final_drivers_data[driver_vehicle.driver_id]["driver_stats"] = driver_vehicle.driver_stats.duplicate()
	game.final_drivers_data[driver_vehicle.driver_id]["weapon_stats"] = driver_vehicle.weapon_stats.duplicate()
	# hide view
	game.gui.hud.get_parent().driver_huds_holder.unset_driver_hud(driver_vehicle.driver_id)

	#	if Sets.hide_view_on_player_deactivated:# and not Sets.mono_view_mode: # ne uporabljam, ker ne smem zbrisat original viewa
	#		var hide_view_time: float
	#		var removed_game_view: ViewportContainer = game.game_views.views_with_drivers.find_key(driver_vehicle)
	#		if removed_game_view and game.game_views.views_with_drivers.size() > 1: # preverim, da ni zadnji view
	#			removed_game_view.queue_free()
	#			game.game_views.views_with_drivers.erase(removed_game_view)
	#			game.hud.driver_huds_holder.remove_view_imitator(game.game_views.views_with_drivers) # odstranim imitatorja ... more bit za setanje game_views
	#			game.set_game_views(game.game_views.views_with_drivers.size()) # setam preostale

	_check_for_game_end()


# SORTERS ------------------------------------------------------------------------------------------------------------


func _sort_drivers_by_laps(driver_1: Vehicle, driver_2: Vehicle): # desc
	# For two elements a and b, if the given method returns true, element b will be after element a in the array.

	var driver_1_lap_count: int = driver_1.driver_stats[Pros.STATS.LAP_COUNT].size()
	var driver_2_lap_count: int = driver_2.driver_stats[Pros.STATS.LAP_COUNT].size()
	if driver_1_lap_count > driver_2_lap_count:
		return true
	return false


func _sort_trackers_by_offset(driver_tracker_1: PathFollow2D, driver_tracker_2: PathFollow2D): # desc ... TRUE = A before B

	if driver_tracker_1.offset > driver_tracker_2.offset:
		return true
	return false


func _sort_drivers_by_goals_reached(driver_1: Vehicle, driver_2: Vehicle):# desc ... TRUE = A before B
	# if TRUE, A before B

	var driver_1_goals_reached_count: int = driver_1.driver_stats[Pros.STATS.GOALS_REACHED].size()
	var driver_2_goals_reached_count: int = driver_2.driver_stats[Pros.STATS.GOALS_REACHED].size()
	if driver_1_goals_reached_count > driver_2_goals_reached_count:
		return true
	return false


func _sort_drivers_by_points(driver_1: Vehicle, driver_2: Vehicle):# desc ... TRUE = A before B

	var driver_1_points: int = driver_1.driver_stats[Pros.STATS.POINTS]
	var driver_2_points: int = driver_2.driver_stats[Pros.STATS.POINTS]
	if driver_1_points > driver_2_points:
		return true
	return false
