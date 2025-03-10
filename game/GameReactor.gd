extends Node


var game_level: Level

var slomo_in_progress: bool = false
var current_pull_positions: Array # že zasedene pozicije za preventanje nalaganja driverjev druga na drugega
var drivers_finished: Array # driverji v cilju, predvsem za določanje ranka v cilju (ki ni isti kot med tekmo

onready var game: Game = get_parent()


func _ready() -> void:

	Rfs.game_reactor = self


func _pull_vehicle_on_field(vehicle_to_pull: Vehicle): # temp ... Vehicle class

	if game.game_stage == game.GAME_STAGE.PLAYING:# and Sts.one_screen_mode:

		if vehicle_to_pull.is_active:
			# točna leading pozicija
			#			var pull_position: Vector2 = vehicle_to_pull.global_position + vector_to_leading_player
			# near raduis - closest
			#			var vector_to_leading_player: Vector2 = game.camera_leader.global_position - vehicle_to_pull.global_position
			#			var distance_with_near_radius_adapt: float = vector_to_leading_player.length() - game.camera_leader.near_radius
			#			var pull_position: Vector2 = vehicle_to_pull.global_position + vector_to_leading_player.normalized() * distance_with_near_radius_adapt
			# near raduis - vzporedna
			var leader_left_near_position: Vector2 = game.camera_leader.global_position + Vector2.UP.rotated(game.camera_leader.global_rotation) * game.camera_leader.near_radius
			var leader_right_near_position: Vector2 = game.camera_leader.global_position + Vector2.DOWN.rotated(game.camera_leader.global_rotation) * game.camera_leader.near_radius
			var vector_to_left_position: Vector2 = leader_left_near_position - vehicle_to_pull.global_position
			var vector_to_right_position: Vector2 = leader_right_near_position - vehicle_to_pull.global_position
			var vector_to_pull_position: Vector2 = Vector2.ZERO
			if vector_to_left_position.length() < vector_to_right_position.length():
				vector_to_pull_position = vector_to_left_position
			else:
				vector_to_pull_position = vector_to_right_position

			var pull_position: Vector2 = vehicle_to_pull.global_position + vector_to_pull_position
			vehicle_to_pull.pull_on_screen(pull_position)

			# poenotim level goals/laps stats ... če ni pulan točno preko cilja, pa bi moral bit
			if vehicle_to_pull.driver_stats[Pfs.STATS.LAP_COUNT].size() < game.camera_leader.driver_stats[Pfs.STATS.LAP_COUNT].size():
				vehicle_to_pull.update_stat(Pfs.STATS.LAP_COUNT, game.camera_leader.driver_stats[Pfs.STATS.LAP_COUNT].duplicate())
			# mogoče tega spodej nebi mel ... bomo videlo po testu
			if vehicle_to_pull.driver_stats[Pfs.STATS.GOALS_REACHED].size() < game.camera_leader.driver_stats[Pfs.STATS.GOALS_REACHED].size():
				vehicle_to_pull.update_stat(Pfs.STATS.GOALS_REACHED, game.camera_leader.driver_stats[Pfs.STATS.GOALS_REACHED].duplicate())


func spawn_random_pickables():

	if game.game_stage == game.GAME_STAGE.PLAYING:
		if get_tree().get_nodes_in_group(Rfs.group_pickables).size() <= Sts.pickables_count_limit - 1:
			game_level.spawn_pickable()
		# random timer reštart
		var random_pickable_spawn_time: int = [1, 2, 3].pick_random()
		yield(get_tree().create_timer(random_pickable_spawn_time), "timeout") # OPT ... uvedi node timer
		spawn_random_pickables()


func animate_day_night():

	var day_length: float = 10
	var day_start_direction: Vector2 = Vector2.LEFT

	var day_night_tween = get_tree().create_tween()
	for shadow in get_tree().get_nodes_in_group(Rfs.group_shadows):
		if shadow is Polygon2D:
			day_night_tween.parallel().tween_property(shadow, "shadow_rotation_deg", 0, day_length).from(-180).set_ease(Tween.EASE_IN_OUT)


