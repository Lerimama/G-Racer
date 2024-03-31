extends Node


signal stat_change_received (player_index, changed_stat, stat_new_value)
signal new_bolt_spawned (name, other)

#enum GameoverReason {SUCCES, FAIL, TIME} # ali kdo od plejerjev napreduje, ali pa ne
#enum LevelGoal{SUCCES, FAIL}
#var level_goal_reached: bool # za GO


var game_on: bool

var bolt_spawn_position_nodes: Array # dobi od tilemapa
var bolts_in_game: Array
var pickables_in_game: Array
var bolts_on_start: Array # GO naredi poročilo o vseh, ki so bili na štaru
var bolts_across_finish_line: Array # bolti v cilju

# level
var navigation_area: Array # vsi navigation tileti
var navigation_positions: Array # pozicije vseh navigation tiletov
var available_pickable_positions: Array # za random spawn

# ranking
var leading_player: KinematicBody2D # trenutno vodilni igralec (rabim za camera target in pull target)
var leading_racing_line: Line2D	
var level_racing_lines: Array 
var level_racing_points: Array # pike vseh linij
#var all_bolts_ranked: Array = []

#onready var level_settings: Dictionary = Set.current_level_settings # ga med igro ne spreminjaš
onready var game_settings: Dictionary = Set.current_game_settings # ga med igro ne spreminjaš
onready var level_settings: Dictionary
#onready var game_settings: Dictionary
onready var navigation_line: Line2D = $"../NavigationPath"

var position_indikator: Node2D	# debug

# neu ... race managerja
var checkpoints_per_lap: int
var level_goal_position: Vector2
var level_start_position: Vector2
var default_enemy_racing_point_offset: int = 20 # da lahko resetiram
var enemy_racing_point_offset: int = 20 # prediction points length ... vpliva na natančnost gibanja
var fast_start_window: bool = false
var enemy_racing_line_index: int = 0
#onready var laps_limit: int = level_settings["lap_limit"]
#onready var NewLevel: PackedScene = level_settings["level_scene"]
onready	var current_bolts_activated_ids: Array = Set.bolts_activated # naslednji leveli se tole adaptira, glede na to kdo je še v igri
#var qualified_bolt_ids: Array # za naslednji level
var qualified_bolts: Array # za naslednji level
var current_level_index: int = 0
var defaultplayer
var current_pull_positions: Array # trenutno zasedene za preventanje nalaganja bolto druga na drugega


func _input(event: InputEvent) -> void:
	
	
	if Input.is_action_just_pressed("m"):
		var bus_index: int = AudioServer.get_bus_index("GameMusic")
		var bus_is_mute: bool = AudioServer.is_bus_mute(bus_index)
		AudioServer.set_bus_mute(bus_index, not bus_is_mute)
			
	if Input.is_action_just_pressed("x"):
		level_finished(true)
#		for bolt in bolts_in_game:
#			bolt.bolt_active = false
#			bolt.call_deferred("queue_free")
	if Input.is_action_just_pressed("f"):
		for bolt in bolts_in_game:
			bolt.gas_count = 0
#			printt("GC", bolt.gas_count)
			
	if game_on:
#			spawn_pickable()
		if Input.is_action_just_released("r"):
			Ref.main_node.to_next_level()


func _ready() -> void:
	printt("GM")
	
	Ref.game_manager = self	
	Ref.current_level = null # da deluje reštart
	
	
func _process(delta: float) -> void:
	
	bolts_in_game = get_tree().get_nodes_in_group(Ref.group_bolts)
	pickables_in_game = get_tree().get_nodes_in_group(Ref.group_pickables)	

	if game_on: 
		if game_settings["race_mode"]:
			get_bolts_ranking()
	
var current_additional_enemies_rank: int = 0
	
func set_game(): # kliče main.gd pred fejdin igre na nov level
	
	spawn_level()	
#	game_settings["start_player_count"] = 1
#	if bolts_in_game.empty():
	if Set.debug_mode:
		if current_bolts_activated_ids.empty(): # kadar ne štartam igre iz home menija
#			current_bolts_activated_ids = [Pro.Bolts.P1] 
			current_bolts_activated_ids = [Pro.Bolts.P1, Pro.Bolts.P2] 	
#			current_bolts_activated_ids = [Pro.Bolts.P1, Pro.Bolts.ENEMY] 
#			current_bolts_activated_ids = [Pro.Bolts.P1, Pro.Bolts.ENEMY, Pro.Bolts.P2 ] 
#			current_bolts_activated_ids = [Pro.Bolts.P1, Pro.Bolts.P2,Pro.Bolts.ENEMY, Pro.Bolts.ENEMY] 
#			current_bolts_activated_ids = [Pro.Bolts.P1, Pro.Bolts.P2, Pro.Bolts.P3, Pro.Bolts.P4]
	
#	var current_bolt_rank
#			current_bolts_activated_ids.append(Pro.Bolts.ENEMY)
	for bolt_id in current_bolts_activated_ids:
