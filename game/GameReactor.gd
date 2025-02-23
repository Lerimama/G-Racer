extends Node


var game_level: Level

var slomo_in_progress: bool = false
var navigation_positions: Array # pozicije vseh navigation tiletov
var current_pull_positions: Array # že zasedene pozicije za preventanje nalaganja driverjev druga na drugega
var drivers_finished: Array # driverji v cilju

onready var game: Game = get_parent()


func _ready() -> void:

	Rfs.game_reactor = self


func _pull_driver_on_field(drivers_to_pull: Vehicle): # temp ... Vehicle class

	if game.game_stage == game.GAME_STAGE.PLAYING and Sts.one_screen_mode:

		if drivers_to_pull.is_active:

			var pull_position: Vector2 = _get_driver_pull_position(drivers_to_pull)
			drivers_to_pull.call_deferred("pull_on_screen", pull_position)

			# če preskoči ciljno črto jo dodaj, če jo je leader prevozil
			# poenotim level goals/laps stats ... če ni pulan točno preko cilja, pa bi moral bit
			if drivers_to_pull.driver_stats[Pfs.STATS.LAP_COUNT].size() < game.camera_leader.driver_stats[Pfs.STATS.LAP_COUNT].size():
				drivers_to_pull.update_stat(Pfs.STATS.LAP_COUNT, game.camera_leader.driver_stats[Pfs.STATS.LAP_COUNT])
			# mogoče tega spodej nebi mel ... bomo videlo po testu
			if drivers_to_pull.driver_stats[Pfs.STATS.GOALS_REACHED].size() < game.camera_leader.driver_stats[Pfs.STATS.GOALS_REACHED].size():
				drivers_to_pull.update_stat(Pfs.STATS.GOALS_REACHED, game.camera_leader.driver_stats[Pfs.STATS.GOALS_REACHED])


func _get_driver_pull_position(drivers_to_pull: Node2D): # temp ... Vehicle class
	# na koncu izbrana pull pozicija:
	# - je na območju navigacije
	# - upošteva razdaljo do vodilnega
	# - se ne pokriva z drugim plejerjem
	#	printt ("current_pull_positions",current_pull_positions.size())

	# pull pozicija brez omejitev
	var pull_position_distance_from_leader: float = drivers_to_pull.near_radius # pull razdalja od vodilnega plejerja

	var vector_to_leading_player: Vector2 = game.camera_leader.global_position - drivers_to_pull.global_position
	var vector_to_pull_position: Vector2 = vector_to_leading_player - vector_to_leading_player.normalized() * pull_position_distance_from_leader
	var driver_pull_position: Vector2 = drivers_to_pull.global_position + vector_to_pull_position

	# implementacija omejitev, da ni na steni ali elementu ali drugemu plejerju
	var navigation_position_as_pull_position: Vector2
	var available_navigation_pull_positions: Array

	# poiščem navigacijsko celico, ki je najbližje določeni pull poziciji
	for cell_position in navigation_positions:
		# prva nav celica v preverjanju se opredeli kot trenutno najbližja
		if navigation_position_as_pull_position == Vector2.ZERO:
			navigation_position_as_pull_position = cell_position
		# ostale nav celice ... če je boljša, jo določim za novo opredeljeno
		else:
			# preverim, če je bližja od trenutno opredeljene ... itak da je
			if cell_position.distance_to(driver_pull_position) < navigation_position_as_pull_position.distance_to(driver_pull_position):
				# pozicija je dovolj stran od vodilnega
				if cell_position.distance_to(game.camera_leader.global_position) > pull_position_distance_from_leader:
					# če je pozicija zasedena
					if cell_position in current_pull_positions:
						var pull_pos_index: int = current_pull_positions.find(cell_position)
						var corrected_pull_position = pull_position_distance_from_leader + pull_pos_index
						if cell_position.distance_to(game.camera_leader.global_position) > corrected_pull_position:
							navigation_position_as_pull_position = cell_position
					else: # če je poza zasedena dobim njen in dex med zasedenimi dodam korekcijo na zahtevani razdalji od vodilnega
						navigation_position_as_pull_position = cell_position

	current_pull_positions.append(navigation_position_as_pull_position) # OBS trenutno ne rabim

	return navigation_position_as_pull_position


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
			reaching_driver.update_stat(Pfs.STATS.GOALS_REACHED, reached_goal)

			var reached_goals_count: int = reaching_driver.driver_stats[Pfs.STATS.GOALS_REACHED].size()
			# next goal
			if reached_goals_count < game_level.level_goals.size():
				Rfs.sound_manager.play_sfx("little_horn")
				reaching_driver.driver.goal_reached(reached_goal)
			# to finish
			elif game_level.level_finish:
				Rfs.sound_manager.play_sfx("little_horn")
				reaching_driver.driver.goal_reached(reached_goal, game_level.level_finish)
			# all goals reached
			else:
				Rfs.sound_manager.play_sfx("finish_horn")
				reaching_driver.driver.goal_reached(reached_goal)
				drivers_finished.append(reaching_driver)
				reaching_driver.motion_manager.drive_out(Vector2.ZERO) # ga tudi deaktivira


