extends Node


signal bolt_spawned (name, other)
signal message_to_drivers (enums, RANKING, RACE_START, RACE_FINISHED) # mogoče signal za vsako posebej
signal game_state_changed (game_on)

var game_on: bool
enum GAME_STATE {LOADING, ON, PAUSED, OFF}
var game_state: int = GAME_STATE.LOADING

var bolts_in_game: Array # tekom igre so v ranked zaporedju (glede na distanco)
var bolts_finished: Array # bolti v cilju
var human_bolts_qualified: Array # obstaja za prenos med leveloma
var bolts_checked: Array
var camera_leader: Node2D # trenutno vodilni igralec (rabim za camera target in pull target)

# game
#var game_settings: Dictionary # set_game seta iz profilov
var activated_player_ids: Array # naslednji leveli se tole adaptira, glede na to kdo je še v igri
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
onready var game_settings: Dictionary = Sts.get_level_game_settings(current_level_index) # set_game seta iz profilov
# shadows
onready var game_shadows_direction: Vector2 = game_settings["game_shadows_direction"] # Vector2(1, 1) # set_game seta iz profilov
onready var game_shadows_length_factor: float = game_settings["game_shadows_length_factor"] # set_game seta iz profilov
onready var game_shadows_alpha: float = game_settings["game_shadows_alpha"] # set_game seta iz profilov
onready var game_shadows_color: Color = game_settings["game_shadows_color"] # set_game seta iz profilov
onready var game_shadows_rotation_deg: float = game_settings["game_shadows_rotation_deg"] # set_game seta iz profilov


func _input(event: InputEvent) -> void:


	#	if Input.is_action_just_pressed("m"):
	#		var bus_index: int = AudioServer.get_bus_index("GameMusic")
	#		var bus_is_mute: bool = AudioServer.is_bus_mute(bus_index)
	#		AudioServer.set_bus_mute(bus_index, not bus_is_mute)

	if Input.is_action_just_pressed("no1"):
		get_tree().set_group(Rfs.group_shadows, "imitate_3d", true)
	elif Input.is_action_just_pressed("no2"):
		get_tree().set_group(Rfs.group_shadows, "imitate_3d", false)
	elif Input.is_action_just_pressed("no3"):
		_animate_day_night()

#	if Input.is_action_just_pressed("no1"): # idle
#		Rfs.current_3Dworld.change_follow_target(bolts_in_game[0])
	#	if Input.is_action_just_pressed("no2"): # race
	#		for bolt in bolts_in_game:
	#			if bolt.is_in_group(Rfs.group_ai):
	#				bolt.get_node("AIController").set_ai_target(bolt.bolt_tracker)
	#	if Input.is_action_just_pressed("no3"):
	#		for bolt in bolts_in_game: # search
	#			if bolt.is_in_group(Rfs.group_ai):
	#				bolt.get_node("AIController").set_ai_target(Rfs.current_level.tilemap_edge)
	#	if Input.is_action_just_pressed("no4"): # follow leader
	#		for bolt in bolts_in_game:
	#			if bolt.is_in_group(Rfs.group_ai):
	#				bolt.get_node("AIController").set_ai_target(camera_leader)


#	if Input.is_action_just_pressed("no5"):
#		for bolt in bolts_in_game:
#			if bolt.is_in_group(Rfs.group_humans):
#				bolt.lose_life()
#				#				bolt.player_stats["gas_count"] = 0
#				#			if bolt.is_in_group(Rfs.group_ai):
#				#				bolt.player_stats["gas_count"] = 0
	pass


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

	#	if game_on:
	_update_ranking()

	var active_human_bolts: Array = []
	for bolt in bolts_in_game:
		if bolt.is_in_group(Rfs.group_humans) and bolt.is_active:
			active_human_bolts.append(bolt)
	if active_human_bolts.empty():
		camera_leader = null
	else:
		camera_leader = active_human_bolts[0]

	if not Rfs.current_camera.follow_target == camera_leader: # da kamera ne reagira, če je že setan isti plejer
		Rfs.current_camera.follow_target = camera_leader