#		if current_level_index == 0:
#			current_bolt_rank = bolt_spawn_position_nodes[current_bolts_activated_ids.find(bolt_id)] 
#		else:
#			current_bolt_rank
		spawn_bolt(bolt_id) # scena, pozicija, profile id (barva, ...)
#		spawn_bolt(bolt_id, bolt_spawn_position_nodes[current_bolts_activated_ids.find(bolt_id)]) # scena, pozicija, profile id (barva, ...)
	
#	game_settings["ai_mode"] = false
	if game_settings["ai_mode"]:
		while current_additional_enemies_rank < bolt_spawn_position_nodes.size():
			var free_positions_count: int = bolt_spawn_position_nodes.size() - current_bolts_activated_ids.size()
			var taken_positions_count: int = bolt_spawn_position_nodes.size() - free_positions_count
#		if free_positions_count > 0:
			current_additional_enemies_rank = taken_positions_count + 1
#			for position_index in free_positions_count:
#				printt("INDEX", position_index)
#				current_additional_enemies_rank = taken_positions_count + position_index + 1
				
#				current_bolts_activated_ids.append(Pro.Bolts.ENEMY) # da prepoznam v spawn funkciji .... trik pač
#				spawn_bolt(10) # scena, pozicija, profile id (barva, ...)
			current_bolts_activated_ids.append(Pro.Bolts.ENEMY) # da prepoznam v spawn funkciji .... trik pač
#			current_additional_enemies_rank += 1
			spawn_bolt(10) # scena, pozicija, profile id (barva, ...)
#			spawn_bolt(10) # scena, pozicija, profile id (barva, ...)
				
				
				
#	for bolt_id in current_bolts_activated_ids:
##		if current_level_index == 0:
##			current_bolt_rank = bolt_spawn_position_nodes[current_bolts_activated_ids.find(bolt_id)] 
##		else:
##			current_bolt_rank
#		spawn_bolt(bolt_id) # scena, pozicija, profile id (barva, ...)
#		spawn_bolt(bolt_id, bolt_spawn_position_nodes[current_bolts_activated_ids.find(bolt_id)]) # scena, pozicija, profile id (barva, ...)
	
	# dodam komp
#	game_settings["ai_mode"] = false
#	if game_settings["ai_mode"]:
#		# koliko pozicij je nezasedenih?
#		var free_positions_count: int = bolt_spawn_position_nodes.size() - current_bolts_activated_ids.size()
#		if free_positions_count > 0:
#			for n in free_positions_count:
#				free_position_index += 1
#
#				spawn_bolt(Pro.Bolts.ENEMY)
##				spawn_bolt(Pro.Bolts.ENEMY, bolt_spawn_position_nodes[bolt_spawn_position_nodes.size() - (1 + n)])	
#		elif free_positions_count < 0:
#			print("ERROR - premalo level pozicij")
	
		
	if Ref.current_level.start_lights.visible:
		Ref.current_level.start_lights.start_countdown()
		yield(Ref.current_level.start_lights, "countdown_finished") # sproži ga hud po slide-inu
	else:
		Ref.hud.start_countdown.start_countdown()
		yield(Ref.hud.start_countdown, "countdown_finished") # sproži ga hud po slide-inu
		
	start_game()


func start_game():
	
#	for bolt in bolts_in_game:
#		Ref.current_camera.follow_target = bolt
#	if not bolts_across_finish_line.empty():
#		Ref.current_camera.follow_target = bolts_across_finish_line[0]
#		bolts_across_finish_line.clear()
	
	Ref.sound_manager.play_music()
	for bolt in bolts_in_game:
#		if not bolt.is_in_group(Ref.group_enemies):
			bolt.bolt_active = true

	Ref.hud.on_game_start()
	
	if game_settings["spawn_pickables_mode"]:
		spawn_pickable()
		
	game_on = true
	
	# fast start
	fast_start_window = true	
	yield(get_tree().create_timer(0.32), "timeout") # za dojet
	fast_start_window = false	
		

func level_finished(level_goal_reached: bool):
	
	if game_on == false: # preprečim double gameover
		return
	game_on = false

	print("Level finished")
	Ref.current_camera.follow_target = null
	
	yield(get_tree().create_timer(2), "timeout") # za dojet
	
	if level_goal_reached:
		
		var last_finished_time: float # da lahko fajkem za enemija
		for bolt in bolts_in_game:
			if bolts_across_finish_line.has(bolt):
				last_finished_time = bolt.level_finished_time # na koncu je time od zadnjega uvrščenega
			# enemy uspe, če zaključim preden je v cilju
			else:
				if bolt.is_in_group(Ref.group_enemies):	
	#			if bolt.is_in_group(Ref.group_enemies) and not bolts_across_finish_line.has(bolt):
					bolt.level_finished_time = last_finished_time + 32
					bolts_across_finish_line.append(bolt)
					printt("time", last_finished_time, bolt.level_finished_time)
		for bolt in bolts_across_finish_line:
#			printt("Bolts rank on finish", bolt.bolt_id, bolt.player_name, bolt)
			qualified_bolts.append(bolt)
		
		Ref.level_completed.open(bolts_across_finish_line, bolts_on_start)
		# save data
