extends Node


signal bolt_spawned (name, other)


var game_on: bool

var bolts_in_game: Array # tekom igre so v ranked zaporedju (glede na distanco)
var bolts_finished: Array # bolti v cilju
var human_bolts_qualified: Array # obstaja za prenos med leveloma
var bolts_checked: Array
var camera_leader: Node2D # trenutno vodilni igralec (rabim za camera target in pull target)

# game
var game_settings: Dictionary # = Set.default_game_settings # ga med igro ne spreminjaš
var activated_player_ids: Array # naslednji leveli se tole adaptira, glede na to kdo je še v igri
var fast_start_window: bool = false # bolt ga čekira in reagira
var start_bolt_position_nodes: Array # dobi od tilemapa
var current_pull_positions: Array # že zasedene pozicije za preventanje nalaganja bolto druga na drugega
export var shadows_direction: Vector2 # = game_settings["shadows_direction"]

# level 
var level_settings: Dictionary
var current_level_index = 0
var available_pickable_positions: Array # za random spawn
var navigation_positions: Array # pozicije vseh navigation tiletov
var pickables_in_game: Array

onready var level_finished_ui: Control = $"../UI/LevelFinished"
onready var game_over_ui: Control = $"../UI/GameOver"


func _input(event: InputEvent) -> void:
	
	
	#	if Input.is_action_just_pressed("m"):
	#		var bus_index: int = AudioServer.get_bus_index("GameMusic")
	#		var bus_is_mute: bool = AudioServer.is_bus_mute(bus_index)
	#		AudioServer.set_bus_mute(bus_index, not bus_is_mute)
				
	if Input.is_action_just_pressed("no1"): # idle
		Ref.current_3Dworld.change_follow_target(bolts_in_game[0])
	#	if Input.is_action_just_pressed("no2"): # race
	#		for bolt in bolts_in_game:
	#			if bolt.is_in_group(Ref.group_ai):
	#				bolt.get_node("AIController").set_ai_target(bolt.bolt_position_tracker)
	#	if Input.is_action_just_pressed("no3"):
	#		for bolt in bolts_in_game: # search
	#			if bolt.is_in_group(Ref.group_ai):
	#				bolt.get_node("AIController").set_ai_target(Ref.current_level.tilemap_edge)
	#	if Input.is_action_just_pressed("no4"): # follow leader
	#		for bolt in bolts_in_game:
	#			if bolt.is_in_group(Ref.group_ai):
	#				bolt.get_node("AIController").set_ai_target(camera_leader)
	if Input.is_action_just_pressed("no5"):
		for bolt in bolts_in_game:
			if bolt.is_in_group(Ref.group_humans):
#				bolt.queue_free()
				bolt.lose_life()
				#				bolt.player_stats["gas_count"] = 0
				#			if bolt.is_in_group(Ref.group_ai):
				#				bolt.player_stats["gas_count"] = 0			


func _ready() -> void:
	printt("GM")
	
	Ref.game_manager = self	
	Ref.current_level = null # da deluje reštart
	
	# intro:
	get_parent().modulate = Color.black

	call_deferred("set_game")


func _process(delta: float) -> void:
	
	bolts_in_game = get_tree().get_nodes_in_group(Ref.group_bolts)
	pickables_in_game = get_tree().get_nodes_in_group(Ref.group_pickables)	

	#	if game_on: 
		
	update_ranking()
			
	var active_human_bolts: Array = []
	for bolt in bolts_in_game:
		if bolt.is_in_group(Ref.group_humans) and bolt.bolt_active:
			active_human_bolts.append(bolt)
	if active_human_bolts.empty(): 
		camera_leader = null
	else:	
		camera_leader = active_human_bolts[0]
	
	if not Ref.current_camera.follow_target == camera_leader: # da kamera ne reagira, če je že setan isti plejer
		Ref.current_camera.follow_target = camera_leader