func apply_slomo(affector: Node2D, affectee: Node2D ):
	# tukaj je odločeno ali slomo ali ne
	# manjka ...da se čas slomo povečuje ob multuplih klicih

	if Sts.slomo_fx_on and not slomo_in_progress:
		var apply_slomo: bool = false
		# če je driver pošlje driverja in se odloči glede na zdravje
		if "driver_stats" in affectee:
			if not affectee.driver_stats[Pfs.STATS.HEALTH] - affector.hit_damage > 0:
				apply_slomo = true
		# drugače se odloča glede na vrsto
		elif affectee.has_method("on_hit"):
			apply_slomo = true
		if apply_slomo:
			get_tree().set_group(Rfs.group_player_cameras, "dynamic_zoom_on", false)
			get_tree().set_group(Rfs.group_player_cameras, "shake_camera_on", false)
			slomo_in_progress = true
			var new_time_scale: float = Sts.slomo_time_scale
			var slomo_fx_time: float = 2 * Sts.slomo_time_scale # prilagotim, ker v slomo je čas počasnejši
			var slomo_transition_time: float = 0.1
			var slomo_tween = get_tree().create_tween()
			slomo_tween.tween_property(Engine, "time_scale", new_time_scale, slomo_transition_time)
			#			Engine.time_scale = new_time_scale
			yield(get_tree().create_timer(slomo_fx_time), "timeout")
			#			Engine.time_scale = 1
			var back_to_normal_tween = get_tree().create_tween()
			back_to_normal_tween.tween_property(Engine, "time_scale", 1, slomo_transition_time * 2)
			yield(back_to_normal_tween, "finished")
			get_tree().set_group(Rfs.group_player_cameras, "shake_camera_on", true) # _temp ... kaj pa če noče?
			get_tree().set_group(Rfs.group_player_cameras, "dynamic_zoom_on", true) # _temp ... kaj pa če noče?
			slomo_in_progress = false


func _check_for_game_end():
	# igre je konec, ko so v cilju vsi plejerji, ki so še aktivni
	# SUCCES je, če je vsaj en plejer v cilju
	# FAIL je če ni nobenega

	if game.game_stage == game.GAME_STAGE.PLAYING:
		var continue_game: bool = false

		# preverim, če kakšen plejer še dirka
		for player in get_tree().get_nodes_in_group(Rfs.group_players):
			if player.is_active and not player in drivers_finished:
				continue_game = true
				break

		# preverim succes, če je konec
		if not continue_game:
#			game.camera_leader = null
			var is_successful: bool = false
			for player in get_tree().get_nodes_in_group(Rfs.group_players):
				if player in drivers_finished:
					is_successful = true
					break
			if is_successful:
				game.game_stage = game.GAME_STAGE.END_SUCCESS
			else:
				game.game_stage = game.GAME_STAGE.END_FAIL


# SIGNALI ------------------------------------------------------------------------------------------------------


func _on_game_time_is_up():

	# če je potekel čas je verjetno še kdo v igri
	for driver in game.game_tracker.drivers_in_game:
		driver.is_active = false

	_check_for_game_end()


func _on_fx_finished(finished_fx: Node): # Node, ker je lahko audio

	if is_instance_valid(finished_fx):
		finished_fx.queue_free()


func _on_goal_reached(reached_goal: Node, reaching_driver: Vehicle): # level poveže  # temp ... Vehicle class
	# reagirata driver in igra

	if game.game_stage == game.GAME_STAGE.PLAYING:

		# če je zaporedje, more bit goal enak prvemu v vrsti
		if not game_level.reach_goals_in_sequence or reached_goal == reaching_driver.goals_to_reach[0]:

			# dodam med dosežene
			reaching_driver.update_stat(Pfs.STATS.GOALS_REACHED, reached_goal.name)

			# ček če so vsi cilji doseženi
			var all_goals_reached: bool = true
			for goal in game_level.level_goals:
				var goal_name: String = goal.name
				if not goal_name in reaching_driver.driver_stats[Pfs.STATS.GOALS_REACHED]:
					all_goals_reached = false
					break

			# next goal
			if all_goals_reached:
				# to finish
				if game_level.level_finish:
					Rfs.sound_manager.play_sfx("little_horn")
					reaching_driver.driver.on_goal_reached(reached_goal, game_level.level_finish)
				# all goals reached and finished
				else:

					Rfs.sound_manager.play_sfx("finish_horn")
					reaching_driver.update_stat(Pfs.STATS.LEVEL_TIME, game.hud.game_timer.game_time_hunds) # more bit pred drive out
					reaching_driver.driver.on_goal_reached(reached_goal)
					drivers_finished.append(reaching_driver)
					reaching_driver.motion_manager.drive_out(Vector2.ZERO) # ga tudi deaktivira
			else:
				Rfs.sound_manager.play_sfx("little_horn")
				reaching_driver.driver.on_goal_reached(reached_goal)


