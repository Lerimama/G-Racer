extends Node


signal stat_change_received (player_index, changed_stat, stat_new_value)
signal new_bolt_spawned (name, other)

var game_on: bool

var bolts_in_game: Array
var pickables_in_game: Array

# game
var game_settings: Dictionary # = Set.default_game_settings # ga med igro ne spreminjaš
var current_bolts_activated_ids: Array # naslednji leveli se tole adaptira, glede na to kdo je še v igri

# level 
var level_settings: Dictionary
var current_game_level_index: int = 0
var available_pickable_positions: Array # za random spawn
var level_goal_position: Vector2
var level_start_position: Vector2
var level_bolt_position_nodes: Array # dobi od tilemapa
var free_bolt_position_nodes: Array # za dodajanje na prave pozicije
var navigation_area: Array # vsi navigation tileti
var navigation_positions: Array # pozicije vseh navigation tiletov

# racing
var leading_player: KinematicBody2D # trenutno vodilni igralec (rabim za camera target in pull target)
var leading_racing_line: Line2D	
var level_racing_lines: Array 
var level_racing_points: Array # pike vseh linij
var bolts_across_finish_line: Array # bolti v cilju
var qualified_bolts: Array # za naslednji level
var fast_start_window: bool = false # bolt ga čekira in reagira

# ai
var enemy_racing_line_index: int = 0
var default_enemy_racing_point_offset: int = 20 # da lahko resetiram
var enemy_racing_point_offset: int = 20 # prediction points length ... vpliva na natančnost gibanja

# neu
#var intro = true
var checkpoints_per_lap: int
var current_pull_positions: Array # že zasedene pozicije za preventanje nalaganja bolto druga na drugega
var enemy_finish_time_addon: float = 32
# debug
var position_indikator: Node2D	
onready var game_cover: Control = $"../UI/GameCover"
onready var level_finished_ui: Control = $"../UI/LevelFinished"
onready var game_over_ui: Control = $"../UI/GameOver"
var level_start_position_node: Position2D
var level_goal_position_node: Position2D

func _input(event: InputEvent) -> void:
	
	
#	if Input.is_action_just_pressed("m"):
#		var bus_index: int = AudioServer.get_bus_index("GameMusic")
#		var bus_is_mute: bool = AudioServer.is_bus_mute(bus_index)
#		AudioServer.set_bus_mute(bus_index, not bus_is_mute)
			
	if Input.is_action_just_pressed("r"):
		level_finished(true)
	
	if Input.is_action_just_pressed("x"):
		for bolt in bolts_in_game:
			if bolt.is_in_group(Ref.group_players):
				bolt.gas_count = 0
			

func _ready() -> void:
	printt("GM")
	Ref.game_manager = self	
	Ref.current_level = null # da deluje reštart
	
	# intro:
	game_cover.show()
	game_cover.modulate = Color.white

	call_deferred("set_game")


func _process(delta: float) -> void:
	
	bolts_in_game = get_tree().get_nodes_in_group(Ref.group_bolts)
	pickables_in_game = get_tree().get_nodes_in_group(Ref.group_pickables)	

#	if game_on: 
	if game_settings["race_mode"]:
		get_bolts_ranking()
	
	
func set_game():
	
	# debug
#	if Set.debug_mode:
#	#	Set.current_game_levels = []
#	#	Set.current_game_levels = [Levels.RACE_8]
#	#	Set.current_game_levels = [Levels.RACE_SNAKE]
#	#	Set.current_game_levels = [Levels.RACE_DIRECT, Levels.RACE_SNAKE]
#		Set.current_game_levels = [Set.Levels.RACE_ROUND, Set.Levels.RACE_DIRECT]
		
	game_settings = Set.get_level_game_settings(current_game_level_index)
	
	spawn_level()
	
	Ref.hud.set_hud()
	Ref.node_creation_parent.get_parent().camera_screen_area.connect( "body_exited_screen", self, "_on_body_exited_screen")
	Ref.current_camera.follow_target = level_start_position_node
		
	if current_game_level_index == 0 and not Set.players_on_game_start.empty():
		current_bolts_activated_ids = Set.players_on_game_start
	elif current_game_level_index == 0 and Set.players_on_game_start.empty(): # debug ... kadar ne štartam igre iz home menija
#		current_bolts_activated_ids = [Pro.Bolts.P1] 
		current_bolts_activated_ids = [Pro.Bolts.P1, Pro.Bolts.P2] 	