func set_game():
	
	game_settings = Set.get_level_game_settings(current_level_index)
	
	spawn_level()
	
	Ref.hud.set_hud()
	
	# playing field
	Ref.game_arena.playing_field.connect( "body_exited_playing_field", self, "_on_body_exited_playing_field")
	if Ref.current_level.level_type == Ref.current_level.LEVEL_TYPE.BATTLE:
		#		Ref.game_arena.playing_field.screen_edge_collision.disabled = false
		Ref.game_arena.playing_field.screen_edge_collision.set_deferred("disabled", false)
	else:
		#		Ref.game_arena.playing_field.screen_edge_collision.disabled = true
		Ref.game_arena.playing_field.screen_edge_collision.set_deferred("disabled", true)
	
	Ref.current_camera.follow_target = Ref.current_level.start_camera_position_node
	
	# players
	activated_player_ids = []
	# če je prvi level so aktivirani dodani v meniju
	if current_level_index == 0:
		# debug ... kadar ne štartam igre iz home menija
		if Set.players_on_game_start.empty():
			pass
#			activated_player_ids = [Pro.PLAYER.P1] 	
			activated_player_ids = [Pro.PLAYER.P1, Pro.PLAYER.P2] 	
#			activated_player_ids = [Pro.PLAYER.P1, Pro.PLAYER.P2, Pro.PLAYER.P3, Pro.PLAYER.P4]
		else:
			activated_player_ids = Set.players_on_game_start
	# če ni prvi level dodam kvalificirane player_id
	elif current_level_index > 0:
		if human_bolts_qualified.empty():
			print("Error! Ni qvalificiranih boltov, torej igre nebi smelo biti!")
		else:
			for bolt in human_bolts_qualified:
				activated_player_ids.append(bolt.player_id)
	human_bolts_qualified = []
	
	# get enemies 			
#	game_settings["enemies_mode"] = true # debug
	
	if game_settings["enemies_mode"]: # začasno vezano na Set. filet
		# za vsako prazno pozicijo dodam AI player_id
		var empty_positions_count = start_bolt_position_nodes.size() - activated_player_ids.size()
		empty_positions_count = 1 # debug
		for empty_position in empty_positions_count:
			# dobim štartni id bolta in umestim ai data
			var new_player_index: int = activated_player_ids.size()
			var new_player_id: int = Pro.player_profiles.keys()[new_player_index]
			Pro.player_profiles[new_player_id]["controller_type"] = Pro.ai_profile["controller_type"]
#			Pro.player_profiles[new_player_id]["bolt_scene"] = Pro.ai_profile["bolt_scene"]
			activated_player_ids.append(new_player_id) # da prepoznam v spawn funkciji .... trik pač
	
	printt("PLAYERS", activated_player_ids)	
		
	# adaptacija količine orožij
#	if not Ref.current_level.level_type == Ref.current_level.LEVEL_TYPE.BATTLE:
	if Ref.current_level.level_type == Ref.current_level.LEVEL_TYPE.BATTLE:
		Pro.default_player_stats["bullet_count"] = 0
		Pro.default_player_stats["misile_count"] = 0
		Pro.default_player_stats["mina_count"] = 0
	game_settings["full_equip_mode"] = true # debug
	if game_settings["full_equip_mode"]:
		Pro.default_player_stats["bullet_count"] = 100
		Pro.default_player_stats["misile_count"] = 100
		Pro.default_player_stats["mina_count"] = 100

	# spawn bolts on positions (po vrsti aktivacije) 
	var spawned_position_index = 0
	for player_id in activated_player_ids: # so v ranking zaporedju
		spawn_bolt(player_id, spawned_position_index) # scena, pozicija, profile id (barva, ...)
		spawned_position_index += 1
	
	game_intro()
	
	
func game_intro():
	
	# pokažem sceno
	var fade_time: float = 1
	var setup_delay: float = 1 # delay, da se kamera naštima
	var fade_tween = get_tree().create_tween()
	fade_tween.tween_property(get_parent(), "modulate", Color.white, fade_time).from(Color.black).set_delay(setup_delay)
	yield(fade_tween, "finished")
	