#		printt("Level SUCCESS", bolts_across_finish_line.size())
#		for bolt_across_finish_line in bolts_across_finish_line:
#			printt("Bolts rank on finish", bolt_across_finish_line[0].bolt_id, bolt_across_finish_line[0].player_name, bolt_across_finish_line[1])
#			qualified_bolts.append([bolt_across_finish_line[0].bolt_id, bolt_across_finish_line[0].player_stats])
#		Ref.level_completed.open(bolts_across_finish_line, bolts_on_start)
		# save data
		printt("Level SUCCESS", bolts_across_finish_line.size())

#				bolt.queue_free()
		
		
	else:
		Ref.game_over.open_gameover(bolts_across_finish_line, bolts_on_start)
		print("Level FAIL")
	
	# level reset
#	yield(get_tree().create_timer(1), "timeout") # da se GO do konca prifejda
	# HUD reset
	Ref.hud.on_level_finished()
	# music stop
	Ref.sound_manager.stop_music()
	# sfx mute
	var bus_index: int = AudioServer.get_bus_index("GameSfx")
	AudioServer.set_bus_mute(bus_index, true)
	# best lap stats reset
	# looping sounds stop
	# navigacija enemyja
	# kvefri elementov, ki so v areni
	bolt_spawn_position_nodes
	

func spawn_level():
	
	current_level_index += 1
	# level name
	var level_to_load: int = Set.game_levels[current_level_index - 1]
	# level settings
	level_settings = Set.level_settings[level_to_load]
	var level_to_load_path: PackedScene = level_settings["level_scene"]
	
	var level_position: Position2D = $"../LevelPosition"
	var level_z_index: int # z index v node drevesu
	
	if not Ref.current_level == null: # če level že obstaja, ga najprej moram zbrisat
		level_z_index = Ref.current_level.z_index
		Ref.current_level.set_physics_process(false)
		Ref.current_level.free()
	else: # če je samo level marker
		level_z_index = level_position.z_index
		
	# spawn level
	# var Level = ResourceLoader.load(level_to_load_path)
	# var new_level = Level.instance()
	var new_level = level_to_load_path.instance()
	new_level.z_index = level_z_index
	new_level.connect( "level_is_set", self, "_on_level_is_set") # nujno pred add child, ker ga level sproži že na ready
	Ref.node_creation_parent.add_child(new_level)	
	
	
func start_next_level():
#	spawn pozicije so drugačne
#	statistika je drugačna 
#	to bo pa to

	for bolt in bolts_in_game:
		# odstrani nekvalificirane bolte iz aktiviranih
		if not qualified_bolts.has(bolt):
			current_bolts_activated_ids.erase(bolt.bolt_id)
		# vse bolte zbrišem ... na začetku vsakega levela spawnam samo aktivne
		bolt.queue_free()
			
#	for bolt_id in current_bolts_activated_ids:
#		if not qualified_bolts[0].has(bolt_id):
#			current_bolts_activated_ids.erase(bolt_id)
#			printt("erased", bolt_id)
#	for bolt_id in current_bolts_activated_ids:
#		if not qualified_bolts[0].has(bolt_id):
#			current_bolts_activated_ids.erase(bolt_id)
#			printt("erased", bolt_id)

#	for bolt in bolts_in_game:
#		bolt.queue_free()

	# reset level values
	leading_player = null # trenutno vodilni igralec (rabim za camera target in pull target)
	leading_racing_line = null
	level_racing_lines = [] 
	level_racing_points = []
#	all_bolts_ranked = []
	checkpoints_per_lap = 0
	level_goal_position = Vector2.ZERO
	level_start_position = Vector2.ZERO
	bolts_across_finish_line = []
	bolts_on_start = []
	# ne brišem rankinga
	
	set_game()
	
	current_additional_enemies_rank = 0
	qualified_bolts = [] # nujno za set game
	
			
func check_for_level_completed(): # za preverjanje pogojev za game over (vsakič ko bolt spreminja aktivnost)
	
	var active_players: Array
	
	for bolt in bolts_in_game:
		if bolt.bolt_active and bolt.is_in_group(Ref.group_players):
			active_players.append(bolt)
			
	# če so vsi neaktivni, preverim kdo je v cilju
	if active_players.empty():
		if not bolts_across_finish_line.empty():
			# SUCCESS če je vsaj en plejer bil čez ciljno črto
			for bolt in bolts_across_finish_line: 
				if bolt.is_in_group(Ref.group_players):
					level_finished(true)		
					return # dovolj je en uspeh
		# FAIL, če ni nobenega plejerja v cilju
		level_finished(false)			
