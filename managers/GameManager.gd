extends Node


signal bolt_spawned (name, other)

var game_on: bool

var bolts_in_game: Array # tekom igre so v ranked zaporedju (glede na distanco)
var bolts_finished: Array # bolti v cilju
var bolts_qualified: Array # obstaja za prenos med leveloma
var bolts_checked: Array
var activated_player_ids: Array # naslednji leveli se tole adaptira, glede na to kdo je še v igri
var camera_leader: KinematicBody2D # za camera target in pull target

# game
var game_settings: Dictionary # = Set.default_game_settings # ga med igro ne spreminjaš
var fast_start_window: bool = false # bolt ga čekira in reagira

# level 
var start_bolt_position_nodes: Array # dobi od tilemapa
var current_pull_positions: Array # že zasedene pozicije za preventanje nalaganja bolto druga na drugega
var pickables_in_game: Array
var level_settings: Dictionary
var current_level_index = 0
var available_pickable_positions: Array # za random spawn
var navigation_area: Array # vsi navigation tileti
var navigation_positions: Array # pozicije vseh navigation tiletov

onready var level_finished_ui: Control = $"../UI/LevelFinished"
onready var game_over_ui: Control = $"../UI/GameOver"


func _input(event: InputEvent) -> void:
	
	
#	if Input.is_action_just_pressed("m"):
#		var bus_index: int = AudioServer.get_bus_index("GameMusic")
#		var bus_is_mute: bool = AudioServer.is_bus_mute(bus_index)
#		AudioServer.set_bus_mute(bus_index, not bus_is_mute)
			
	if Input.is_action_just_pressed("r"):
		level_finished(false)
	
	if Input.is_action_just_pressed("x"):
		for bolt in bolts_in_game:
			if bolt.is_in_group(Ref.group_players):
				bolt.player_stats["gas_count"] = 0
			

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

	get_ranking()

	# manage Human in AI
	var active_human_bolts: Array = []
	var active_ai_bolts: Array = []
	
	for bolt in bolts_in_game:
		if bolt.is_in_group(Ref.group_players) and bolt.bolt_active:
			active_human_bolts.append(bolt)
		elif bolt.is_in_group(Ref.group_ai) and bolt.bolt_active:
			active_ai_bolts.append(bolt)
	
	if not active_human_bolts.empty():
		#		# vodilni je po točkah, sledi pa hitrejšemu
		#		if Ref.current_level.level_type == Ref.current_level.LevelTypes.BATTLE:
		#			active_human_bolts.sort_custom(self, "sort_bolts_by_speed")
		camera_leader = active_human_bolts[0] 

	# AI nav_target
	for active_ai in active_ai_bolts:
		if Ref.current_level.level_type == Ref.current_level.LevelTypes.BATTLE:
			pass
		else:
			# poiščem pripadajočega trackerja in njegovem offset
			var current_bolt_tracker: PathFollow2D
			for bolt_tracker in Ref.current_level.racing_track.get_children():
				if bolt_tracker.tracking_target == active_ai:
					current_bolt_tracker = bolt_tracker
					break
			# lociram target točko na krivulji
			var ai_target_point_on_curve: Vector2
			var ai_target_prediction: float = 50
			var ai_target_total_offset: float = current_bolt_tracker.offset + ai_target_prediction
			var bolt_tracker_curve: Curve2D = current_bolt_tracker.get_parent().get_curve()
			ai_target_point_on_curve = bolt_tracker_curve.interpolate_baked(ai_target_total_offset)
			active_ai.navigation_target_position = ai_target_point_on_curve	
	
	if camera_leader:
		if not Ref.current_camera.follow_target == camera_leader: # da kamera ne reagira, če je že setan isti plejer
			Ref.current_camera.follow_target = camera_leader
	
	
func set_game():
	
	game_settings = Set.get_level_game_settings(current_level_index)
	
	spawn_level()
	
	Ref.hud.set_hud()
	Ref.game_arena.playing_field.connect( "body_exited_playing_field", self, "_on_body_exited_playing_field")
	Ref.current_camera.follow_target = Ref.current_level.start_camera_position_node
	
	# get activated players
	activated_player_ids = []

	# če je prvi level so aktivirani dodani v meniju
	if current_level_index == 0:# 
		if not Set.players_on_game_start.empty():
			activated_player_ids = Set.players_on_game_start
		else: # debug
			activated_player_ids = [Pro.Players.P1, Pro.Players.P2] 	