#	yield(get_tree().create_timer(Set.get_it_time),"timeout")
	
	# bolts drive-in
	for bolt in bolts_in_game:
		bolt.drive_in()
		
#	yield(get_tree().create_timer(Set.get_it_time),"timeout")

	# start countdown	
	Ref.current_level.start_lights.start_countdown() # če je skrit, pošlje signal takoj
	yield(Ref.current_level.start_lights, "countdown_finished")		
	
	start_game()


func start_game():
	
	# start
	for bolt in bolts_in_game:
		#		bolt.bolt_active = true
		if bolt.is_in_group(Ref.group_ai):
			if Ref.current_level.level_type == Ref.current_level.LEVEL_TYPE.BATTLE:
				pass
			else:
				bolt.bolt_controller.set_ai_target(bolt.bolt_position_tracker)
			
				
	Ref.sound_manager.play_music()
	Ref.hud.on_game_start()
	
	# random pickables spawn
	if Ref.current_level.level_type == Ref.current_level.LEVEL_TYPE.BATTLE:
		start_spawning_pickables() 

	game_on = true
	
	# fast start
	fast_start_window = true	
	yield(get_tree().create_timer(game_settings["fast_start_window_time"]), "timeout")
	fast_start_window = false	
		

func level_finished():
	
	Ref.current_camera.follow_target = Ref.current_level.finish_camera_position_node
	
	if game_on == false: # preprečim double gameover
		return
	game_on = false

	Ref.hud.on_level_finished()
	
	yield(get_tree().create_timer(Set.get_it_time), "timeout")
	
	# preverim, če je kakšen človek kvalificiran
	if bolts_finished.empty():
		pass
	else:
		# SUCCESS če je vsaj en plejer bil čez ciljno črto
		for bolt in bolts_finished: 
			if bolt.is_in_group(Ref.group_humans):
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
				if bolt.is_in_group(Ref.group_ai):	
					# AI se vedno uvrsti in dobi nekaj časa glede na zadnjega v cilju
					var worst_time_among_finished: float = bolts_finished[bolts_finished.size() - 1].player_stats["level_time"]
					bolt.player_stats["level_time"] = worst_time_among_finished + worst_time_among_finished / 5
					bolts_finished.append(bolt)
				elif bolt.is_in_group(Ref.group_humans):
					# plejer se na Easy_mode uvrsti brez časa
					if game_settings["easy_mode"]:
						bolts_finished.append(bolt)
		

		
		# je level zadnji?
		if current_level_index < (Set.current_game_levels.size() - 1):
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
		if bolt.bolt_active: # zazih
			bolt.bolt_active = false
		bolt.set_physics_process(false)
			
	# music stop
	Ref.sound_manager.stop_music()
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
	if not Ref.sound_manager.sfx_set_to_mute:
		var bus_index: int = AudioServer.get_bus_index("GameSfx")
		AudioServer.set_bus_mute(bus_index, false)
	
	# zbrišem vse otroke v NCP (bolti, orožja, efekti, ...)
	var all_children: Array = Ref.node_creation_parent.get_children()
	for child in all_children:
		child.queue_free()

	# reset level values
	camera_leader = null # trenutno vodilni igralec (rabim za camera target in pull target)
	
	call_deferred("set_game")

	