#	# če so vsi neaktivni, preverim kdo je v cilju
#	if active_players.empty():
#		if not bolts_across_finish_line.empty():
#			# SUCCESS če je vsaj en plejer bil čez ciljno črto
#			for bolt_across_finish_line in bolts_across_finish_line: 
#				if bolt_across_finish_line[0].is_in_group(Ref.group_players):
#					level_finished(true)		
#					return # dovolj je en uspeh
#		# FAIL, če ni nobenega plejerja v cilju
#		level_finished(false)			

		
func on_finish_line_crossed(bolt_finished: KinematicBody2D): # sproži finish line
	
	var time_to_finish: float = 2 # čas za druge, da dosežejo cilj
	#	var current_race_time: float  = Ref.hud.game_timer.current_game_time # beleženje časa
	
	var current_race_time: float  = Ref.hud.game_timer.absolute_game_time # pozitiven game čas v sekundah
	
	# LAP FINISHED
	checkpoints_per_lap = 1
	if bolt_finished.checkpoints_reached.size() >= checkpoints_per_lap:
		bolt_finished.on_lap_finished(current_race_time, level_settings["lap_limit"])
		Ref.sound_manager.play_sfx("finish_horn")
	
	
	# RACE FINISHED
	# če je izpolnil število krogov, ga pripnem, ki tistim ki so končali 
	if bolt_finished.laps_finished_count >= level_settings["lap_limit"]:
#		var race_finished_time: float = current_race_time
		bolt_finished.player_stats["level_finished_time"] = current_race_time
		bolts_across_finish_line.append(bolt_finished) # pripnem šele tukaj, da lahko prej čekiram, če je prvi plejer
		# deaktiviram plejerja in zabležim statistiko 
		if bolt_finished.is_in_group(Ref.group_players):
			bolt_finished.bolt_active = false # enemy se disebla ko doseže target
		elif bolt_finished.is_in_group(Ref.group_enemies):
			bolt_finished.on_race_finished()
#		bolts_across_finish_line.append([bolt_finished, race_finished_time]) # pripnem šele tukaj, da lahko prej čekiram, če je prvi plejer
#		# deaktiviram plejerja in zabležim statistiko 
#		if bolt_finished.is_in_group(Ref.group_players):
#			bolt_finished.bolt_active = false # enemy se disebla ko doseže target
#		elif bolt_finished.is_in_group(Ref.group_enemies):
#			bolt_finished.on_race_finished()
	


# SPAWNING ---------------------------------------------------------------------------------------------


func spawn_bolt(spawned_bolt_id: int): #, spawn_position_node: Node2D): #, spawned_bolt_index: int): # scena, pozicija, bolt id
#func spawn_bolt(spawned_bolt_id: int, spawn_position_node: Node2D): #, spawned_bolt_index: int): # scena, pozicija, bolt id
#func spawn_bolt(NewBolt: PackedScene, spawn_position_node: Node2D, spawned_bolt_id: int, spawned_bolt_index: int): # scena, pozicija, bolt id
	var NewBolt: PackedScene# = Pro.default_player_profiles[spawned_bolt_id]["player_scene"]
	
	if spawned_bolt_id == 10:
#		print("JUHEEEEEJ")
#		spawned_bolt_id = Pro.Bolts.ENEMY
		NewBolt = Pro.default_player_profiles[Pro.Bolts.ENEMY]["player_scene"]
	else:
		NewBolt = Pro.default_player_profiles[spawned_bolt_id]["player_scene"]

#		if current_level_index == 0:
#			current_bolt_rank = bolt_spawn_position_nodes[current_bolts_activated_ids.find(bolt_id)] 
#		else:
#			current_bolt_rank

	# za prenos v spawnanega
	var spawned_bolt_stats: Dictionary 
	var current_bolt_rank: int
	
	if spawned_bolt_id == 10:
		print("JUHEEEEEJ")
		if game_settings["ai_mode"]:
		# additional enemies
			spawned_bolt_stats = Pro.default_bolt_stats.duplicate()	
			current_bolt_rank = current_additional_enemies_rank
			spawned_bolt_id = Pro.Bolts.ENEMY
			
			pass
	else:		
		# če ni prvi level
		if current_level_index > 0 and not qualified_bolts.empty(): 
			# če je bolt_id enak trenutno spawnanemu mu podam pripadajočo statistiko
			for bolt in qualified_bolts:
				if bolt.bolt_id == spawned_bolt_id:
					spawned_bolt_stats = bolt.player_stats
					current_bolt_rank = spawned_bolt_stats["level_rank"]
		else: # prvi level ...  default statsi
			spawned_bolt_stats = Pro.default_bolt_stats.duplicate()	
			current_bolt_rank = current_bolts_activated_ids.find(spawned_bolt_id) + 1 # fejkam
	

	
			
				
	var new_bolt = NewBolt.instance()
	new_bolt.bolt_id = spawned_bolt_id
	# new_bolt.bolt_id = spawned_bolt_index
	new_bolt.global_position = bolt_spawn_position_nodes[current_bolt_rank - 1].global_position
	new_bolt.rotation_degrees = bolt_spawn_position_nodes[current_bolt_rank - 1].rotation_degrees# - 90 # ob rotaciji 0 je default je obrnjen navzgor
#	new_bolt.global_position = spawn_position_node.global_position
#	new_bolt.rotation_degrees = spawn_position_node.rotation_degrees# - 90 # ob rotaciji 0 je default je obrnjen navzgor
	new_bolt.player_stats = spawned_bolt_stats
	
#	new_bolt.player_stats = Pro.default_player_stats.duplicate()