#		current_bolts_activated_ids = [Pro.Bolts.P1, Pro.Bolts.ENEMY] 
#		current_bolts_activated_ids = [Pro.Bolts.P1, Pro.Bolts.ENEMY, Pro.Bolts.P2 ] 
#		current_bolts_activated_ids = [Pro.Bolts.P1, Pro.Bolts.P2,Pro.Bolts.ENEMY, Pro.Bolts.ENEMY] 
#		current_bolts_activated_ids = [Pro.Bolts.P1, Pro.Bolts.P2, Pro.Bolts.P3, Pro.Bolts.P4]
	# resetiram aktivirane ID in jim dodam kvalificirane bolt_id
	elif current_game_level_index > 0 and not qualified_bolts.empty():
		current_bolts_activated_ids.clear()
		printt ("Q2", qualified_bolts)
		for bolt in qualified_bolts:
			current_bolts_activated_ids.append(bolt.bolt_id)
	
	game_settings["enemies_mode"] = true
	# za vsako prazno pozicijo dodam enemy bolt_id 			
	if game_settings["enemies_mode"]: # začasno vezano na Set. filet
		var empty_positions_count = level_bolt_position_nodes.size() - current_bolts_activated_ids.size()
		for empty_position in empty_positions_count:
			current_bolts_activated_ids.append(Pro.Bolts.ENEMY) # da prepoznam v spawn funkciji .... trik pač
	
	
	printt("ID", current_bolts_activated_ids)
	var spawned_position_index = 0
	for bolt_id in current_bolts_activated_ids: # so v ranking zaporedju
		spawn_bolt(bolt_id, spawned_position_index) # scena, pozicija, profile id (barva, ...)
		# ko so spoawnani vsi bolti
		# intro:
		if spawned_position_index < current_bolts_activated_ids.size():
			spawned_position_index += 1
		if spawned_position_index == current_bolts_activated_ids.size():
			game_intro()
#		print("IND", spawned_position_index)
#		else:
#			spawned_position_index += 1
#	if not intro:
#		start_game()
	
	
func game_intro():
	
	var fade_time = 1
	var fade_in_tween = get_tree().create_tween()
	fade_in_tween.tween_property(game_cover, "modulate:a", 0, fade_time).set_delay(1) # delay, da se kamera naštima	
	yield(fade_in_tween, "finished")
	game_cover.hide()
	
	yield(get_tree().create_timer(1),"timeout") # za dojet
	
	var drive_in_time: float = 2
	var drive_index: int = 0 # da ugotovim, kdaj so vsi zapeljani
	var drive_in_distance: float = 50 # da ugotovim, kdaj so vsi zapeljani
	for bolt in bolts_in_game:
		# bolt.bolt_collision.set_disabled(true) # da ga ne moti morebitna stena
		var orig_position: Vector2 = bolt.global_position
		bolt.global_position -= drive_in_distance * bolt.transform.x
		bolt.modulate.a = 1
		bolt.current_motion_state = bolt.MotionStates.FWD # za fx
		bolt.start_engines()
		var intro_drive_tween = get_tree().create_tween()
		intro_drive_tween.tween_property(bolt, "global_position", orig_position, drive_in_time).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
		# intro_drive_tween.tween_callback(bolt.bolt_collision, "set_disabled", [false])
		# še kakšen drive?
		drive_index += 1
		# če je zadnji drive počakam, da se drive konča in potem zaženem igro
		if drive_index == bolts_in_game.size():
			yield(intro_drive_tween, "finished")
			start_game()


func start_game():
	
	# start countdown	
	Ref.current_level.start_lights.start_countdown() # če je skrit, pošlje signal takoj
	yield(Ref.current_level.start_lights, "countdown_finished")	
	
	# start
	for bolt in bolts_in_game:
#		if not bolt.is_in_group(Ref.group_enemies):
			bolt.bolt_active = true
	Ref.sound_manager.play_music()
	Ref.hud.on_game_start()
	if not game_settings["race_mode"]:
		spawn_pickable() # začetek random spawnanja
	
	game_on = true
	
	# fast start
	fast_start_window = true	
	yield(get_tree().create_timer(0.32), "timeout") # za dojet
	fast_start_window = false	
		