# RACING ---------------------------------------------------------------------------------------------

	
func update_ranking():
	
	if Ref.current_level.level_type == Ref.current_level.LEVEL_TYPE.BATTLE:
		bolts_in_game.sort_custom(self, "sort_trackers_by_points")
	else:
		# najprej sortirami po poziciji trackerja, 
		# potem naredim array boltov v istem zaporedju
		# potem razporedim array boltov glede na kroge
		var bolts_ranked: Array = []
		var all_bolt_trackers: Array = Ref.current_level.racing_track.get_children()
		all_bolt_trackers.sort_custom(self, "sort_trackers_by_offset")
		for bolt_tracker in all_bolt_trackers:
			bolts_ranked.append(bolt_tracker.tracking_target)
		bolts_ranked.sort_custom(self, "sort_bolts_by_laps")
		bolts_in_game = bolts_ranked

	for bolt in bolts_in_game:
		var current_bolt_rank: int = bolts_in_game.find(bolt) + 1
		bolt.update_bolt_rank(current_bolt_rank)
	

func sort_bolts_by_laps(bolt_1, bolt_2): # ascending ... večji index je boljši
	
	if bolt_1.player_stats["laps_count"] > bolt_2.player_stats["laps_count"]:
	    return true
	return false


func sort_trackers_by_offset(bolt_tracker_1, bolt_tracker_2): # ascending ... večji index je boljši
	
	if bolt_tracker_1.offset > bolt_tracker_2.offset:
	    return true
	return false
	
	
func sort_trackers_by_points(bolt_1, bolt_2): # ascending ... večji index je boljši
	
	if bolt_1.player_stats["points"] > bolt_2.player_stats["points"]:
	    return true
	return false
	
	
func sort_trackers_by_speed(bolt_1, bolt_2): # ascending ... večji index je boljši
	
	if bolt_1.velocity.length() > bolt_2.velocity.length():
	    return true
	return false
	

func get_bolt_pull_position(bolt_to_pull: Node2D):
	# na koncu izbrana pull pozicija:
	# - je na območju navigacije
	# - upošteva razdaljo do vodilnega
	# - se ne pokriva z drugim plejerjem	
	#	printt ("current_pull_positions",current_pull_positions.size())
	
	if game_on:
		
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

				
func bolt_across_finish_line(bolt_across: Node2D): # sproži finish line
	
	if not game_on: # preventam, da gre čez črto ko je konec igre
		return
	
	# če je čekpoint prižgan in, če ni čekiran ... returnam
	if not bolts_checked.has(bolt_across) and Ref.current_level.checkpoint.monitoring == true:
		return
	
	Ref.sound_manager.play_sfx("finish_horn")
	bolt_across.lap_finished(level_settings["lap_limit"])
	
	# odčekiram za naslednji krog in grem dalje
	bolts_checked.erase(bolt_across)


func check_for_level_finished(): # za preverjanje pogojev za game over (vsakič ko bolt spreminja aktivnost)
	
	var current_active_human_players: Array = []
	
	for bolt in bolts_in_game:
		if bolt.bolt_active and bolt.is_in_group(Ref.group_humans):
			current_active_human_players.append(bolt)
			
	# če so vsi neaktivni, preverim kdo je v cilju
	if current_active_human_players.empty():
		level_finished()			


# SPAWNING ---------------------------------------------------------------------------------------------


func spawn_level():
	
	# level name (iz seznama levelov v igri)
	var level_to_load_id: int = Set.current_game_levels[current_level_index]
	# level settings
	level_settings = Set.level_settings[level_to_load_id]
	var level_to_load_path: String = level_settings["level_path"]
	
	var level_z_index: int # z index v node drevesu
	if not Ref.current_level == null: # če level že obstaja, ga najprej moram zbrisat
		level_z_index = Ref.current_level.z_index
		Ref.current_level.set_physics_process(false)
		Ref.current_level.free()
	else: # če je samo level marker
		level_z_index = Ref.game_arena.level_placeholder.z_index
		
	# spawn level
	var NewLevel: PackedScene = ResourceLoader.load(level_to_load_path)
	var new_level = NewLevel.instance()
	new_level.z_index = level_z_index
	new_level.connect( "level_is_set", self, "_on_level_is_set") # nujno pred add child, ker ga level sproži že na ready
	Ref.game_arena.add_child(new_level)	
	
	
