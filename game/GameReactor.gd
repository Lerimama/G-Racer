extends Node


var game_level: Level

var camera_leader: Node2D = null setget _change_camera_leader
var slomo_in_progress: bool = false
var available_pickable_positions: Array # za random spawn
var navigation_positions: Array # pozicije vseh navigation tiletov
var current_pull_positions: Array # že zasedene pozicije za preventanje nalaganja agento druga na drugega
var agents_finished: Array # agenti v cilju

onready var game_parent: Game = get_parent()


func _ready() -> void:

	Rfs.game_reactor = self


func _pull_agent_on_field(agent_to_pull: Node2D): # temp ... Vechile class

	if game_parent.game_stage == game_parent.GAME_STAGE.PLAYING and Sts.one_screen_mode:

		if agent_to_pull.is_active:

			var agent_pull_position: Vector2 = _get_agent_pull_position(agent_to_pull)
			agent_to_pull.call_deferred("pull_on_screen", agent_pull_position)

			# če preskoči ciljno črto jo dodaj, če jo je leader prevozil
			var pulled_agent_level_stats: Dictionary = game_parent.level_stats[agent_to_pull.driver_index]
			var leader_agent_level_stats: Dictionary = game_parent.level_stats[camera_leader.driver_index]

			# poenotim level goals/laps stats ... če ni pulan točno preko cilja, pa bi moral bit
			if pulled_agent_level_stats[Pfs.STATS.LAPS_FINISHED].size() < leader_agent_level_stats[Pfs.STATS.LAPS_FINISHED].size():
				pulled_agent_level_stats[Pfs.STATS.LAPS_FINISHED] = leader_agent_level_stats[Pfs.STATS.LAPS_FINISHED]
			# mogoče tega spodej nebi mel ... bomo videlo po testu
			if pulled_agent_level_stats[Pfs.STATS.GOALS_REACHED].size() < leader_agent_level_stats[Pfs.STATS.GOALS_REACHED].size():
				pulled_agent_level_stats[Pfs.STATS.GOALS_REACHED] = leader_agent_level_stats[Pfs.STATS.GOALS_REACHED]


func _get_agent_pull_position(agent_to_pull: Node2D): # temp ... Vechile class
	# na koncu izbrana pull pozicija:
	# - je na območju navigacije
	# - upošteva razdaljo do vodilnega
	# - se ne pokriva z drugim plejerjem
	#	printt ("current_pull_positions",current_pull_positions.size())

	# pull pozicija brez omejitev
	var pull_position_distance_from_leader: float = agent_to_pull.near_radius # pull razdalja od vodilnega plejerja

	var vector_to_leading_player: Vector2 = camera_leader.global_position - agent_to_pull.global_position
	var vector_to_pull_position: Vector2 = vector_to_leading_player - vector_to_leading_player.normalized() * pull_position_distance_from_leader
	var agent_pull_position: Vector2 = agent_to_pull.global_position + vector_to_pull_position

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
			if cell_position.distance_to(agent_pull_position) < navigation_position_as_pull_position.distance_to(agent_pull_position):
				# pozicija je dovolj stran od vodilnega
				if cell_position.distance_to(camera_leader.global_position) > pull_position_distance_from_leader:
					# če je pozicija zasedena
					if current_pull_positions.has(cell_position):
						var pull_pos_index: int = current_pull_positions.find(cell_position)
						var corrected_pull_position = pull_position_distance_from_leader + pull_pos_index
						if cell_position.distance_to(camera_leader.global_position) > corrected_pull_position:
							navigation_position_as_pull_position = cell_position
					else: # če je poza zasedena dobim njen in dex med zasedenimi dodam korekcijo na zahtevani razdalji od vodilnega
						navigation_position_as_pull_position = cell_position

	current_pull_positions.append(navigation_position_as_pull_position) # OBS trenutno ne rabim

	return navigation_position_as_pull_position