func _on_finish_crossed(crossing_driver: Vehicle): # sproži finish line  # temp ... Vehicle class

	if game.game_stage >= game.GAME_STAGE.PLAYING and crossing_driver.is_active == true: # > ai lahko pride v cilj po igri

		# ček če so vsi cilji doseženi
		var all_goals_reached: bool = true
		for goal in game_level.level_goals:
			var goal_name: String = goal.name
			if not goal_name in crossing_driver.driver_stats[Pfs.STATS.GOALS_REACHED]:
				all_goals_reached = false
				break

		# ne registriram, če niso izpolnjeni pogoji v krogu oz dirki
		if all_goals_reached:
		#		if game_level.level_goals.empty() or crossing_driver.driver_stats[Pfs.STATS.GOALS_REACHED] == game_level.level_goals:
			var has_finished_level: bool = false
			# če ni krogov je lap count da stat ve za prehod cilja
			crossing_driver.update_stat(Pfs.STATS.LAP_COUNT, game.hud.game_timer.game_time_hunds)

			if crossing_driver.driver_stats[Pfs.STATS.LAP_COUNT].size() >= game.level_profile["level_laps"]:
				has_finished_level = true
			if has_finished_level:
				Rfs.sound_manager.play_sfx("finish_horn")
				crossing_driver.update_stat(Pfs.STATS.LEVEL_TIME, game.hud.game_timer.game_time_hunds) # more bit pred drive out
				drivers_finished.append(crossing_driver)
				var drive_out_position: Vector2 = Vector2.ZERO
				if game_level.level_finish:	drive_out_position = game_level.level_finish.drive_out_position_node.global_position
				crossing_driver.motion_manager.drive_out(drive_out_position) # ga tudi deaktivira
			else:
				Rfs.sound_manager.play_sfx("little_horn")


func _on_body_exited_playing_field(player_vehicle: Node) -> void:
	# playingfield kolajda samo s plejerji

	_pull_vehicle_on_field(player_vehicle)


func _on_vehicle_deactivated(driver_vehicle: Vehicle):
#	printt("deactivated", driver_vehicle, game.game_tracker.drivers_in_game.has(driver_vehicle))

	# finale data za vse ki so še v igri
	if driver_vehicle in drivers_finished:
		var finished_driver_rank: int = drivers_finished.size()
		driver_vehicle.driver_stats[Pfs.STATS.LEVEL_RANK] = finished_driver_rank
		# dodam zmago
		if finished_driver_rank == 1: # zmaga
			# curr/max ... popravi hud, veh update stats, veh spawn, veh deact
			driver_vehicle.update_stat(Pfs.STATS.WINS, game.level_index)
			#			driver_vehicle.update_stat(Pfs.STATS.WINS, 1) # temp WINS pozicija
		# dodam cash nagrado
		if not finished_driver_rank > Sts.ranking_cash_rewards.size() and not finished_driver_rank == -1:
			driver_vehicle.update_stat(Pfs.STATS.CASH, Sts.ranking_cash_rewards[finished_driver_rank - 1])
	else:
		driver_vehicle.driver_stats[Pfs.STATS.LEVEL_RANK] = -1

	game.final_drivers_data[driver_vehicle.driver_id]["driver_stats"] = driver_vehicle.driver_stats.duplicate()


	# hide view
	if Sts.hide_view_on_player_deactivated:# and not Sts.one_screen_mode: # ne uporabljam, ker ne smem zbrisat original viewa
		var hide_view_time: float
		var removed_game_view: ViewportContainer = game.game_views.views_with_drivers.find_key(driver_vehicle)
		if removed_game_view and game.game_views.views_with_drivers.size() > 1: # preverim, da ni zadnji view
			removed_game_view.queue_free()
			game.game_views.views_with_drivers.erase(removed_game_view)
			game.set_game_views(game.game_views.views_with_drivers.size()) # setam preostale
			game.hud.driver_huds_holder.remove_view_imitator(game.game_views.views_with_drivers) # odstranim imitatorja ... more bit za setanje game_views

	_check_for_game_end()