func spawn_bolt(spawned_bolt_id: int, spawned_position_index: int):
	
	var bolt_type: int = Pro.player_profiles[spawned_bolt_id]["bolt_type"]
	var NewBoltInstance: PackedScene = Pro.bolt_profiles[bolt_type]["bolt_scene"]
	
	var new_bolt = NewBoltInstance.instance()
	new_bolt.player_id = spawned_bolt_id
	new_bolt.modulate.a = 0 # za intro
	new_bolt.rotation_degrees = Ref.current_level.race_start.rotation_degrees - 90 # ob rotaciji 0 je default je obrnjen navzgor
	new_bolt.global_position = start_bolt_position_nodes[spawned_position_index].global_position
	Ref.node_creation_parent.add_child(new_bolt)
	
	# setup
	if Pro.player_profiles[spawned_bolt_id]["controller_type"] == Pro.CONTROLLER_TYPE.AI:
		new_bolt.bolt_controller.level_navigation_positions = navigation_positions.duplicate()
	if not Ref.current_level.level_type == Ref.current_level.LEVEL_TYPE.BATTLE:
		new_bolt.bolt_position_tracker = Ref.current_level.racing_track.set_new_bolt_tracker(new_bolt)
	new_bolt.connect("stats_changed", Ref.hud, "_on_stats_changed") # statistika med boltom in hudom
	emit_signal("bolt_spawned", new_bolt) # pošljem na hud, da prižge stat line in ga napolne
	

func start_spawning_pickables():
	
	if available_pickable_positions.empty():
		return
	
	if pickables_in_game.size() <= Ref.game_manager.game_settings["pickables_count_limit"] - 1:
				
		# žrebanje tipa
		var random_pickable_key = Met.get_random_member(Pro.pickable_profiles.keys())
		var random_cell_position: Vector2 = Met.get_random_member(navigation_positions)
		Ref.current_level.spawn_pickable(random_cell_position, "random_pickable_key", random_pickable_key)
		
		# odstranim celico iz arraya tistih na voljo
		var random_cell_position_index: int = available_pickable_positions.find(random_cell_position)
		available_pickable_positions.remove(random_cell_position_index)		

	# random timer reštart
	var random_pickable_spawn_time: int = Met.get_random_member([1,2,3])
	yield(get_tree().create_timer(random_pickable_spawn_time), "timeout") # OPT ... uvedi node timer
	start_spawning_pickables()

	
# PRIVAT ----------------------------------------------------------------------------------------------------


func _on_level_is_set(tilemap_navigation_cells_positions: Array):
	
	# navigacija za AI
	navigation_positions = tilemap_navigation_cells_positions
	
	# random pickable pozicije 
	available_pickable_positions = tilemap_navigation_cells_positions.duplicate()
	
	# spawn poz
	start_bolt_position_nodes = Ref.current_level.start_positions_node.get_children()
	
	# kamera
	Ref.current_camera.position = Ref.current_level.start_camera_position_node.global_position
	Ref.current_camera.set_camera_limits()
	

func _on_body_exited_playing_field(body: Node) -> void:
	
	if not game_on:
		return
	
	if Ref.current_level.level_type == Ref.current_level.LEVEL_TYPE.BATTLE:
		# wrap_around all bolts
		if body.is_in_group(Ref.group_bolts) and body.bolt_active:
			# body.call_deferred("screen_wrap") # IDE
			pass
	else:
		# pull player bolt
		if body.is_in_group(Ref.group_humans) and body.bolt_active:
			var bolt_pull_position: Vector2 = get_bolt_pull_position(body)
			body.call_deferred("pull_bolt_on_screen", bolt_pull_position, camera_leader)
			
	if body.is_in_group(Ref.group_bolts) and not body.bolt_active:
		body.call_deferred("set_physics_process", false)
	elif body is Bullet:
		body.on_out_of_screen() # ta funkcija zakasni učinek
	# elif body is Misile: ... se sama kvefrija in se lahko vrne v ekran (nitro)
