extends Node


signal bolt_spawned (name, other)
signal game_state_changed (game_on, level_settings)

var game_on: bool

var bolts_in_game: Array # live data ... tekom igre so v ranked zaporedju (glede na distanco)
var bolts_finished: Array # bolti v cilju
var players_qualified: Array # obstaja za prenos med leveloma
var camera_leader: Node2D setget _change_camera_leader # trenutno vodilni igralec ... lahko tudi kakšen drug pogoj

# game
#var game_settings: Dictionary # set_game seta iz profilov
var activated_driver_ids: Array # naslednji leveli se tole adaptira, glede na to kdo je še v igri
var fast_start_window: bool = false # bolt ga čekira in reagira
var start_bolt_position_nodes: Array # dobi od tilemapa
var current_pull_positions: Array # že zasedene pozicije za preventanje nalaganja bolto druga na drugega

# level
var level_settings: Dictionary # set_level seta iz profilov
var current_level_index = 0
var available_pickable_positions: Array # za random spawn
var navigation_positions: Array # pozicije vseh navigation tiletov
var pickables_in_game: Array

onready var level_finished_ui: Control = $"../UI/LevelFinished"
onready var game_over_ui: Control = $"../UI/GameOver"
#onready var game_settings: Dictionary = Sts.get_level_game_settings(current_level_index) # set_game seta iz profilov

# shadows
#onready var game_shadows_direction: Vector2 = Sts.game_shadows_direction # Vector2(1, 1) # set_game seta iz profilov
onready var game_shadows_length_factor: float = Sts.game_shadows_length_factor # set_game seta iz profilov
onready var game_shadows_alpha: float = Sts.game_shadows_alpha # set_game seta iz profilov
onready var game_shadows_color: Color = Sts.game_shadows_color # set_game seta iz profilov
onready var game_shadows_rotation_deg: float = Sts.game_shadows_rotation_deg # set_game seta iz profilov

# neu
var games
onready var hud: Control = $"../UI/Hud"
onready var pause_game: Control = $"../UI/PauseGame"
onready var level_finished: Control = $"../UI/LevelFinished"
onready var game_over: Control = $"../UI/GameOver"
onready var game_view: ViewportContainer = $"../GameViewGrid/GameView"
var level_stats: Dictionary = {}
var goals_to_reach: Array = []


func _input(event: InputEvent) -> void:


	if Input.is_action_just_pressed("no1"):
		get_tree().set_group(Rfs.group_shadows, "imitate_3d", true)
	elif Input.is_action_just_pressed("no2"):
		get_tree().set_group(Rfs.group_shadows, "imitate_3d", false)
	elif Input.is_action_just_pressed("no3"):
		_animate_day_night()


func _ready() -> void:
#	printt("GM")

	Rfs.game_manager = self
	Rfs.current_level = null # da deluje reštart

	# intro:
	get_parent().modulate = Color.black

	call_deferred("_set_game")


func _process(delta: float) -> void:

	bolts_in_game = get_tree().get_nodes_in_group(Rfs.group_bolts)
	pickables_in_game = get_tree().get_nodes_in_group(Rfs.group_pickables)

	_update_ranking()

	# camera leader
	for bolt in bolts_in_game:
		if bolt.is_in_group(Rfs.group_players) and bolt.is_active:
			self.camera_leader = bolt
			break
		self.camera_leader = null


func _change_camera_leader(new_camera_leader: Node2D):

	if new_camera_leader == camera_leader:
		pass
	elif new_camera_leader == null:
		pass
	else:
		camera_leader = new_camera_leader
		Rfs.game_camera.follow_target = camera_leader


func _set_game():