func level_finished(level_goal_reached: bool):
	
	
#	print("LP", level_goal_position, Ref.current_camera.follow_target)	
#	Ref.current_camera.follow_target = null
	Ref.current_camera.follow_target = level_goal_position_node
	
	if game_on == false: # preprečim double gameover
		return
	game_on = false

	Ref.hud.on_level_finished()
	
	yield(get_tree().create_timer(2), "timeout") # za dojet
	
	if level_goal_reached and current_game_level_index < (Set.current_game_levels.size() - 1):
		printt("Level SUCCESS", bolts_across_finish_line.size())
		# če ni v cilju, ga dodam me tiste v cilju
		# enemija uvrstim in mu fejkam čas 
		# plejerja uvrstim če je izi mode 
		var last_finished_time: float # da lahko fajkem za enemija
		for bolt in bolts_in_game:
			if bolts_across_finish_line.has(bolt): # na koncu je time od zadnjega še uvrščenega
				last_finished_time = bolt.level_finished_time
			elif not bolts_across_finish_line.has(bolt):
				if bolt.is_in_group(Ref.group_enemies):	
					bolt.level_finished_time = last_finished_time + enemy_finish_time_addon
					bolts_across_finish_line.append(bolt)
				elif game_settings["easy_mode"] and bolt.is_in_group(Ref.group_players):	
					bolts_across_finish_line.append(bolt)
		# vsi čez finiš line so kvalificirani
		qualified_bolts = bolts_across_finish_line
		yield(get_tree().create_timer(2), "timeout") # za dojet
		# cover fejd
		var fade_time = 1
		var fade_in_tween = get_tree().create_tween()
		fade_in_tween.tween_callback(game_cover, "show")
		fade_in_tween.tween_property(game_cover, "modulate:a", 1, fade_time)	
		yield(fade_in_tween, "finished")
		# open level_screen
		level_finished_ui.open(bolts_across_finish_line, bolts_in_game)
#		Ref.level_completed.open(bolts_across_finish_line, bolts_in_game)
	else:
		# cover fejd
		var fade_time = 1
		var fade_in_tween = get_tree().create_tween()
		fade_in_tween.tween_callback(game_cover, "show")
		fade_in_tween.tween_property(game_cover, "modulate:a", 1, fade_time)	
		yield(fade_in_tween, "finished")
		print("Level FAIL")
		game_over_ui.open_gameover(bolts_across_finish_line, bolts_in_game)
#		Ref.game_over.open_gameover(bolts_across_finish_line, bolts_in_game)
	
	for bolt in bolts_in_game: 
		# player se deaktivira, ko mu zmanjka bencina (in ko gre čez cilj)
		# enemy se deaktivira, ko gre čez cilj ... in tukaj
		if bolt.bolt_active:
			bolt.bolt_active = false
			bolt.set_physics_process(false)
			
	# music stop
	Ref.sound_manager.stop_music()
	# sfx mute
	var bus_index: int = AudioServer.get_bus_index("GameSfx")
	AudioServer.set_bus_mute(bus_index, true)
	
	# best lap stats reset
	# looping sounds stop
	# navigacija enemyja
	# kvefri elementov, ki so v areni
	
	
func set_next_level():

	current_game_level_index += 1
	
	# manage bolts
	for bolt in bolts_in_game:
		# odstrani nekvalificirane bolte iz aktiviranih
		if not qualified_bolts.has(bolt):
			current_bolts_activated_ids.erase(bolt.bolt_id)
#		bolt.queue_free() # aktivirane respawnam 
	printt("current_bolts_activated_ids", current_bolts_activated_ids)		
	# unmute sfx 
	if not Ref.sound_manager.sfx_set_to_mute:
		var bus_index: int = AudioServer.get_bus_index("GameSfx")
		AudioServer.set_bus_mute(bus_index, false)
	
	# zbrišem vse otroke v NCP (bolti, orožja, efekti, ...)
	var all_children: Array = Ref.node_creation_parent.get_children()
	for child in all_children:
		child.queue_free()

	# reset level values
	leading_player = null # trenutno vodilni igralec (rabim za camera target in pull target)
	leading_racing_line = null
	level_racing_lines = [] 
	level_racing_points = []
	bolts_across_finish_line = []
	position_indikator = null
	
	set_game()
			
			