func _on_finish_crossed(crossing_driver: Vehicle): # sproži finish line  # temp ... Vehicle class

	if game.game_stage >= game.GAME_STAGE.PLAYING and crossing_driver.is_active == true: # > ai lahko pride v cilj po igri

		var driver_goals_reached: Array = crossing_driver.driver_stats[Pfs.STATS.GOALS_REACHED].duplicate()

		# ne registriram, če niso izpolnjeni pogoji v krogu oz dirki
		if game_level.level_goals.empty() or driver_goals_reached == game_level.level_goals:

			# stat level time ... ostale čase preračuna driver v update stats
			crossing_driver.update_stat(Pfs.STATS.LEVEL_TIME, game.hud.game_timer.game_time_hunds)

			var has_finished_level: bool = false

			# WITH LAPS ... lap finished če so vsi čekpointi
			if game.level_profile["level_laps"] > 1:
#				var lap_time: float = crossing_driver.driver_stats[Pfs.STATS.LAP_TIME]
				crossing_driver.update_stat(Pfs.STATS.LAP_COUNT, game.hud.game_timer.game_time_hunds) # ... ostale lap statse preračuna driver v update stats
				if crossing_driver.driver_stats[Pfs.STATS.LAP_COUNT].size() >= game.level_profile["level_laps"]:
					has_finished_level = true
			else:
				has_finished_level = true

			if has_finished_level:
				Rfs.sound_manager.play_sfx("finish_horn")
				drivers_finished.append(crossing_driver)
				var drive_out_position: Vector2 = Vector2.ZERO
				if game_level.level_finish:	drive_out_position = game_level.level_finish.drive_out_position_node.global_position
				crossing_driver.motion_manager.drive_out(drive_out_position) # ga tudi deaktivira
			else:
				Rfs.sound_manager.play_sfx("little_horn")


func _on_body_exited_playing_field(body: Node) -> void:

	#	if body.is_in_group(Rfs.group_drivers):
	if body.is_in_group(Rfs.group_players) and body.is_active:
		_pull_driver_on_field(body)
	elif body.has_method("on_out_of_playing_field"):
		body.on_out_of_playing_field() # ta funkcija zakasni učinek


func _on_vehicle_deactivated(driver_vehicle: Vehicle):
#	printt("deactivated", driver_vehicle, game.game_tracker.drivers_in_game.has(driver_vehicle))

	# finale data za vse ki so še v igri
	if driver_vehicle in drivers_finished:
		driver_vehicle.driver_stats[Pfs.STATS.LEVEL_RANK] = drivers_finished.size()
		if drivers_finished.size() == 1: # zmaga
			driver_vehicle.update_stat(Pfs.STATS.WINS, game.level_profile) # temp WINS pozicija
	else:
		driver_vehicle.driver_stats[Pfs.STATS.LEVEL_RANK] = -1
	game.finale_game_data[driver_vehicle.driver_name_id] = { # more bit id, da ni odvisen od obstoja vehicle noda
		"driver_profile": driver_vehicle.driver_profile,
		"driver_stats": driver_vehicle.driver_stats,
		}

	# hide view
	if Sts.hide_view_on_player_deactivated:# and not Sts.one_screen_mode: # ne uporabljam, ker ne smem zbrisat original viewa
		var hide_view_time: float
		var removed_game_view: ViewportContainer = game.game_views.find_key(driver_vehicle)
		if removed_game_view and game.game_views.size() > 1: # preverim, da ni zadnji view
			removed_game_view.queue_free()
			game.game_views.erase(removed_game_view)
			game._set_game_views(game.game_views.size()) # setam preostale
			game.hud.driver_huds_holder.remove_view_imitator(game.game_views) # odstranim imitatorja ... more bit za setanje game_views

	_check_for_game_end()