#	game_settings = Sts.get_level_game_settings(current_level_index)
	_spawn_level()

	hud.set_hud(level_settings, Rfs.current_level.level_type, Rfs.current_level.LEVEL_TYPE) # kliče GM
	Rfs.game_camera.follow_target = Rfs.current_level.start_camera_position_node

	# playing field
	var playing_field_node: Node2D = Rfs.game_camera.playing_field
	playing_field_node.connect( "body_exited_playing_field", self, "_on_body_exited_playing_field")
	if Sts.all_bolts_on_screen_mode:
		match Rfs.current_level.level_type:
			Rfs.current_level.LEVEL_TYPE.BATTLE:
				playing_field_node.enable_playing_field(false)
			Rfs.current_level.LEVEL_TYPE.CHASE:
				playing_field_node.enable_playing_field(true, true)
			_:
				playing_field_node.enable_playing_field(true)
	else:
		playing_field_node.enable_playing_field(false)

	# drivers
	activated_driver_ids.clear()
	if current_level_index == 0:
		# če je prvi level so aktivirani dodani v meniju
		activated_driver_ids = Sts.players_on_game_start
	else: # če ni prvi level dodam kvalificirane driver_id
		if players_qualified.empty():
			print("Error! Ni qvalificiranih boltov, torej igre nebi smelo biti!")
		for bolt in players_qualified:
			activated_driver_ids.append(bolt.driver_id)
	players_qualified.clear()
	#	printt("DRIVER_ID", activated_driver_ids)

	# AI
	if Sts.enemies_mode: # začasno vezano na Set. filet
		# za vsako prazno pozicijo dodam AI driver_id
		var empty_positions_count = start_bolt_position_nodes.size() - activated_driver_ids.size()
		empty_positions_count = 1 # debug ... omejitev  ai spawna na 1
		for empty_position in empty_positions_count:
			# dobim štartni id bolta in umestim ai data
			var new_driver_index: int = activated_driver_ids.size()
			var new_driver_id: int = Pfs.driver_profiles.keys()[new_driver_index]
			Pfs.driver_profiles[new_driver_id]["controller_type"] = Pfs.ai_profile[Pfs.AI_TYPE.DEFAULT]["controller_type"]
			activated_driver_ids.append(new_driver_id) # da prepoznam v spawn funkciji .... trik pač

	# spawn bolts ... po vrsti aktivacije
	var spawned_position_index = 0
	for driver_id in activated_driver_ids: # so v ranking zaporedju
		_spawn_bolt(driver_id, spawned_position_index) # scena, pozicija, profile id (barva, ...)
		spawned_position_index += 1
	Rfs.ultimate_popup.hide()
	_game_intro()


func _game_intro():

	# pokažem sceno
	var fade_time: float = 1
	var setup_delay: float = 0 # delay, da se kamera naštima
	var fade_tween = get_tree().create_tween()
	fade_tween.tween_property(get_parent(), "modulate", Color.white, fade_time).from(Color.black).set_delay(setup_delay)
	yield(fade_tween, "finished")

	# bolts drive-in
	var drive_in_time: float = 2
	for bolt in bolts_in_game:
		var drive_in_vector: Vector2 = Rfs.current_level.drive_in_position.rotated(Rfs.current_level.level_start.global_rotation)
		bolt.drive_in(drive_in_time, drive_in_vector)
	yield(get_tree().create_timer(drive_in_time),"timeout")

	_start_game()


func _start_game():

	# start countdown
	if Sts.start_countdown:
		Rfs.current_level.start_lights.start_countdown() # če je skrit, pošlje signal takoj
		yield(Rfs.current_level.start_lights, "countdown_finished")

	# start
#	for bolt in bolts_in_game:
#		if bolt.is_in_group(Rfs.group_ai):
#			match Rfs.current_level.level_type:
#				Rfs.current_level.LEVEL_TYPE.RACE_TRACK:
#					bolt.bolt_controller.set_ai_target(bolt.bolt_tracker)
#				_:
#					pass
	Rfs.sound_manager.play_music()
	hud.on_game_start()

	# random pickables spawn
	if Rfs.current_level.level_type == Rfs.current_level.LEVEL_TYPE.BATTLE:
		_spawn_random_pickables()

	game_on = true
	emit_signal("game_state_changed", game_on, level_settings) #  poslušajo drajverji,  hud3 "signal dobijo"

	# fast start
	fast_start_window = true
	yield(get_tree().create_timer(Sts.fast_start_window_time), "timeout")
	fast_start_window = false