func check_for_level_finished(): # za preverjanje pogojev za game over (vsakič ko bolt spreminja aktivnost)
	
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

		
func on_finish_line_crossed(bolt_finished: KinematicBody2D): # sproži finish line
	
	if not game_on: # preventam, da gre čez črto ko je konec igre
		return
		
	var time_to_finish: float = 2 # čas za druge, da dosežejo cilj
	var current_race_time: float  = Ref.hud.game_timer.absolute_game_time # pozitiven game čas v sekundahF
	
	# LAP FINISHED
	if checkpoints_per_lap > 0: # temp rešitev
		checkpoints_per_lap = 1
	if bolt_finished.checkpoints_reached.size() >= checkpoints_per_lap:
		bolt_finished.on_lap_finished(current_race_time, level_settings["lap_limit"])
		Ref.sound_manager.play_sfx("finish_horn")
	
	# RACE FINISHED
	if bolt_finished.laps_finished_count >= level_settings["lap_limit"]:
		# če je izpolnil število krogov, ga pripnem, ki tistim ki so končali 
		bolts_across_finish_line.append(bolt_finished) # pripnem šele tukaj, da lahko prej čekiram, če je prvi plejer
		bolt_finished.bolt_stats["level_finished_time"] = current_race_time
		# deaktiviram plejerja in zabležim statistiko 
		bolt_finished.bolt_active = false
		# drive out
		bolt_finished.current_motion_state = bolt_finished.MotionStates.FWD # za fx
		var level_finish_line = Ref.current_level.finish_line
		var drive_out_distance: float = level_finish_line.drive_out_distance # črta v finish line 
		var drive_out_rotation: float = level_finish_line.get_rotation_degrees() - 90
		var drive_out_position: Vector2 = bolt_finished.global_position - drive_out_distance * level_finish_line.transform.y
		var drive_out_time: float = 2
		var drive_out_tween = get_tree().create_tween()
		drive_out_tween.tween_property(bolt_finished, "global_position", drive_out_position, drive_out_time).set_ease(Tween.EASE_IN)#.set_trans(Tween.TRANS_CUBIC)
		drive_out_tween.parallel().tween_property(bolt_finished, "rotation_degrees", drive_out_rotation, drive_out_time/5)
		drive_out_tween.parallel().tween_callback(bolt_finished.bolt_collision, "set_disabled", [true])
		drive_out_tween.tween_property(bolt_finished, "modulate:a", 0, drive_out_time) # če je krožna dirka in ne gre iz ekrana


# SPAWNING ---------------------------------------------------------------------------------------------


func spawn_level():
	
	# level name (iz seznama levelov v igri)
	var level_to_load_id: int = Set.current_game_levels[current_game_level_index]
	# level settings
	level_settings = Set.level_settings[level_to_load_id]
	var level_to_load_path: String = level_settings["level_path"]
	
	var level_z_index: int # z index v node drevesu
	if not Ref.current_level == null: # če level že obstaja, ga najprej moram zbrisat
		level_z_index = Ref.current_level.z_index
		Ref.current_level.set_physics_process(false)
		Ref.current_level.free()
	else: # če je samo level marker
		level_z_index = Ref.node_creation_parent.get_parent().level_placeholder.z_index
#		level_z_index = Ref.node_creation_parent.get_node("LevelPosition").z_index
		
	# spawn level
	var NewLevel: PackedScene = ResourceLoader.load(level_to_load_path)
	var new_level = NewLevel.instance()
	new_level.z_index = level_z_index
	new_level.connect( "level_is_set", self, "_on_level_is_set") # nujno pred add child, ker ga level sproži že na ready
#	printt("level_to_load_path", level_to_load_path, level_settings, Ref.node_creation_parent)
	Ref.node_creation_parent.get_parent().add_child(new_level)	
	
	
func spawn_bolt(spawned_bolt_id: int, spawned_position_index: int):
	
	var NewBolt: PackedScene = Pro.player_profiles[spawned_bolt_id]["player_scene"]
	var spawned_bolt_stats: Dictionary # za prenos v spawnanega
	
	# ni prvi level
	if current_game_level_index > 0:
		if not qualified_bolts.empty(): # najprej se spawnajo kvalificirani
			for bolt in qualified_bolts:
				if bolt.bolt_id == spawned_bolt_id:
					spawned_bolt_stats = bolt.bolt_stats
					qualified_bolts.pop_front()
					break