#			activated_player_ids = [Pro.Players.P1] 
#			activated_player_ids = [Pro.Players.P1, Pro.Players.P2, Pro.Players.P3, Pro.Players.P4]
	# če ni prvi level dodam kvalificirane bolt_id
	elif current_level_index > 0:
		if not bolts_qualified.empty():
			for bolt in bolts_qualified:
				activated_player_ids.append(bolt.bolt_id)
		else:
			print("Error! Ni kvalificiranih ... igra ne bi smelo biti!")
	
	bolts_qualified = []
	
	# get enemies 			
	game_settings["enemies_mode"] = true # debug
	if game_settings["enemies_mode"]: # začasno vezano na Set. filet
		# za vsako prazno pozicijo dodam AI bolt_id
		var empty_positions_count = start_bolt_position_nodes.size() - activated_player_ids.size()
		for empty_position in empty_positions_count:
			# dobim štatni id bolta in 
			var new_player_index: int = activated_player_ids.size()
			var new_player_id: int = Pro.player_profiles.keys()[new_player_index]
			Pro.player_profiles[new_player_id]["controller_profile"] = Pro.ai_profile["controller_profile"]
			Pro.player_profiles[new_player_id]["bolt_scene"] = Pro.ai_profile["bolt_scene"]
			activated_player_ids.append(new_player_id) # da prepoznam v spawn funkciji .... trik pač
	
	# štartne količine orožij
	if not Ref.current_level.level_type == Ref.current_level.LevelTypes.BATTLE:
		Pro.default_player_stats["bullet_count"] = 0
		Pro.default_player_stats["misile_count"] = 0
		Pro.default_player_stats["mina_count"] = 0
		Pro.default_player_stats["shocker_count"] = 0
	if game_settings["full_equip_mode"]:
		Pro.default_player_stats["bullet_count"] = 100
		Pro.default_player_stats["misile_count"] = 100
		Pro.default_player_stats["mina_count"] = 100
		Pro.default_player_stats["shocker_count"] = 100	

	# spawn bolts on positions (po vrsti aktivacije) 
	var spawned_position_index = 0
	for bolt_id in activated_player_ids: # so v ranking zaporedju
		spawn_bolt(bolt_id, spawned_position_index) # scena, pozicija, profile id (barva, ...)
		spawned_position_index += 1
	
	game_intro()
	
	
func game_intro():
	
	# pokažem sceno
	var fade_time: float = 1
	var setup_delay: float = 1 # delay, da se kamera naštima
	var fade_tween = get_tree().create_tween()
	fade_tween.tween_property(get_parent(), "modulate", Color.white, fade_time).from(Color.black).set_delay(setup_delay)
	yield(fade_tween, "finished")
	
	yield(get_tree().create_timer(Set.get_it_time),"timeout")
	
	# bolts drive-in
	var drive_in_time: float = 2
	for bolt in bolts_in_game:
		bolt.drive_in(drive_in_time)
		
	yield(get_tree().create_timer(Set.get_it_time),"timeout")

	# start countdown	
	Ref.current_level.start_lights.start_countdown() # če je skrit, pošlje signal takoj
	yield(Ref.current_level.start_lights, "countdown_finished")		
	
	start_game()


func start_game():
	
	# start
	for bolt in bolts_in_game:
		bolt.bolt_active = true
	
	Ref.sound_manager.play_music()
	Ref.hud.on_game_start()
	
	# random pickables spawn
	if Ref.current_level.level_type == Ref.current_level.LevelTypes.BATTLE:
		start_spawning_pickables() 

	game_on = true
	
	# fast start
	fast_start_window = true	
	yield(get_tree().create_timer(game_settings["fast_start_window_time"]), "timeout")
	fast_start_window = false	
		

func level_finished(level_goal_reached: bool):
	
	Ref.current_camera.follow_target = Ref.current_level.finish_camera_position_node
	
	if game_on == false: # preprečim double gameover
		return
	game_on = false

	Ref.hud.on_level_finished()
	
	yield(get_tree().create_timer(Set.get_it_time), "timeout")
	
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
				elif bolt.is_in_group(Ref.group_players):
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
	
	# predam vse v cilju med kvalificirani v naslednji level
	bolts_qualified = bolts_finished
	bolts_finished = []	
	
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

	
func get_ranking():

	# battle ranking ... glede na točke (ne zanima me aktivnost bolta)
	if Ref.current_level.level_type == Ref.current_level.LevelTypes.BATTLE:
		bolts_in_game.sort_custom(self, "sort_bolts_by_points")
	# race ranking ... glede dolžino prevožene linije (ne zanima me aktivnost bolta)
	else:	
		var bolts_ranked: Array = []
		# najprej sortirami po poziciji trackerja, 
		var all_bolt_trackers: Array = Ref.current_level.racing_track.get_children()
		all_bolt_trackers.sort_custom(self, "sort_trackers_by_offset")
		# potem naredim array boltov v istem zaporedju kot so bolt trackerji
		for bolt_tracker in all_bolt_trackers:
			bolts_ranked.append(bolt_tracker.tracking_target)
		# potem sortam array boltov glede na število krogov
		bolts_ranked.sort_custom(self, "sort_bolts_by_laps")
		# kopiram ranking na bolte v igri
		bolts_in_game = bolts_ranked
	
	# apliciram ranking v bolte
	for bolt in bolts_in_game:
		var current_bolt_rank: int = bolts_in_game.find(bolt) + 1
		bolt.update_bolt_rank(current_bolt_rank)
	