func end_level():

	Rfs.game_camera.follow_target = Rfs.current_level.finish_camera_position_node

	if game_on:

		game_on = false
		emit_signal("game_state_changed", game_on, level_settings) #  poslušajo drajverji,  hud3 "signal dobijo"

		hud.on_level_finished()

		yield(get_tree().create_timer(Sts.get_it_time), "timeout")

		# preverim, če je kakšen človek kvalificiran
		if bolts_finished.empty():
			pass
		else:
			# SUCCESS če je vsaj en plejer bil čez ciljno črto
			for bolt in bolts_finished:
				if bolt.is_in_group(Rfs.group_players):
					players_qualified.append(bolt)
			# FAIL, če ni nobenega plejerja v cilju

		var level_goal_reached: bool
		if players_qualified.empty():
			level_goal_reached = false

		if level_goal_reached:
			# ranking ob koncu levela
			var bolts_ranked_on_level_finished: Array = []
			# najprej dodam bolts finished, ki je že pravilno rangiran
			bolts_ranked_on_level_finished.append_array(bolts_finished)
			# potem dodam še not finished ... po vrsti gre čez array in upošteva pogoje > vrstni red je po prevoženi distanci
			for bolt in bolts_in_game:
				if not bolts_finished.has(bolt):
					bolts_ranked_on_level_finished.append(bolt)
					if bolt.is_in_group(Rfs.group_ai):
						# AI se vedno uvrsti in dobi nekaj časa glede na zadnjega v cilju
						var worst_time_among_finished: float = bolts_finished[bolts_finished.size() - 1].driver_stats[Pfs.STATS.LEVEL_TIME]
						bolt.driver_stats[Pfs.STATS.LEVEL_TIME] = worst_time_among_finished + worst_time_among_finished / 5
						bolts_finished.append(bolt)
					elif bolt.is_in_group(Rfs.group_players):
						# plejer se na Easy_mode uvrsti brez časa
						if Sts.easy_mode:
							bolts_finished.append(bolt)

			# je level zadnji?
			if current_level_index < (Sts.current_game_levels.size() - 1):
				level_finished_ui.open_level_finished(bolts_finished, bolts_in_game)
			else:
				game_over_ui.open_gameover(bolts_finished, bolts_in_game)
				print("bolts_finished", bolts_finished)

		else:
			print("bolts_finished else ", bolts_finished)
			game_over_ui.open_gameover(bolts_finished, bolts_in_game)
			#		var fade_time = 1
			#		var fade_in_tween = get_tree().create_tween()
			#		fade_in_tween.tween_property(get_parent(), "modulate", Color.black, fade_time)
			#		yield(fade_in_tween, "finished")


		for bolt in bolts_in_game: # zazih
			# driver se deaktivira, ko mu zmanjka bencina (in ko gre čez cilj)
			# AI se deaktivira, ko gre čez cilj
			if bolt.is_active: # zazih
				bolt.is_active = false
			bolt.set_physics_process(false)

		# music stop
		Rfs.sound_manager.stop_music()
		# sfx mute
		var bus_index: int = AudioServer.get_bus_index("GameSfx")
		AudioServer.set_bus_mute(bus_index, true)

		# best lap stats reset
		# looping sounds stop
		# navigacija AI
		# kvefri elementov, ki so v areni


func set_next_level():

	current_level_index += 1

	bolts_finished = [] # resetiram šele tukaj, ker ga rabim tudi v GO

	# unmute sfx
	if not Rfs.sound_manager.sfx_set_to_mute:
		var bus_index: int = AudioServer.get_bus_index("GameSfx")
		AudioServer.set_bus_mute(bus_index, false)

	# zbrišem vse otroke v NCP (bolti, orožja, efekti, ...)
	var all_children: Array = Rfs.node_creation_parent.get_children()
	for child in all_children:
		child.queue_free()

	# reset level values
	self.camera_leader = null # trenutno vodilni igralec (rabim za camera target in pull target)

	call_deferred("_set_game")


# TRACKING ---------------------------------------------------------------------------------------------