func _set_game():

	game_settings = Sts.get_level_game_settings(current_level_index)

	_spawn_level()

	Rfs.hud.set_hud()
	self.connect("game_state_changed", Rfs.hud, "_on_game_state_change") # statistika med boltom in hudom

	# playing field
	Rfs.game_arena.playing_field.connect( "body_exited_playing_field", self, "_on_body_exited_playing_field")
	match Rfs.current_level.level_type:
		Rfs.current_level.LEVEL_TYPE.BATTLE:
			Rfs.game_arena.playing_field.screen_edge_collision.set_deferred("disabled", false)
			Rfs.game_arena.playing_field.screen_area.set_deferred("monitoring", false)
		Rfs.current_level.LEVEL_TYPE.CHASE:
			Rfs.game_arena.playing_field.screen_edge_collision.set_deferred("disabled", true)
			Rfs.game_arena.playing_field.screen_area.set_deferred("monitoring", false)
		_:
			Rfs.game_arena.playing_field.screen_area.set_deferred("monitoring", true)
			Rfs.game_arena.playing_field.screen_edge_collision.set_deferred("disabled", true)

	Rfs.current_camera.follow_target = Rfs.current_level.start_camera_position_node

	# players
	activated_player_ids = []
	# če je prvi level so aktivirani dodani v meniju
	if current_level_index == 0:




		# debug ... kadar ne štartam igre iz home menija
		if Sts.players_on_game_start.empty():
#			activated_player_ids = [Pfs.PLAYER.P1]
#			activated_player_ids = [Pfs.PLAYER.P1, Pfs.PLAYER.P2]
#			activated_player_ids = [Pfs.PLAYER.P1, Pfs.PLAYER.P2, Pfs.PLAYER.P3, Pfs.PLAYER.P4]
			game_settings["enemies_mode"] = true # debug



		else:
			activated_player_ids = Sts.players_on_game_start

	# če ni prvi level dodam kvalificirane player_id
	elif current_level_index > 0:
		if human_bolts_qualified.empty():
			print("Error! Ni qvalificiranih boltov, torej igre nebi smelo biti!")
		else:
			for bolt in human_bolts_qualified:
				activated_player_ids.append(bolt.player_id)
	human_bolts_qualified = []

	# get enemies

	if game_settings["enemies_mode"]: # začasno vezano na Set. filet
		# za vsako prazno pozicijo dodam AI player_id
		var empty_positions_count = start_bolt_position_nodes.size() - activated_player_ids.size()
		empty_positions_count = 1 # debug
		for empty_position in empty_positions_count:
			# dobim štartni id bolta in umestim ai data
			var new_player_index: int = activated_player_ids.size()
			var new_player_id: int = Pfs.player_profiles.keys()[new_player_index]
			Pfs.player_profiles[new_player_id]["controller_type"] = Pfs.ai_profile["controller_type"]
			activated_player_ids.append(new_player_id) # da prepoznam v spawn funkciji .... trik pač
	#	printt("PLAYERS", activated_player_ids)

	# adaptacija količine orožij
	Pfs.default_player_stats["bullet_count"] = 0
	Pfs.default_player_stats["misile_count"] = 0
	Pfs.default_player_stats["mina_count"] = 0
	game_settings["full_equip_mode"] = true # debug
	if game_settings["full_equip_mode"]:
		Pfs.default_player_stats["bullet_count"] = 100
		Pfs.default_player_stats["misile_count"] = 100
		Pfs.default_player_stats["mina_count"] = 100

	# spawn bolts on positions (po vrsti aktivacije)
	var spawned_position_index = 0
	for player_id in activated_player_ids: # so v ranking zaporedju
		_spawn_bolt(player_id, spawned_position_index) # scena, pozicija, profile id (barva, ...)
		spawned_position_index += 1

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
		bolt.drive_in(drive_in_time)
	yield(get_tree().create_timer(drive_in_time),"timeout")

	_start_game()


func _start_game():

	# start countdown
	if Rfs.game_manager.game_settings["start_countdown"]:
		Rfs.current_level.start_lights.start_countdown() # če je skrit, pošlje signal takoj
		yield(Rfs.current_level.start_lights, "countdown_finished")

	# start