#	if current_level_index > 0 and not qualified_bolts.empty(): 
#		# če je bolt_id enak trenutno spawnanemu mu podam pripadajočo statistiko
#		for qualified_bolt in qualified_bolts: # bolt_id, player_stats
##			print ("qualified_bolt", qualified_bolt[0],qualified_bolt[1])
#			if qualified_bolt[0] == spawned_bolt_id:
#				new_bolt.player_stats = qualified_bolt[1]
#	else: # prvi level > default statsi
#		new_bolt.player_stats = Pro.default_player_stats.duplicate()
#
		
	Ref.node_creation_parent.add_child(new_bolt)
	
	# new_bolt.look_at(Vector2(320,180)) # rotacija proti centru ekrana
	# new_bolt.set_physics_process(false)
	
	# signali
	new_bolt.connect("bolt_activity_changed", self, "_on_Bolt_activity_changed")
	if new_bolt.is_in_group(Ref.group_enemies):
		new_bolt.navigation_cells = navigation_area
		new_bolt.connect("path_changed", self, "_on_Enemy_path_changed") # samo za prikaz nav linije
#		emit_signal("new_bolt_spawned", spawned_bolt_id, spawned_bolt_index) # pošljem na hud, da prižge stat line in ga napolne
	if new_bolt.is_in_group(Ref.group_players):
		new_bolt.connect("stat_changed", Ref.hud, "_on_stat_changed") # statistika med boltom in hudom
#		emit_signal("new_bolt_spawned", spawned_bolt_id, spawned_bolt_index) # pošljem na hud, da prižge stat line in ga napolne
#	emit_signal("new_bolt_spawned", spawned_bolt_id, spawned_bolt_stats) # pošljem na hud, da prižge stat line in ga napolne
	emit_signal("new_bolt_spawned", new_bolt) # pošljem na hud, da prižge stat line in ga napolne
	# Ref.current_camera.follow_target = new_bolt
	
	Ref.current_camera.follow_target = new_bolt # začasen holder, ki se obdrži, če se ob štartu ne seta posebej (racing se ...) 
	bolts_on_start.append(new_bolt)


func spawn_pickable():
	
	if available_pickable_positions.empty():
		return
	
	if pickables_in_game.size() <= Ref.game_manager.game_settings["pickables_count_limit"] - 1:
		# žrebanje tipa
		var pickables_for_selection: Array
		for pickable in Pro.pickable_profiles:
			if Pro.pickable_profiles[pickable]["for_random_selection"]:
				pickables_for_selection.append(pickable)
		var random_pickables_key: String = Met.get_random_member(pickables_for_selection)
		var random_pickable_path = Pro.pickable_profiles[random_pickables_key]["scene_path"]
		# žrebanje pozicije
		var random_cell_position: Vector2 = Met.get_random_member(navigation_positions)
		# spawn
		var new_pickable = random_pickable_path.instance()
		new_pickable.global_position = random_cell_position
		add_child(new_pickable)
		# odstranim celico iz arraya tistih na voljo
		var random_cell_position_index: int = available_pickable_positions.find(random_cell_position)
		available_pickable_positions.remove(random_cell_position_index)		

	# random timer reštart
	var random_pickable_spawn_time: int = Met.get_random_member([1,2,3])
	yield(get_tree().create_timer(random_pickable_spawn_time), "timeout") # za dojet
	spawn_pickable()

	
#func spawn_level_():
#
#	var level_position: Position2D = $"../LevelPosition"
#	var level_z_index: int # z index v node drevesu
#
#	if not Ref.current_level == null: # če level že obstaja, ga najprej moram zbrisat
#		#var level_to_load_path: String = level_settings["level_path"]
#		level_z_index = Ref.current_level.z_index
#		Ref.current_level.set_physics_process(false)
#		Ref.current_level.free()
#	else: # če je samo level marker
#		level_z_index = level_position.z_index
#
#	# spawn level
#	# var Level = ResourceLoader.load(level_to_load_path)
#	# var new_level = Level.instance()
#	var new_level = NewLevel.instance()
#	new_level.z_index = level_z_index
#	new_level.connect( "level_is_set", self, "_on_level_is_set") # nujno pred add child, ker ga level sproži že na ready
#	Ref.node_creation_parent.add_child(new_level)

		
# RANKING ---------------------------------------------------------------------------------------------

	
func get_bolts_ranking():
	# najbližje točke vseh boltov primerjam (po indexu na vodilni racing liniji) 
	## problem ... trenutnega načina je da rangira plejerje glede na index točke znotraj njene linije
	## rad bi ... ko vodilni plejer zamenja linijo se le-ta zamenja
	## rešitev ... ko enkrat vem kdo je leading plejer, moram rangirat samo glede na njegovo linijo
	
	# vodilna racing linija
	if leading_racing_line == null:
		leading_racing_line = level_racing_lines[0] # na začetku je vedno ta glavna linija, kasneje se opredeli glede na vodilnega plejerja
					
	# VSI BOLTI
	# sortam arraj po indexu pike na vodilni liniji ... 0 ... bolt, 1 ... closest_racing_line_point_index, 2 ...closest_racing_line_index
	var all_bolts_on_racing_line: Array = get_racing_line_bolts() # array ima bolta, index najbližje točke na svoji liniji, točko (global position) in index linije
	all_bolts_on_racing_line.sort_custom(self, "sort_bolts_by_point_index")
	# razvrstim po prevoženih krogih
	all_bolts_on_racing_line.sort_custom(self, "sort_bolts_by_laps")
	