#			spawned_bolt_stats = qualified_bolts[0].bolt_stats
#			qualified_bolts.pop_front()
		else: # potem pa še enemy spawn na prazne pozicije
			spawned_bolt_stats = Pro.default_bolt_stats.duplicate()	
	else: # prvi level
		spawned_bolt_stats = Pro.default_bolt_stats.duplicate()	
		
	# bolt stats setup
	#	game_settings["full_equip_mode"] = true
	if game_settings["race_mode"]: # izpraznem orožje
		spawned_bolt_stats["bullet_count"] = 0
		spawned_bolt_stats["misile_count"] = 0
		spawned_bolt_stats["mina_count"] = 0
		spawned_bolt_stats["shocker_count"] = 0
	if game_settings["full_equip_mode"]:
		spawned_bolt_stats["bullet_count"] = 100
		spawned_bolt_stats["misile_count"] = 100
		spawned_bolt_stats["mina_count"] = 100
		spawned_bolt_stats["shocker_count"] = 100		
	
	var new_bolt = NewBolt.instance()
	new_bolt.bolt_id = spawned_bolt_id
	new_bolt.bolt_stats = spawned_bolt_stats
	new_bolt.modulate.a = 0 # intro
	new_bolt.rotation_degrees = level_bolt_position_nodes[spawned_position_index].rotation_degrees# - 90 # ob rotaciji 0 je default je obrnjen navzgor
	new_bolt.global_position = level_bolt_position_nodes[spawned_position_index].global_position
	Ref.node_creation_parent.add_child(new_bolt)
	
	
	# signali
	new_bolt.connect("bolt_activity_changed", self, "_on_bolt_activity_changed")
	if new_bolt.is_in_group(Ref.group_enemies):
		new_bolt.navigation_cells = navigation_area
		new_bolt.connect("path_changed", self, "_on_enemy_path_changed") # samo za prikaz nav linije
	if new_bolt.is_in_group(Ref.group_players):
		new_bolt.connect("stat_changed", Ref.hud, "_on_stat_changed") # statistika med boltom in hudom
		#		Ref.current_camera.follow_target = new_bolt # začasen holder, ki se obdrži, če se ob štartu ne seta posebej (racing se ...) 
	emit_signal("new_bolt_spawned", new_bolt) # pošljem na hud, da prižge stat line in ga napolne
	

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
		Ref.node_creation_parent.add_child(new_pickable)
		# odstranim celico iz arraya tistih na voljo
		var random_cell_position_index: int = available_pickable_positions.find(random_cell_position)
		available_pickable_positions.remove(random_cell_position_index)		

	# random timer reštart
	var random_pickable_spawn_time: int = Met.get_random_member([1,2,3])
	yield(get_tree().create_timer(random_pickable_spawn_time), "timeout") # za dojet
	spawn_pickable()

	
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
	
	# VODILNI BOLT
	var leading_bolt_on_racing_line: Array = all_bolts_on_racing_line[0]
	var leading_racing_point_index: int = leading_bolt_on_racing_line[1]
	var leading_bolt: KinematicBody2D = leading_bolt_on_racing_line[0]
	# player ali enemy
	var players_on_racing_line: Array
	var enemies_on_racing_line: Array
	for bolt_on_racing_line in all_bolts_on_racing_line:
		# set bolt ranking
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
		var enemy_racing_line_points: Array = level_racing_lines[enemy_racing_line_index].get_points()
		var enemy_racing_line_point: Vector2 = enemy_racing_line_points[enemy_on_racing_line[1]]
		var enemy_racing_line_point_index: int = enemy_racing_line_points.find(enemy_racing_line_point)
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
#		Ref.current_camera.follow_target = level_goal_position
	else:
		var leading_player_on_racing_line: Array = players_on_racing_line[0] # players_on_racing_line so že rangirani zato je 0 prvi
		leading_player = leading_player_on_racing_line[0]
		leading_racing_line = level_racing_lines[leading_player_on_racing_line[2]]
		
		# debug ... indikator
		if Set.debug_mode:
			pass
			var leading_point_index: int = leading_player_on_racing_line[1]
			var leading_point: Vector2 = level_racing_points[leading_point_index]
			position_indikator.global_position = leading_point
			position_indikator.scale = Vector2(3,3)
			position_indikator.modulate = leading_player.bolt_color
			# camera follow