func _update_ranking():

	match Rfs.current_level.level_type:
		Rfs.current_level.LEVEL_TYPE.BATTLE, Rfs.current_level.LEVEL_TYPE.CHASE, Rfs.current_level.LEVEL_TYPE.RACE_GOAL:
			bolts_in_game.sort_custom(self, "_sort_trackers_by_points")
		_:
			# najprej sortirami po poziciji trackerja,
			# potem naredim array boltov v istem zaporedju
			# potem razporedim array boltov glede na kroge
			var bolts_ranked: Array = []
			var all_bolt_trackers: Array = Rfs.current_level.level_track.get_children()
			all_bolt_trackers.sort_custom(self, "_sort_trackers_by_offset")
			for bolt_tracker in all_bolt_trackers:
				bolts_ranked.append(bolt_tracker.tracking_target)
			bolts_ranked.sort_custom(self, "_sort_bolts_by_laps")
			bolts_in_game = bolts_ranked

	for bolt in bolts_in_game:
		var current_bolt_rank: int = bolts_in_game.find(bolt) + 1
		if not current_bolt_rank == level_stats[bolt.driver_id][Pfs.STATS.LEVEL_RANK]:
			level_stats[bolt.driver_id][Pfs.STATS.LEVEL_RANK] = current_bolt_rank
			hud.update_bolt_level_stats(bolt.driver_id, Pfs.STATS.LEVEL_RANK, current_bolt_rank) # OPT prepogosto


func _on_bolt_reached_goal(level_goal: Node, goal_reaching_bolt: Bolt): # level poveže

	var curr_bolt_level_data: Dictionary = level_stats[goal_reaching_bolt.driver_id]

	var reach_in_sequence: bool = false
	if reach_in_sequence:
		if goal_reaching_bolt.goals_to_reach[0] == level_goal:
			curr_bolt_level_data[Pfs.STATS.GOALS_REACHED].append(level_goal)
			if "goals_to_reach" in goal_reaching_bolt.bolt_controller:
				goal_reaching_bolt.bolt_controller.goals_to_reach.pop_front()
	else:
		curr_bolt_level_data[Pfs.STATS.GOALS_REACHED].append(level_goal)
		if "goals_to_reach" in goal_reaching_bolt.bolt_controller:
			goal_reaching_bolt.bolt_controller.goals_to_reach.erase(level_goal)


func _bolt_across_finish_line(bolt_across: Bolt): # sproži finish line

	if not game_on:
		return

	# najprej preverjam, če je izpolnil cilje za finish line
	var curr_bolt_level_data: Dictionary = level_stats[bolt_across.driver_id]
	#	printt("finished", curr_bolt_level_data)

	var goals_reached: Array = curr_bolt_level_data[Pfs.STATS.GOALS_REACHED]
	if goals_reached.size() >= goals_to_reach.size():

		var prev_level_time: float = curr_bolt_level_data[Pfs.STATS.LEVEL_TIME]
		var curr_level_time: float = hud.game_timer.game_time_hunds
		var curr_lap_time: float = curr_level_time - prev_level_time

		curr_bolt_level_data[Pfs.STATS.LAPS_FINISHED].append(curr_lap_time)
		curr_bolt_level_data[Pfs.STATS.LEVEL_TIME] = curr_level_time

		# best lap
		if curr_lap_time < curr_bolt_level_data[Pfs.STATS.BEST_LAP_TIME]:
			curr_bolt_level_data[Pfs.STATS.BEST_LAP_TIME] = curr_lap_time
			hud.spawn_bolt_floating_tag(bolt_across, curr_lap_time, true)
		else:
			# čas prvega kroga je pseudo best lap ... ne tretiram ga kot best lap
			if curr_bolt_level_data[Pfs.STATS.BEST_LAP_TIME] == 0:
				curr_bolt_level_data[Pfs.STATS.BEST_LAP_TIME] = curr_lap_time
			hud.spawn_bolt_floating_tag(bolt_across, curr_lap_time)

		# last lap
		var laps_count: int = curr_bolt_level_data[Pfs.STATS.LAPS_FINISHED].size()
		if laps_count >= level_settings["lap_limit"]:
			bolts_finished.append(bolt_across)
			var drive_out_time: float = 1
			var drive_out_vector: Vector2 = Rfs.current_level.drive_out_position.rotated(Rfs.current_level.level_finish.global_rotation)
			bolt_across.drive_out(drive_out_time, drive_out_vector)
			Rfs.sound_manager.play_sfx("finish_horn")
		else:
			Rfs.sound_manager.play_sfx("finish_horn")

		for stat_key in [Pfs.STATS.LAPS_FINISHED, Pfs.STATS.BEST_LAP_TIME, Pfs.STATS.LEVEL_TIME, Pfs.STATS.GOALS_REACHED]:
			hud.update_bolt_level_stats(bolt_across.driver_id, stat_key, curr_bolt_level_data[stat_key])