#	var all_bolts_ranked: Array
#	for bolt_on_ = all_bolts_on_racing_line
#	all_bolts_ranked = all_bolts_on_racing_line
#	for bolt in all_bolts_ranked:
#		var bolt_rank: int = all_bolts_ranked.find(bolt) + 1
#		if not bolt.level_rank == bolt_rank: 
#			bolt.level_rank = bolt_rank
	
	# VODILNI BOLT
	var leading_bolt_on_racing_line: Array = all_bolts_on_racing_line[0]
	var leading_racing_point_index: int = leading_bolt_on_racing_line[1]
	var leading_bolt: KinematicBody2D = leading_bolt_on_racing_line[0]
	# player ali enemy
	var players_on_racing_line: Array
	var enemies_on_racing_line: Array
	for bolt_on_racing_line in all_bolts_on_racing_line:
		# set bolt ranking
#		bolt_on_racing_line[0].current_race_ranking = all_bolts_on_racing_line.find(bolt_on_racing_line) + 1
		bolt_on_racing_line[0].level_rank = all_bolts_on_racing_line.find(bolt_on_racing_line) + 1
		# če je plejer ga dodam me plejerje
		if bolt_on_racing_line[0].is_in_group(Ref.group_players) and bolt_on_racing_line[0].bolt_active:
			players_on_racing_line.append(bolt_on_racing_line)
		elif bolt_on_racing_line[0].is_in_group(Ref.group_enemies) and bolt_on_racing_line[0].bolt_active:
			enemies_on_racing_line.append(bolt_on_racing_line)
			
	# ENEMIES ... setam nav target
	# enemy racing line je vedno glavni racing line
	# razen če si linije sledijo in glavne ni več, potem je naslednja (stil 8 recimo)
	# če je nov krog je glavna linija spet prva
	for enemy_on_racing_line in enemies_on_racing_line:
		var enemy_racing_line_point: Vector2 = level_racing_lines[enemy_racing_line_index].get_points()[enemy_on_racing_line[1]]
		var enemy_racing_line_point_index: int = level_racing_lines[enemy_racing_line_index].get_points().find(enemy_racing_line_point)
		# če je na koncu linije trenutne linije, premaknem na naslednjo
		if enemy_racing_point_offset < 15: # arbitrarna meja, da je zazih
			# če je trenutna linija zadnja, je naslednja spet prva
			if enemy_racing_line_index == level_racing_lines.size() - 1:
				enemy_racing_line_index = 0
				enemy_racing_point_offset = default_enemy_racing_point_offset
			# če ni zadnja (in ni na cilju)... premaknem na naslednjo linijo 
			else:
				enemy_racing_line_index += 1
				enemy_racing_point_offset = default_enemy_racing_point_offset # reset offseta
		# če je pika znotraj obsega minus offset, ji dodajam predikcijo
		elif enemy_racing_line_point_index < level_racing_lines[enemy_racing_line_index].get_points().size() - enemy_racing_point_offset:
			var enemy_racing_line_offset_point: Vector2 = level_racing_lines[enemy_racing_line_index].get_points()[enemy_on_racing_line[1] + enemy_racing_point_offset]
			enemy_on_racing_line[0].navigation_target_position = enemy_racing_line_offset_point
		# če ni, offset zmanjšam ... tako se na pride na 0
		else:
			enemy_racing_point_offset -= 1
		
	# PLAYERS ... setam vodilnega, vodilno linijo in tarčo kamere
	# če so vsi neaktivni, lokacija kamere ostane ista
	if players_on_racing_line.empty(): 
		Ref.current_camera.follow_target = null
	else:
		var leading_player_on_racing_line: Array = players_on_racing_line[0] # players_on_racing_line so že rangirani zato je 0 prvi
		leading_player = leading_player_on_racing_line[0]
		leading_racing_line = level_racing_lines[leading_player_on_racing_line[2]]
		
		# debug ... indikator
		if Set.debug_mode:
#		if level_settings["level"] == Set.Levels.DEBUG_RACE:
			var leading_point_index: int = leading_player_on_racing_line[1]
			var leading_point: Vector2 = level_racing_points[leading_point_index]
			position_indikator.global_position = leading_point
			position_indikator.scale = Vector2(3,3)
			position_indikator.modulate = leading_player.bolt_color
		# camera follow
			#if not Ref.current_camera.follow_target == position_indikator: # da kamera ne reagira, če je že setan isti plejer
			#	Ref.current_camera.follow_target = position_indikator
		if not Ref.current_camera.follow_target == leading_player: # da kamera ne reagira, če je že setan isti plejer
			Ref.current_camera.follow_target = leading_player
	