func sort_bolts_by_speed(bolt_1, bolt_2): # ascending ... večji index je boljši
	
	if bolt_1.velocity.length() > bolt_2.velocity.length():
	    return true
	return false
	
	
func sort_bolts_by_laps(bolt_1, bolt_2): # ascending ... večji index je boljši
	
	if bolt_1.player_stats["laps_count"] > bolt_2.player_stats["laps_count"]:
	    return true
	return false


func sort_trackers_by_offset(first_bolt_tracker, second_bolt_tracker): # ascending ... večji index je boljši
	
	if first_bolt_tracker.offset > second_bolt_tracker.offset:
	    return true
	return false
	
func sort_bolts_by_points(bolt_1, bolt_2): # ascending ... večji index je boljši
	
	if bolt_1.player_stats["points"] > bolt_2.player_stats["points"]:
	    return true
	return false
	

func get_bolt_pull_position(bolt_to_pull: KinematicBody2D):
	# na koncu izbrana pull pozicija:
	# - je na območju navigacije
	# - upošteva razdaljo do vodilnega
	# - se ne pokriva z drugim plejerjem	
	
	#	printt ("current_pull_positions",current_pull_positions.size())
	
	if game_on:
		
		# pull pozicija brez omejitev
		var pull_position_distance_from_leader: float = 10 # pull razdalja od vodilnega plejerja  
		var pull_position_distance_from_leader_correction: float = bolt_to_pull.bolt_sprite.get_rect().size.y * 2 # 18 ... 20 # pull razdalja od vodilnega plejerja glede na index med trenutno pulanimi
	
		var vector_to_camera_leader: Vector2 = camera_leader.global_position - bolt_to_pull.global_position
		var vector_to_pull_position: Vector2 = vector_to_camera_leader - vector_to_camera_leader.normalized() * pull_position_distance_from_leader
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
					# preverim, da je dovolj stran od vodilnega
					if cell_position.distance_to(camera_leader.global_position) > pull_position_distance_from_leader:
						# preverim, da pozicija ni že zasedena
						# če poza ni zasedena ga dodaj med zasedene
						if not current_pull_positions.has(cell_position):
							navigation_position_as_pull_position = cell_position
						else: # če je poza zasedena dobim njen in dex med zasedenimi dodam korekcijo na zahtevani razdalji od vodilnega
							var pull_pos_index: int = current_pull_positions.find(cell_position)
							var corrected_pull_position = pull_position_distance_from_leader + pull_pos_index * pull_position_distance_from_leader_correction
							if cell_position.distance_to(camera_leader.global_position) > corrected_pull_position:
								navigation_position_as_pull_position = cell_position

		current_pull_positions.append(navigation_position_as_pull_position)
		return navigation_position_as_pull_position

				
func on_finish_line_crossed(bolt_across_finish_line: KinematicBody2D): # sproži finish line
	
	if not game_on: # preventam, da gre čez črto ko je konec igre
		return
	
	# če je čekpoint prižgan in, če ni čekiran ... returnam
	if not bolts_checked.has(bolt_across_finish_line) and Ref.current_level.checkpoint.monitoring == true:
		return
	
	Ref.sound_manager.play_sfx("finish_horn")
	bolt_across_finish_line.on_lap_finished(level_settings["lap_limit"])
	
	# odčekiram za naslednji krog in grem dalje
	bolts_checked.erase(bolt_across_finish_line)