func _pull_bolt_on_field(bolt_to_pull: Bolt):

	if game_on and Sts.all_bolts_on_screen_mode:

		if bolt_to_pull.is_active:

			var bolt_pull_position: Vector2 = _get_bolt_pull_position(bolt_to_pull)
			bolt_to_pull.call_deferred("pull_bolt_on_screen", bolt_pull_position)

			# če preskoči ciljno črto jo dodaj, če jo je leader prevozil
			var pulled_bolt_level_stats: Dictionary = level_stats[bolt_to_pull.driver_id]
			var leader_bolt_level_stats: Dictionary = level_stats[camera_leader.driver_id]

			# poenotim level goals/laps stats ... če ni pulan točno preko cilja, pa bi moral bit
			if pulled_bolt_level_stats[Pfs.STATS.LAPS_FINISHED].size() < leader_bolt_level_stats[Pfs.STATS.LAPS_FINISHED].size():
				pulled_bolt_level_stats[Pfs.STATS.LAPS_FINISHED] = leader_bolt_level_stats[Pfs.STATS.LAPS_FINISHED]
			# mogoče tega spodej nebi mel ... bomo videlo po testu
			if pulled_bolt_level_stats[Pfs.STATS.GOALS_REACHED].size() < leader_bolt_level_stats[Pfs.STATS.GOALS_REACHED].size():
				pulled_bolt_level_stats[Pfs.STATS.GOALS_REACHED] = leader_bolt_level_stats[Pfs.STATS.GOALS_REACHED]


func _get_bolt_pull_position(bolt_to_pull: Bolt):
	# na koncu izbrana pull pozicija:
	# - je na območju navigacije
	# - upošteva razdaljo do vodilnega
	# - se ne pokriva z drugim plejerjem
	#	printt ("current_pull_positions",current_pull_positions.size())
	if game_on:

		# pull pozicija brez omejitev
		var pull_position_distance_from_leader: float = 200 # pull razdalja od vodilnega plejerja
		var pull_position_distance_from_leader_correction: float = bolt_to_pull.chassis.get_node("BoltScale").rect_size.x * 2 # 18 ... 20 # pull razdalja od vodilnega plejerja glede na index med trenutno pulanimi

		var vector_to_leading_player: Vector2 = camera_leader.global_position - bolt_to_pull.global_position
		var vector_to_pull_position: Vector2 = vector_to_leading_player - vector_to_leading_player.normalized() * pull_position_distance_from_leader
		var bolt_pull_position: Vector2 = bolt_to_pull.global_position + vector_to_pull_position

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
				if cell_position.distance_to(bolt_pull_position) < navigation_position_as_pull_position.distance_to(bolt_pull_position):
					# pozicija je dovolj stran od vodilnega
					if cell_position.distance_to(camera_leader.global_position) > pull_position_distance_from_leader:
						# če je pozicija zasedena
						if current_pull_positions.has(cell_position):
							var pull_pos_index: int = current_pull_positions.find(cell_position)
							var corrected_pull_position = pull_position_distance_from_leader + pull_pos_index * pull_position_distance_from_leader_correction
							if cell_position.distance_to(camera_leader.global_position) > corrected_pull_position:
								navigation_position_as_pull_position = cell_position
						else: # če je poza zasedena dobim njen in dex med zasedenimi dodam korekcijo na zahtevani razdalji od vodilnega
							navigation_position_as_pull_position = cell_position

		current_pull_positions.append(navigation_position_as_pull_position) # OBS trenutno ne rabim

		return navigation_position_as_pull_position


# SPAWNING ---------------------------------------------------------------------------------------------


func _spawn_level():

	# level name (iz seznama levelov v igri)
	var level_to_load_id: int = Sts.current_game_levels[current_level_index]
	var level_spawn_parent: Node = game_view.get_node("Viewport") # VP node