func sort_bolts_by_laps(bolt_on_racing_line_1, bolt_on_racing_line_2): # ascending ... večji index je boljši
	
	if bolt_on_racing_line_1[0].laps_finished_count > bolt_on_racing_line_2[0].laps_finished_count:
	    return true
	return false
	
	
func sort_bolts_by_point_index(bolt_on_racing_line_1, bolt_on_racing_line_2): # ascending ... večji index je boljši
	
	if bolt_on_racing_line_1[1] > bolt_on_racing_line_2[1]:
	    return true
	return false


func get_racing_line_bolts():
	# za vsakega aktivnega bolta naberem najbližje točke na racing liniji 
	# za vodilnega preverjam vse racing linije
	# za ostale preverjam samo pozicijo na racing liniji

	var bolts_on_racing_line: Array	# paketi podatkov o boltu in njegovi pozicij na racing liniji	
	
	# najprej čekiram najbližje točke za vsakega na progi
	for bolt in bolts_in_game:
		
		# med točkami na vseh racing linijah poiščem najbližjo
		var shortest_distance: float = 0
		var closest_racing_line_point: Vector2
		var closest_racing_line: Line2D
				
		# VODILNI MED PLEJER ... preverjam vse racing linije
		if bolt == leading_player:
			for racing_line in level_racing_lines:
				# naberem razdalje vseh točk do bolta
				for line_point in racing_line.get_points():
					var distance_to_point: float = bolt.global_position.distance_to(line_point)
					# če je prva distance jo štejem in zapišem lokacijo točke na liniji
					if shortest_distance == 0:
						shortest_distance = distance_to_point
						closest_racing_line_point = line_point
						closest_racing_line = racing_line
					# če je nižja od trenutne jo zamenjam in zapišem lokacijo točke na liniji
					elif distance_to_point < shortest_distance:
						shortest_distance = distance_to_point
						closest_racing_line_point = line_point
						closest_racing_line = racing_line 
				# na koncu imam vodilnemu boltu najbližjo točko in njeno linijo
				# opredelim najbližjo linijo kot vodilno
				leading_racing_line = closest_racing_line
		# ENEMY ... preverjam glavno linijo in potem vse, ki sledijo
		elif bolt.is_in_group(Ref.group_enemies):	
			for line_point in level_racing_lines[enemy_racing_line_index].get_points():
				var distance_to_point: float = bolt.global_position.distance_to(line_point)
				# če je prva distance jo štejem in zapišem lokacijo točke na liniji
				if shortest_distance == 0:
					shortest_distance = distance_to_point
					closest_racing_line_point = line_point
					closest_racing_line = leading_racing_line # nepotrebna vrstica ... da lahko kaj dam v boltov array na koncu
				# če je nižja od trenutne jo zamenjam in zapišem lokacijo točke na liniji
				elif distance_to_point < shortest_distance:
					shortest_distance = distance_to_point
					closest_racing_line_point = line_point
					closest_racing_line = leading_racing_line # nepotrebna vrstica ... da lahko kaj dam v boltov array na koncu						
		# NEVODILNI MED PLEJERJI ... preverjam samo linijo vodilnega	
		else:
			for line_point in leading_racing_line.get_points():
				var distance_to_point: float = bolt.global_position.distance_to(line_point)
				# če je prva distance jo štejem in zapišem lokacijo točke na liniji
				if shortest_distance == 0:
					shortest_distance = distance_to_point
					closest_racing_line_point = line_point
					closest_racing_line = leading_racing_line # nepotrebna vrstica ... da lahko kaj dam v boltov array na koncu
				# če je nižja od trenutne jo zamenjam in zapišem lokacijo točke na liniji
				elif distance_to_point < shortest_distance:
					shortest_distance = distance_to_point
					closest_racing_line_point = line_point
					closest_racing_line = leading_racing_line # nepotrebna vrstica ... da lahko kaj dam v boltov array na koncu
		
		# na koncu (nujno) sestavim bolt_on_racing_line .. bolt, index najbližje točke, index linije v level racing linijah
		var closest_racing_line_point_index: int 
		var closest_racing_line_index: int	
		if bolt.is_in_group(Ref.group_players):
			closest_racing_line_point_index = level_racing_points.find(closest_racing_line_point)
			closest_racing_line_index = level_racing_lines.find(closest_racing_line)
		elif bolt.is_in_group(Ref.group_enemies):
			closest_racing_line_point_index = level_racing_lines[enemy_racing_line_index].get_points().find(closest_racing_line_point)
			closest_racing_line_index = enemy_racing_line_index
					
		var bolt_on_racing_line: Array = [bolt, closest_racing_line_point_index, closest_racing_line_index] # 0 ... bolt, 1 ... closest_racing_line_point_index, 2 ...closest_racing_line_index
		bolts_on_racing_line.append(bolt_on_racing_line)
	
	return bolts_on_racing_line