func spawn_random_pickables():

	if game_parent.game_stage == game_parent.GAME_STAGE.PLAYING:

		if available_pickable_positions.empty():
			return

		if get_tree().get_nodes_in_group(Rfs.group_pickables).size() <= Sts.pickables_count_limit - 1:

			# žrebanje tipa
			var random_pickable_key = Pfs.pickable_profiles.keys().pick_random()
			var random_cell_position: Vector2 = navigation_positions.pick_random()
			game_level.spawn_pickable(random_cell_position, "random_pickable_key", random_pickable_key)

			# odstranim celico iz arraya tistih na voljo
			var random_cell_position_index: int = available_pickable_positions.find(random_cell_position)
			available_pickable_positions.remove(random_cell_position_index)

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

	var all_players_finished_or_deactivated: bool = true

	# preverim, če kakšen plejer še dirka
	for player in game_parent.game_tracker.players_in_game:
		if player.is_active and not agents_finished.has(player):
			all_players_finished_or_deactivated = false
			break

	# če je konec, preverim succes
	var is_success: bool = false
	if all_players_finished_or_deactivated:
		for player in game_parent.game_tracker.players_in_game:
			if agents_finished.has(player):
				is_success = true
		# apliciram stage ... pošlje signal
		if is_success:
			game_parent.game_stage = game_parent.GAME_STAGE.END_SUCCESS
		else:
			game_parent.game_stage = game_parent.GAME_STAGE.END_FAIL


func _change_camera_leader(new_camera_leader: Node2D):

	if not new_camera_leader == camera_leader:
		camera_leader = new_camera_leader
		if Sts.one_screen_mode and not camera_leader == null:
			get_tree().set_group(Rfs.group_player_cameras, "follow_target", camera_leader)



# SIGNALI ------------------------------------------------------------------------------------------------------


func _on_game_time_is_up():
		# če je potekel čas je verjetno še kdo v igri
	get_tree().set_group(Rfs.group_agents, "is_active", false)
#	for agent in game_parent.game_tracker.agents_in_game:
#		# če se disejbla sam na GO signal je prepozno za final game data
#		if agent.is_active:
#			agent.is_active = false


func _on_fx_finished(finished_fx: Node): # Node, ker je lahko audio

	if is_instance_valid(finished_fx):
		finished_fx.queue_free()


func _on_agent_reached_goal(current_goal: Node, agent_reaching: Node2D): # level poveže  # temp ... Vechile class
	# reagirata agent in igra

	if game_parent.game_stage == game_parent.GAME_STAGE.PLAYING:

		# če je zaporedje, more bit goal enak prvemu v vrsti
		if not game_level.reach_goals_in_sequence or current_goal == agent_reaching.goals_to_reach[0]:

			# dodam med dosežene
			var agent_level_stats: Dictionary = game_parent.level_stats[agent_reaching.driver_index]
			agent_level_stats[Pfs.STATS.GOALS_REACHED].append(current_goal)

			# next ...
			var reached_goals_count: int = agent_level_stats[Pfs.STATS.GOALS_REACHED].size()
			if reached_goals_count < game_level.level_goals.size():
				agent_reaching.controller.goal_reached(current_goal)
				Rfs.sound_manager.play_sfx("little_horn")
			elif game_level.level_finish:
				agent_reaching.controller.goal_reached(current_goal, game_level.level_finish)
				Rfs.sound_manager.play_sfx("little_horn")
			else:
				agent_reaching.controller.goal_reached(current_goal)
				Rfs.sound_manager.play_sfx("finish_horn")
				agents_finished.append(agent_reaching)

		_check_for_game_end()