#	var level_spawn_parent: Node = Rfs.game_camera.get_parent()

	# level settings
	level_settings = Pfs.level_profiles[level_to_load_id]
	var level_to_load_path: String = level_settings["level_path"]

	var level_z_index: int # z index v node drevesu
	if not Rfs.current_level == null: # če level že obstaja, ga najprej moram zbrisat
		level_z_index = Rfs.current_level.z_index
		Rfs.current_level.set_physics_process(false)
		Rfs.current_level.free()

	# spawn level
	var NewLevel: PackedScene = ResourceLoader.load(level_to_load_path)
	var new_level = NewLevel.instance()
	new_level.z_index = level_z_index
	new_level.connect( "level_is_set", self, "_on_level_is_set") # nujno pred add child, ker ga level sproži že na ready
	level_spawn_parent.add_child(new_level)
	level_spawn_parent.move_child(new_level, 0)

	level_settings["level_type"] = Rfs.current_level.level_type

	# connect elements: start, finish, goals
	for node_path in Rfs.current_level.level_goals_paths:
		Rfs.current_level.get_node(node_path).connect("goal_reached", self, "_on_bolt_reached_goal")
		goals_to_reach.append(Rfs.current_level.get_node(node_path))
	if Rfs.current_level.level_finish_path:
		Rfs.current_level.get_node(Rfs.current_level.level_finish_path).connect("finish_reached", self, "_bolt_across_finish_line")

	#	print ("spawned level_stats", level_stats)


func _spawn_bolt(bolt_driver_id: int, spawned_position_index: int):

	var bolt_type: int = Pfs.driver_profiles[bolt_driver_id]["bolt_type"]
	# debug ... ai spawn
	var scene_name: String = "bolt_scene"
#	if Pfs.driver_profiles[bolt_driver_id]["controller_type"] == Pfs.CONTROLLER_TYPE.AI:
#		scene_name = "bolt_scene_ai"
	var NewBoltInstance: PackedScene = Pfs.bolt_profiles[bolt_type][scene_name]

	var new_bolt = NewBoltInstance.instance()
	new_bolt.driver_id = bolt_driver_id
	new_bolt.modulate.a = 0 # za intro
	new_bolt.rotation_degrees = Rfs.current_level.level_start.rotation_degrees - 90 # ob rotaciji 0 je default je obrnjen navzgor
	new_bolt.global_position = start_bolt_position_nodes[spawned_position_index].global_position

	# setam mu profile ... iz njih podatke povleče sam na readi
	new_bolt.driver_profile = Pfs.driver_profiles[bolt_driver_id].duplicate()
	new_bolt.driver_stats = Pfs.start_bolt_stats.duplicate()
	new_bolt.bolt_profile = Pfs.bolt_profiles[bolt_type].duplicate()
	Rfs.node_creation_parent.add_child(new_bolt)

	# AI
	if Pfs.driver_profiles[bolt_driver_id]["controller_type"] == Pfs.CONTROLLER_TYPE.AI:
		new_bolt.bolt_controller.level_navigation_positions = Rfs.current_level.level_navigation.level_navigation_points # _temp zakaj tukaj
		self.connect("game_state_changed", new_bolt.bolt_controller, "_on_game_state_change") # _temp _on_game_state_change signal na ai

	# race trackers
	match Rfs.current_level.level_type:
		Rfs.current_level.LEVEL_TYPE.RACE_TRACK:
			new_bolt.bolt_tracker = Rfs.current_level.level_track.set_new_bolt_tracker(new_bolt)

	# signali
	new_bolt.connect("bolt_activity_changed", self, "_on_bolt_activity_change")
	new_bolt.connect("bolt_stat_changed", hud, "_on_bolt_stat_changed")

	# bolts level stats
	level_stats[bolt_driver_id] = Pfs.start_bolt_level_stats.duplicate()
	level_stats[bolt_driver_id][Pfs.STATS.LAPS_FINISHED] = [] # prepišem array v slovarju, da je tudi ta unique
	level_stats[bolt_driver_id][Pfs.STATS.GOALS_REACHED] = []

	emit_signal("bolt_spawned", new_bolt, level_stats[bolt_driver_id]) # zaenkrat samo HUD, da prižge in napolne statbox