#			if not Ref.current_camera.follow_target == position_indikator: # da kamera ne reagira, če je že setan isti plejer
#				Ref.current_camera.follow_target = position_indikator
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
		var pull_position_distance_from_leader_correction: float = bolt_to_pull.bolt_sprite.get_rect().size.y * 2 # 18 ... 20 # pull razdalja od vodilnega plejerja glede na index med trenutno pulanimi
	
		var vector_to_leading_player: Vector2 = leading_player.global_position - bolt_to_pull.global_position
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
					# preverim, da je dovolj stran od vodilnega
					if cell_position.distance_to(leading_player.global_position) > pull_position_distance_from_leader:
						# preverim, da pozicija ni že zasedena
						# če poza ni zasedena ga dodaj med zasedene
						if not current_pull_positions.has(cell_position):
							navigation_position_as_pull_position = cell_position
						else: # če je poza zasedena dobim njen in dex med zasedenimi dodam korekcijo na zahtevani razdalji od vodilnega
							var pull_pos_index: int = current_pull_positions.find(cell_position)
							var corrected_pull_position = pull_position_distance_from_leader + pull_pos_index * pull_position_distance_from_leader_correction
							if cell_position.distance_to(leading_player.global_position) > corrected_pull_position:
								navigation_position_as_pull_position = cell_position

		current_pull_positions.append(navigation_position_as_pull_position)
		return navigation_position_as_pull_position
		
	
# PRIVAT ----------------------------------------------------------------------------------------------------


func _on_bolt_activity_changed(bolt: KinematicBody2D):
	
	if bolt.bolt_active == false:
		check_for_level_finished()
	
	
func _on_level_is_set(tilemap_navigation_cells: Array, tilemap_navigation_cells_positions: Array):
#func _on_level_is_set(level_positions_nodes: Array, tilemap_navigation_cells: Array, tilemap_navigation_cells_positions: Array, level_checkpoints_count: int):
	
	# navigacija za enemy AI
	navigation_area = tilemap_navigation_cells
	navigation_positions = tilemap_navigation_cells_positions
	
	# random pickable pozicije 
	available_pickable_positions = navigation_area.duplicate()
	
	# racing linije
	level_racing_lines = Ref.current_level.racing_line.draw_racing_lines()
	for line in level_racing_lines:
		level_racing_points.append_array(line.get_points())
	
	# čekpointi
	checkpoints_per_lap = Ref.current_level.checkpoints_count	
	
	# spawn poz
#	level_bolt_position_nodes = level_positions_nodes
#	level_start_position_node = level_positions_nodes.pop_front()
#	level_goal_position_node = level_positions_nodes.pop_back()
	level_bolt_position_nodes = Ref.current_level.spawn_position_nodes.get_children()
	free_bolt_position_nodes = level_bolt_position_nodes.duplicate()
	
	# start and goal poz
	level_start_position_node = Ref.current_level.start_position_node
	level_goal_position_node = Ref.current_level.goal_position_node
	level_start_position = level_start_position_node.global_position
	level_goal_position = level_goal_position_node.global_position # vedno zadnja v arrayu
	
	# kamera
	Ref.current_camera.position = level_start_position
	Ref.current_camera.set_camera_limits()	
	
	# debug
	if Set.debug_mode and position_indikator == null:
		position_indikator = Met.spawn_indikator(level_bolt_position_nodes[1].global_position, 0)


# SIGNALI ----------------------------------------------------------------------------------------------------


func _on_enemy_path_changed(path: Array) -> void: # za prikaz linije
	# ta funkcija je vezana na signal bolta
	# inline connect za primer, če je bolt spawnan
	# def signal connect za primer, če je bolt "in-tree" node
	
	var navigation_line: Line2D = Ref.node_creation_parent.get_parent().enemy_navigation_line
	navigation_line.points = path


func _on_body_exited_screen(body: Node) -> void:
	
	if not game_on:
		return
	# player pull	
	if game_settings["race_mode"]:
		if body.is_in_group(Ref.group_players) and body.bolt_active:
			var bolt_pull_position: Vector2 = get_bolt_pull_position(body)
			var leader_laps_finished_count: int = leading_player.laps_finished_count
			var leader_checkpoints_reached: Array = leading_player.checkpoints_reached
			body.call_deferred("pull_bolt_on_screen", bolt_pull_position, leader_laps_finished_count, leader_checkpoints_reached)
	
	if body.is_in_group(Ref.group_bolts) and not body.bolt_active:
			body.call_deferred("set_physics_process", false)
	elif body is Bullet:
		body.on_out_of_screen() # ta funkcija zakasni učinek
	# elif body is Misile: ... ima timer in se sama kvefrija ... misila se lahko vrne v ekran (nitro)