func _on_finish_line_crossed(agent_across: Node2D): # sproži finish line  # temp ... Vechile class

	if game_parent.game_stage == game_parent.GAME_STAGE.PLAYING:

		var agent_level_data: Dictionary = game_parent.level_stats[agent_across.driver_index]
		var agent_goals_reached: Array = agent_level_data[Pfs.STATS.GOALS_REACHED].duplicate()

		# ne registriram, če niso izpolnjeni pogoji v krogu oz dirki
		if game_level.level_goals.empty() or agent_goals_reached == game_level.level_goals:

			# stat level time
			var prev_lap_level_time: float = agent_level_data[Pfs.STATS.LEVEL_TIME]
			agent_level_data[Pfs.STATS.LEVEL_TIME] = game_parent.hud.game_timer.game_time_hunds

			var has_finished_level: bool = false
			# WITH LAPS ... lap finished če so vsi čekpointi
			if game_parent.level_profile["level_laps"] > 1:
				var lap_time: float = agent_level_data[Pfs.STATS.LEVEL_TIME] - prev_lap_level_time
				agent_level_data[Pfs.STATS.LAPS_FINISHED].append(lap_time)
				if agent_level_data[Pfs.STATS.LAPS_FINISHED].size() >= game_parent.level_profile["level_laps"]:
					has_finished_level = true
			else:
				has_finished_level = true

			if has_finished_level:
				agents_finished.append(agent_across) # pred drive out, ker se tam deaktivira
				var drive_out_time: float = 1
				var drive_out_vector: Vector2 = Vector2.ZERO
				if game_level.drive_out_position:
					drive_out_vector = game_level.drive_out_position.rotated(game_level.level_finish.global_rotation)
				agent_across.drive_out(drive_out_vector, drive_out_time)
				Rfs.sound_manager.play_sfx("finish_horn")
			else:
				Rfs.sound_manager.play_sfx("little_horn")


			# hud update
			for stat_key in [Pfs.STATS.LAPS_FINISHED, Pfs.STATS.BEST_LAP_TIME, Pfs.STATS.LEVEL_TIME, Pfs.STATS.GOALS_REACHED]:
				game_parent.hud.update_agent_level_stats(agent_across.driver_index, stat_key, agent_level_data[stat_key])

			_check_for_game_end()


func _on_body_exited_playing_field(body: Node) -> void:

	#	if body.is_in_group(Rfs.group_agents):
	if body.is_in_group(Rfs.group_players):
		_pull_agent_on_field(body)
	elif body.has_method("on_out_of_playing_field"):
		body.on_out_of_playing_field() # ta funkcija zakasni učinek


func _on_agent_activity_change(changed_agent: Node2D): # temp ... Vechile class
#	printt("acitvity", changed_agent.name, changed_agent.is_active)

	# preverja, če je še kakšen player aktiven ... za GO
	if changed_agent.is_active:
		pass
	else:
#		game_parent.game_tracker.players_in_game.erase(changed_agent)
#		game_parent.game_tracker.agents_in_game.erase(changed_agent)
#		game_parent.game_tracker.ais_in_game.erase(changed_agent)

		# pripnem končne podatke o agentu
		var agent_has_finished: bool = agents_finished.has(changed_agent)
		# če ni deaktiviran v finišu izgubi ranking
		if not agent_has_finished:
			game_parent.level_stats[changed_agent.driver_index][Pfs.STATS.LEVEL_RANK] = -1
		game_parent.finale_game_data[changed_agent.driver_index] = {
			"driver_profile": changed_agent.driver_profile,
			"driver_stats": changed_agent.driver_stats,
			"driver_level_stats": game_parent.level_stats[changed_agent.driver_index],
			}

		#		print("act off ----  ", game_parent.finale_game_data[changed_agent.driver_index]["driver_level_stats"][Pfs.STATS.LEVEL_RANK])

		if Sts.hide_view_on_player_deactivated and not Sts.one_screen_mode: # ne uporabljam, ker ne smem zbrisat original viewa
			# skrijem view
			var hide_view_time: float
			var removed_game_view: ViewportContainer = game_parent.game_views.find_key(changed_agent)
			# odstranim, če ni zadnji view
			if removed_game_view and game_parent.game_views.size() > 1:
				removed_game_view.queue_free()
				game_parent.game_views.erase(removed_game_view)
				# setam preostale
				game_parent._set_game_views(game_parent.game_views.size())
				# odstranim imitatorja ... more bit za setanje game_views
				game_parent.hud.agent_huds_holder.remove_view_imitator(game_parent.game_views)

		# preverim, če je bil zadnji plejer da končam igro ... za primer, če ni nobe
		if game_parent.game_stage == game_parent.GAME_STAGE.PLAYING:
			var still_playing: bool = false
			for player in game_parent.game_tracker.players_in_game:
#				if not is_instance_valid(player):
#					still_playing = false
#				elif player.is_active:
				if player.is_active:
					still_playing = true
			if not still_playing:
				game_parent.game_stage = game_parent.GAME_STAGE.END_FAIL
				# _on_change preverja, če je igra že končana (tole ne poveozi morebitnega uspeha