func check_for_level_finished(): # za preverjanje pogojev za game over (vsakič ko bolt spreminja aktivnost)
	
	var still_active_human_bolts: Array = []
	
	for bolt in bolts_in_game:
		if bolt.bolt_active and bolt.is_in_group(Ref.group_players):
			still_active_human_bolts.append(bolt)
			
	# če so vsi neaktivni, preverim kdo je v cilju
	if still_active_human_bolts.empty():
		if not bolts_finished.empty():
			# SUCCESS če je vsaj en plejer bil čez ciljno črto
			for bolt in bolts_finished: 
				if bolt.is_in_group(Ref.group_players):
					level_finished(true)		
					return # dovolj je en uspeh
		# FAIL, če ni nobenega plejerja v cilju
		level_finished(false)			


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
	
	var NewBoltInstance: PackedScene = Pro.player_profiles[spawned_bolt_id]["bolt_scene"]
	
	var new_bolt = NewBoltInstance.instance()
	new_bolt.bolt_id = spawned_bolt_id
	new_bolt.modulate.a = 0 # za intro
	new_bolt.rotation_degrees = Ref.current_level.race_start_node.rotation_degrees - 90 # ob rotaciji 0 je default je obrnjen navzgor
	new_bolt.global_position = start_bolt_position_nodes[spawned_position_index].global_position
	Ref.node_creation_parent.add_child(new_bolt)

	if not Ref.current_level.level_type == Ref.current_level.LevelTypes.BATTLE:
		Ref.current_level.racing_track.set_new_bolt_tracker(new_bolt)
	
	# signali
	if new_bolt.is_in_group(Ref.group_ai):
		new_bolt.navigation_cells = navigation_area
	if new_bolt.is_in_group(Ref.group_players):
		new_bolt.connect("stats_changed", Ref.hud, "_on_stats_changed") # statistika med boltom in hudom
	
	emit_signal("bolt_spawned", new_bolt) # pošljem na hud, da prižge stat line in ga napolne
	

func start_spawning_pickables():
	
	if available_pickable_positions.empty():
		return
	
	if pickables_in_game.size() <= 20:
#	if pickables_in_game.size() <= Ref.game_manager.game_settings["pickables_count_limit"] - 1: # _temp
				
		# žrebanje tipa
		var random_pickable_key = Met.get_random_member(Pro.pickable_profiles.keys())
		var random_cell_position: Vector2 = Met.get_random_member(navigation_positions)
		Ref.current_level.spawn_pickable(random_cell_position, "random_pickable_key", random_pickable_key)
		
		# odstranim celico iz arraya tistih na voljo
		var random_cell_position_index: int = available_pickable_positions.find(random_cell_position)
		available_pickable_positions.remove(random_cell_position_index)		

	# random timer reštart
	var random_pickable_spawn_time: int = Met.get_random_member([1,2,3])
	yield(get_tree().create_timer(random_pickable_spawn_time), "timeout")
	start_spawning_pickables()

	
# PRIVAT ----------------------------------------------------------------------------------------------------


func _on_level_is_set(tilemap_navigation_cells: Array, tilemap_navigation_cells_positions: Array):
	
	# navigacija za AI
	navigation_area = tilemap_navigation_cells
	navigation_positions = tilemap_navigation_cells_positions
	
	# random pickable pozicije 
	available_pickable_positions = navigation_area.duplicate()
	
	# spawn poz
	start_bolt_position_nodes = Ref.current_level.start_positions_node.get_children()
	
	# kamera
	Ref.current_camera.position = Ref.current_level.start_camera_position_node.global_position
	Ref.current_camera.set_camera_limits()
	

# SIGNALI ----------------------------------------------------------------------------------------------------


func _on_body_exited_playing_field(body: Node) -> void:
	
	if not game_on:
		return
	
	# player pull
	if not Ref.current_level.level_type == Ref.current_level.LevelTypes.BATTLE:
		# če je aktiven human ga pulam
		if body.is_in_group(Ref.group_players) and body.bolt_active:
			var bolt_pull_position: Vector2 = get_bolt_pull_position(body)
			body.call_deferred("pull_bolt_on_screen", bolt_pull_position, camera_leader)
		# če je neaktiven bolt, mu izklopim FP
		if body.is_in_group(Ref.group_bolts) and not body.bolt_active:
				body.call_deferred("set_physics_process", false)
			
	elif body is Bullet:
		body.on_out_of_screen() # ta funkcija zakasni učinek
	# elif body is Misile: ... ima timer in se sama kvefrija ... misila se lahko vrne v ekran (nitro)


func _on_body_exited_screen(body: Node) -> void:
	
	if not game_on:
		return
	
	# player pull
	if not Ref.current_level.level_type == Ref.current_level.LevelTypes.BATTLE:
		if body.is_in_group(Ref.group_players) and body.bolt_active:
			var bolt_pull_position: Vector2 = get_bolt_pull_position(body)
			body.call_deferred("pull_bolt_on_screen", bolt_pull_position, camera_leader)
	
	if body.is_in_group(Ref.group_bolts) and not body.bolt_active:
			body.call_deferred("set_physics_process", false)
			
	elif body is Bullet:
		body.on_out_of_screen() # ta funkcija zakasni učinek
	# elif body is Misile: ... ima timer in se sama kvefrija ... misila se lahko vrne v ekran (nitro)