func get_bolt_pull_position(bolt_to_pull: KinematicBody2D):
#	printt ("current_pull_positions",current_pull_positions.size())
	# na koncu izbrana pull pozicija:
	# - je na območju navigacije
	# - upošteva razdaljo do vodilnega
	# - se ne pokriva z drugim plejerjem	
	
	if game_on:
		
		# pull pozicija brez omejitev
		var pull_position_distance_from_leader: float = 10 # pull razdalja od vodilnega plejerja  
		var pull_position_distance_from_leader_correction: float = 20 # pull razdalja od vodilnega plejerja glede na index med trenutno pulanimi
		var vector_to_leading_player: Vector2 = leading_player.global_position - bolt_to_pull.global_position
		var vector_to_pull_position: Vector2 = vector_to_leading_player - vector_to_leading_player.normalized() * pull_position_distance_from_leader
		var bolt_pull_position: Vector2 = bolt_to_pull.global_position + vector_to_pull_position
		
		# implementacija omejitev, da ni na steni ali elementu ali drugemu plejerju
		var navigation_position_as_pull_position: Vector2
		var available_navigation_pull_positions: Array
		var bolt_areas: Array = current_bolt_areas()
		
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
					if cell_position.distance_to(leading_player.global_position) > pull_position_distance_from_leader:
						# preverim, da pozicija ni že zasedena
						# preverim, da pozicija ni že zasedena
						# če poza ni zasedena ga dodaj med zasedene
						if not current_pull_positions.has(cell_position):
							navigation_position_as_pull_position = cell_position
						else: # če je poza zasedena dobim njen in dex med zasedenimi dodam korekcijo na zahtevani razdalji od vodilnega
							var pull_pos_index: int = current_pull_positions.find(cell_position)
							var corrected_pull_position = pull_position_distance_from_leader + pull_pos_index * pull_position_distance_from_leader_correction
							if cell_position.distance_to(leading_player.global_position) > corrected_pull_position:
#								current_pull_positions.append(cell_position)
								navigation_position_as_pull_position = cell_position

		current_pull_positions.append(navigation_position_as_pull_position)
		return navigation_position_as_pull_position
		
		
func current_bolt_areas():
	
	var current_bolt_areas: Array 
	for bolt in bolts_in_game:
		var bolt_sprite_rectangle: Rect2 = bolt.bolt_sprite.get_rect()
		bolt_sprite_rectangle.position += Vector2(-20,-20)
		bolt_sprite_rectangle.size += Vector2(40,40)
		var bolt_sprite_area: Rect2 = Rect2(bolt.global_position + bolt_sprite_rectangle.position, bolt_sprite_rectangle.size)
		current_bolt_areas.append(bolt_sprite_area)
	return current_bolt_areas
	
	
# PRIVAT ----------------------------------------------------------------------------------------------------


func _on_Bolt_activity_changed(bolt: KinematicBody2D):
	
	if bolt.bolt_active == false:
		check_for_level_completed()

	
func _on_level_is_set(level_positions_nodes: Array, tilemap_navigation_cells: Array, tilemap_navigation_cells_positions: Array, level_checkpoints_count: int):
	
	# navigacija za enemy AI
	navigation_area = tilemap_navigation_cells
	navigation_positions = tilemap_navigation_cells_positions
	
	# random pickable pozicije 
	available_pickable_positions = navigation_area.duplicate()
	
	# racing linije
	level_racing_lines = Ref.current_level.racing_line.draw_racing_lines()
	for line in level_racing_lines:
		level_racing_points.append_array(line.get_points())
		
	# pozicije
	bolt_spawn_position_nodes = level_positions_nodes
	level_start_position = level_positions_nodes.pop_front().global_position
	level_goal_position = level_positions_nodes.pop_back().global_position # vedno zadnja v arrayu
	
	# kamera
	Ref.current_camera.position = level_start_position
	Ref.current_camera.set_camera_limits()	
	
	# čekpointi
	checkpoints_per_lap = level_checkpoints_count
	
	# debug
	if Set.debug_mode and position_indikator == null:
		position_indikator = Met.spawn_indikator(bolt_spawn_position_nodes[1].global_position, 0)


# SIGNALI ----------------------------------------------------------------------------------------------------


func _on_Enemy_path_changed(path: Array) -> void: # za prikaz linije
	# ta funkcija je vezana na signal bolta
	# inline connect za primer, če je bolt spawnan
	# def signal connect za primer, če je bolt "in-tree" node
	
	navigation_line.points = path


func _on_ScreenArea_body_exited(body: Node) -> void:
	
	# player pull	
	if game_settings["race_mode"]:
		if body.is_in_group(Ref.group_players):
			var bolt_pull_position: Vector2 = get_bolt_pull_position(body)
			var leader_laps_finished_count: int = leading_player.laps_finished_count
			var leader_checkpoints_reached: Array = leading_player.checkpoints_reached
			body.call_deferred("pull_bolt_on_screen", bolt_pull_position, leader_laps_finished_count, leader_checkpoints_reached)
	
	if body.is_in_group(Ref.group_bolts):
		if not body.bolt_active:
			body.call_deferred("set_physics_process", false)
	elif body is Bullet:
		body.on_out_of_screen() # ta funkcija zakasni učinek
	# elif body is Misile: ... ima timer in se sama kvefrija ... misila se lahko vrne v ekran (nitro)
		