#	for bolt in bolts_in_game:
#		if bolt.is_in_group(Rfs.group_ai):
#			match Rfs.current_level.level_type:
#				Rfs.current_level.LEVEL_TYPE.RACE, Rfs.current_level.LEVEL_TYPE.RACE_LAPS:
#					bolt.bolt_controller.set_ai_target(bolt.bolt_tracker)
#				_:
#					pass
	Rfs.sound_manager.play_music()
	Rfs.hud.on_game_start()

	# random pickables spawn
	if Rfs.current_level.level_type == Rfs.current_level.LEVEL_TYPE.BATTLE:
		_start_spawning_pickables()

	game_on = true
	game_state = GAME_STATE.ON
	emit_signal("message_to_drivers", "game_on", game_on) #  poslušajo drajverji,  hud3 "signal dobijo"
	emit_signal("game_state_changed", game_on, level_settings) #  poslušajo drajverji,  hud3 "signal dobijo"

	# fast start
	fast_start_window = true
	yield(get_tree().create_timer(game_settings["fast_start_window_time"]), "timeout")
	fast_start_window = false


func level_finished():

	Rfs.current_camera.follow_target = Rfs.current_level.finish_camera_position_node

	if game_state == GAME_STATE.ON:

		game_state = GAME_STATE.OFF
	#	if game_on == false: # preprečim double gameover
	#		return
		game_on = false
		emit_signal("message_to_drivers", "game_on", game_on) #  poslušajo drajverji,  hud3 "signal dobijo"
		emit_signal("game_state_changed", game_on, level_settings) #  poslušajo drajverji,  hud3 "signal dobijo"

		Rfs.hud.on_level_finished()

		yield(get_tree().create_timer(Sts.get_it_time), "timeout")

		# preverim, če je kakšen človek kvalificiran
		if bolts_finished.empty():
			pass
		else:
			# SUCCESS če je vsaj en plejer bil čez ciljno črto
			for bolt in bolts_finished:
				if bolt.is_in_group(Rfs.group_humans):
					human_bolts_qualified.append(bolt)
			# FAIL, če ni nobenega plejerja v cilju

		var level_goal_reached: bool
		if human_bolts_qualified.empty():
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
						var worst_time_among_finished: float = bolts_finished[bolts_finished.size() - 1].player_stats["level_time"]
						bolt.player_stats["level_time"] = worst_time_among_finished + worst_time_among_finished / 5
						bolts_finished.append(bolt)
					elif bolt.is_in_group(Rfs.group_humans):
						# plejer se na Easy_mode uvrsti brez časa
						if game_settings["easy_mode"]:
							bolts_finished.append(bolt)



			# je level zadnji?
			if current_level_index < (Sts.current_game_levels.size() - 1):
				level_finished_ui.open_level_finished(bolts_finished, bolts_in_game)
			else:
				game_over_ui.open_gameover(bolts_finished, bolts_in_game)

		else:
			game_over_ui.open_gameover(bolts_finished, bolts_in_game)
			#		var fade_time = 1
			#		var fade_in_tween = get_tree().create_tween()
			#		fade_in_tween.tween_property(get_parent(), "modulate", Color.black, fade_time)
			#		yield(fade_in_tween, "finished")


		for bolt in bolts_in_game: # zazih
			# player se deaktivira, ko mu zmanjka bencina (in ko gre čez cilj)
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
	camera_leader = null # trenutno vodilni igralec (rabim za camera target in pull target)

	call_deferred("_set_game")


func _animate_day_night():

	var day_length: float = 10
	var day_start_direction: Vector2 = Vector2.LEFT

	var day_night_tween = get_tree().create_tween()
	for shadow in get_tree().get_nodes_in_group(Rfs.group_shadows):
		if shadow is Polygon2D:
			day_night_tween.parallel().tween_property(shadow, "shadow_rotation_deg", 0, day_length).from(-180).set_ease(Tween.EASE_IN_OUT)


# RACING ---------------------------------------------------------------------------------------------


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
		bolt.update_bolt_rank(current_bolt_rank)


func bolt_across_finish_line(bolt_across: Node2D): # sproži finish line


	if game_state == GAME_STATE.ON:
#	if not game_on: # preventam, da gre čez črto ko je konec igre
#		return

		# če je čekpoint prižgan in, če ni čekiran ... returnam
		if not bolts_checked.has(bolt_across) and Rfs.current_level.checkpoint.monitoring == true:
			pass
		else:
			Rfs.sound_manager.play_sfx("finish_horn")
			bolt_across.lap_finished(level_settings["lap_limit"])

			# odčekiram za naslednji krog in grem dalje
			bolts_checked.erase(bolt_across)