func _spawn_random_pickables():

	if available_pickable_positions.empty():
		return

	if pickables_in_game.size() <= Sts.pickables_count_limit - 1:

		# žrebanje tipa
		var random_pickable_key = Pfs.pickable_profiles.keys().pick_random()
		var random_cell_position: Vector2 = navigation_positions.pick_random()
		Rfs.current_level.spawn_pickable(random_cell_position, "random_pickable_key", random_pickable_key)

		# odstranim celico iz arraya tistih na voljo
		var random_cell_position_index: int = available_pickable_positions.find(random_cell_position)
		available_pickable_positions.remove(random_cell_position_index)

	# random timer reštart
	var random_pickable_spawn_time: int = [1, 2, 3].pick_random()
	yield(get_tree().create_timer(random_pickable_spawn_time), "timeout") # OPT ... uvedi node timer

	_spawn_random_pickables()


# UTILITI ---------------------------------------------------------------------------------------------


func _animate_day_night():

	var day_length: float = 10
	var day_start_direction: Vector2 = Vector2.LEFT

	var day_night_tween = get_tree().create_tween()
	for shadow in get_tree().get_nodes_in_group(Rfs.group_shadows):
		if shadow is Polygon2D:
			day_night_tween.parallel().tween_property(shadow, "shadow_rotation_deg", 0, day_length).from(-180).set_ease(Tween.EASE_IN_OUT)


func _sort_bolts_by_laps(bolt_1, bolt_2): # descending ... večji index je boljši
	# For two elements a and b, if the given method returns true, element b will be after element a in the array.

	var bolt_1_lap_count = level_stats[bolt_1.bolt_type][Pfs.STATS.LAPS_FINISHED].size()
	var bolt_2_lap_count = level_stats[bolt_2.bolt_type][Pfs.STATS.LAPS_FINISHED].size()
	if bolt_1_lap_count > bolt_2_lap_count:
	    return true
	return false


func _sort_trackers_by_offset(bolt_tracker_1, bolt_tracker_2):# descending ... večji index je boljši
	# For two elements a and b, if the given method returns true, element b will be after element a in the array.

	if bolt_tracker_1.offset > bolt_tracker_2.offset:
	    return true
	return false


func _sort_trackers_by_points(bolt_1, bolt_2):# descending ... večji index je boljši
	# For two elements a and b, if the given method returns true, element b will be after element a in the array.

	var bolt_1_points = bolt_1.driver_stats[Pfs.STATS.POINTS]
	var bolt_2_points = bolt_2.driver_stats[Pfs.STATS.POINTS]
	if bolt_1_points > bolt_2_points:
	    return true
	return false


func _sort_trackers_by_speed(bolt_1, bolt_2): # temp ...  ne uporabljam# descn ... večji index je boljši

	if bolt_1.bolt_velocity.length() > bolt_2.bolt_velocity.length():
	    return true
	return false


# SIGNALI ----------------------------------------------------------------------------------------------------


func _on_level_is_set(tilemap_navigation_cells_positions: Array):

	# navigacija za AI
	navigation_positions = tilemap_navigation_cells_positions

	# random pickable pozicije
	available_pickable_positions = tilemap_navigation_cells_positions.duplicate()

	# spawn poz
	start_bolt_position_nodes = Rfs.current_level.start_positions_node.get_children()

	# kamera
	Rfs.game_camera.position = Rfs.current_level.start_camera_position_node.global_position
	Rfs.game_camera.set_camera_limits() # debug


func _on_body_exited_playing_field(body: Node) -> void:

	#	if body.is_in_group(Rfs.group_bolts):
	if body.is_in_group(Rfs.group_players):
		_pull_bolt_on_field(body)
	elif body is Bullet:
		body.on_out_of_playing_field() # ta funkcija zakasni učinek


func _on_bolt_activity_change(changed_bolt: Bolt):

	# preverja, če je še kakšen player aktiven ... za GO
	if changed_bolt.is_active == false:
		for bolt in bolts_in_game:
			if bolt.is_active and bolt.is_in_group(Rfs.group_players):
				return
		end_level()