func check_for_level_finished(): # za preverjanje pogojev za game over (vsakič ko bolt spreminja aktivnost)

	var current_active_human_players: Array = []

	for bolt in bolts_in_game:
		if bolt.is_active and bolt.is_in_group(Rfs.group_humans):
			current_active_human_players.append(bolt)

	# če so vsi neaktivni, preverim kdo je v cilju
	if current_active_human_players.empty():
		level_finished()


func _get_bolt_pull_position(bolt_to_pull: Node2D):
	# na koncu izbrana pull pozicija:
	# - je na območju navigacije
	# - upošteva razdaljo do vodilnega
	# - se ne pokriva z drugim plejerjem
	#	printt ("current_pull_positions",current_pull_positions.size())

	if game_state == GAME_STATE.ON:
#	if game_on:

		# pull pozicija brez omejitev
		var pull_position_distance_from_leader: float = 10 # pull razdalja od vodilnega plejerja
		var pull_position_distance_from_leader_correction: float = bolt_to_pull.bolt_sprite.get_rect().size.y * 2 # 18 ... 20 # pull razdalja od vodilnega plejerja glede na index med trenutno pulanimi

#		var vector_to_leading_human_player: Vector2 = camera_leader.global_position - bolt_to_pull.global_position
		var vector_to_leading_human_player: Vector2 = camera_leader.position - bolt_to_pull.position
		var vector_to_pull_position: Vector2 = vector_to_leading_human_player - vector_to_leading_human_player.normalized() * pull_position_distance_from_leader
#		var bolt_pull_position: Vector2 = bolt_to_pull.global_position + vector_to_pull_position
		var bolt_pull_position: Vector2 = bolt_to_pull.position + vector_to_pull_position

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
					# preverim, da je dovolj stran od vodilnega
#					if cell_position.distance_to(camera_leader.global_position) > pull_position_distance_from_leader:
					if cell_position.distance_to(camera_leader.position) > pull_position_distance_from_leader:
						# preverim, da pozicija ni že zasedena
						# če poza ni zasedena ga dodaj med zasedene
						if not current_pull_positions.has(cell_position):
							navigation_position_as_pull_position = cell_position
						else: # če je poza zasedena dobim njen in dex med zasedenimi dodam korekcijo na zahtevani razdalji od vodilnega
							var pull_pos_index: int = current_pull_positions.find(cell_position)
							var corrected_pull_position = pull_position_distance_from_leader + pull_pos_index * pull_position_distance_from_leader_correction
#							if cell_position.distance_to(camera_leader.global_position) > corrected_pull_position:
							if cell_position.distance_to(camera_leader.position) > corrected_pull_position:
								navigation_position_as_pull_position = cell_position

		current_pull_positions.append(navigation_position_as_pull_position) # OBS trenutno ne rabim

		return navigation_position_as_pull_position


# SPAWNING ---------------------------------------------------------------------------------------------


func _spawn_level():

	# level name (iz seznama levelov v igri)
	var level_to_load_id: int = Sts.current_game_levels[current_level_index]
	# level settings
	level_settings = Sts.level_settings[level_to_load_id]
	var level_to_load_path: String = level_settings["level_path"]

	var level_z_index: int # z index v node drevesu
	if not Rfs.current_level == null: # če level že obstaja, ga najprej moram zbrisat
		level_z_index = Rfs.current_level.z_index
		Rfs.current_level.set_physics_process(false)
		Rfs.current_level.free()
	else: # če je samo level marker
		level_z_index = Rfs.game_arena.level_placeholder.z_index

	# spawn level
	var NewLevel: PackedScene = ResourceLoader.load(level_to_load_path)
	var new_level = NewLevel.instance()
	new_level.z_index = level_z_index
	new_level.connect( "level_is_set", self, "_on_level_is_set") # nujno pred add child, ker ga level sproži že na ready
	Rfs.game_arena.add_child(new_level)


func _spawn_bolt(spawned_bolt_id: int, spawned_position_index: int):

	var bolt_type: int = Pfs.player_profiles[spawned_bolt_id]["bolt_type"]
	var NewBoltInstance: PackedScene = Pfs.bolt_profiles[bolt_type]["bolt_scene"]

	var new_bolt = NewBoltInstance.instance()
	new_bolt.player_id = spawned_bolt_id
	new_bolt.modulate.a = 0 # za intro
	new_bolt.rotation_degrees = Rfs.current_level.level_start.rotation_degrees - 90 # ob rotaciji 0 je default je obrnjen navzgor
	new_bolt.global_position = start_bolt_position_nodes[spawned_position_index].global_position
	Rfs.node_creation_parent.add_child(new_bolt)

	# setup
	if Pfs.player_profiles[spawned_bolt_id]["controller_type"] == Pfs.CONTROLLER_TYPE.AI:
#		new_bolt.bolt_controller.level_navigation_positions = navigation_positions.duplicate() # _temp zakaj tukaj
		new_bolt.bolt_controller.level_navigation_positions = Rfs.current_level.level_navigation.level_navigation_points # _temp zakaj tukaj
#		new_bolt.bolt_controller.level_navigation_positions = Rfs.current_level.navigation_cells_positions.duplicate() # _temp zakaj tukaj
#		printt ("POS", Rfs.current_level.navigation_cells_positions.size() )
	match Rfs.current_level.level_type:
		Rfs.current_level.LEVEL_TYPE.RACE, Rfs.current_level.LEVEL_TYPE.RACE_LAPS:
			new_bolt.bolt_tracker = Rfs.current_level.level_track.set_new_bolt_tracker(new_bolt)

#	if not Rfs.current_level.level_type == Rfs.current_level.LEVEL_TYPE.BATTLE:

	self.connect("game_state_changed", new_bolt.bolt_controller, "_on_game_state_change") # statistika med boltom in hudom
	self.connect("message_to_drivers", new_bolt.bolt_controller, "_on_message_from_game_manager") # statistika med boltom in hudom
	new_bolt.connect("stats_changed", Rfs.hud, "_on_stats_changed") # statistika med boltom in hudom

	emit_signal("bolt_spawned", new_bolt) # pošljem na hud, da prižge stat line in ga napolne


func _start_spawning_pickables():

	if available_pickable_positions.empty():
		return

	if pickables_in_game.size() <= Rfs.game_manager.game_settings["pickables_count_limit"] - 1:

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
	_start_spawning_pickables()


# SORTERS ---------------------------------------------------------------------------------------------


func _sort_bolts_by_laps(bolt_1, bolt_2): # descending ... večji index je boljši
	# For two elements a and b, if the given method returns true, element b will be after element a in the array.

	if bolt_1.player_stats["laps_count"] > bolt_2.player_stats["laps_count"]:
	    return true
	return false


func _sort_trackers_by_offset(bolt_tracker_1, bolt_tracker_2):# descending ... večji index je boljši
	# For two elements a and b, if the given method returns true, element b will be after element a in the array.

	if bolt_tracker_1.offset > bolt_tracker_2.offset:
	    return true
	return false


func _sort_trackers_by_points(bolt_1, bolt_2):# descending ... večji index je boljši
	# For two elements a and b, if the given method returns true, element b will be after element a in the array.

	if bolt_1.player_stats["points"] > bolt_2.player_stats["points"]:
	    return true
	return false


func _sort_trackers_by_speed(bolt_1, bolt_2): # temp ...  ne uporabljam# descn ... večji index je boljši

	if bolt_1.velocity.length() > bolt_2.velocity.length():
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
	Rfs.current_camera.position = Rfs.current_level.start_camera_position_node.global_position
	Rfs.current_camera.set_camera_limits() # debug


func _on_body_exited_playing_field(body: Node) -> void:


	if game_state == GAME_STATE.ON:

		match Rfs.current_level.level_type:
			# pull player bolt
			Rfs.current_level.LEVEL_TYPE.RACE, Rfs.current_level.LEVEL_TYPE.RACE_LAPS:
				if body.is_in_group(Rfs.group_humans) and body.is_active:
					var bolt_pull_position: Vector2 = _get_bolt_pull_position(body)
					body.call_deferred("pull_bolt_on_screen", bolt_pull_position, camera_leader)
			# wrap_around all bolts
			#		_:
			#			if body.is_in_group(Rfs.group_bolts) and body.is_active:
			#				body.call_deferred("screen_wrap") # IDE

		if body.is_in_group(Rfs.group_bolts) and not body.is_active:
			body.call_deferred("set_physics_process", false)
		elif body is Bullet:
			body.on_out_of_playing_field() # ta funkcija zakasni učinek
		# elif body is Misile: ... se sama kvefrija in se lahko vrne v ekran (nitro)
