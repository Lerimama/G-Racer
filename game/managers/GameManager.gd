extends Node


signal stat_change_received (player_index, changed_stat, stat_new_value)
signal new_bolt_spawned (name, other)

enum GameoverReason {SUCCES, FAIL, TIME} # ali kdo od plejerjev napreduje, ali pa ne

var game_on: bool

var bolt_spawn_position_nodes: Array # dobi od tilemapa
var bolts_in_game: Array
var pickables_in_game: Array
var bolts_on_start: Array # GO naredi poročilo o vseh, ki so bili na štaru
var bolts_across_finish_line: Array # array boltov skupaj s časom

# level
var navigation_area: Array # vsi navigation tileti
var navigation_positions: Array # pozicije vseh navigation tiletov
var available_pickable_positions: Array # za random spawn

# ranking
var leading_player: KinematicBody2D # trenutno vodilni igralec (rabim za camera target in pull target)
var leading_racing_line: Line2D	
var level_racing_lines: Array 
var level_racing_points: Array # pike vseh linij
var all_bolts_ranked: Array = []

onready var level_settings: Dictionary = Set.current_level_settings # ga med igro ne spreminjaš
onready var game_settings: Dictionary = Set.current_game_settings # ga med igro ne spreminjaš
onready var navigation_line: Line2D = $"../NavigationPath"

# temp 
var position_indikator: Node2D	# debug
onready var NewLevel: PackedScene = level_settings["level_scene"]

# neu
var checkpoints_per_lap: int
var level_goal_position: Vector2
var level_start_position: Vector2
var default_enemy_racing_point_offset: int = 20 # da lahko resetiram
var enemy_racing_point_offset: int = 20 # prediction points length ... vpliva na natančnost gibanja
var fast_start_window: bool = false
onready var laps_limit: int = level_settings["lap_limit"]
var enemy_racing_line_index: int = 0


func _input(event: InputEvent) -> void:
	
	if Input.is_action_just_pressed("m"):
		var bus_index: int = AudioServer.get_bus_index("GameMusic")
		var bus_is_mute: bool = AudioServer.is_bus_mute(bus_index)
		AudioServer.set_bus_mute(bus_index, not bus_is_mute)
			
	if game_on:
		if Input.is_action_just_pressed("x"):
			spawn_pickable()
		if Input.is_action_just_released("r"):
			call_deferred("game_over", GameoverReason.SUCCES)	
		#		if Input.is_action_just_pressed("f"):
		#			for bolt in bolts_in_game:
		#				if bolt.selected_feat_index > 2:
		#					bolt.selected_feat_index = 0
		#				else:
		#					bolt.selected_feat_index += 1
		#				print("id", bolt.selected_feat_index)


func _ready() -> void:
	printt("GM")
	
	Ref.game_manager = self	
	Ref.current_level = null # da deluje reštart
	
	
func _process(delta: float) -> void:
	
	bolts_in_game = get_tree().get_nodes_in_group(Ref.group_bolts)
	pickables_in_game = get_tree().get_nodes_in_group(Ref.group_pickables)	

	if game_on: 
		if game_settings["race_mode"]:
			get_game_ranking()
	
	
func set_game(): # kliče main.gd pred fejdin igre
	
	spawn_level()	
#	game_settings["start_player_count"] = 1
	var current_bolts_activated: Array = Set.bolts_activated
	if current_bolts_activated.empty(): # kadar ne štartam igre iz home menija
#		current_bolts_activated = [Pro.Bolts.P1] 
#		current_bolts_activated = [Pro.Bolts.P1, Pro.Bolts.P2] 
#		current_bolts_activated = [Pro.Bolts.P1, Pro.Bolts.ENEMY] 
		current_bolts_activated = [Pro.Bolts.P1, Pro.Bolts.P2, Pro.Bolts.ENEMY] 
#		current_bolts_activated = [Pro.Bolts.P1, Pro.Bolts.P2,Pro.Bolts.ENEMY, Pro.Bolts.ENEMY] 
#		current_bolts_activated = [Pro.Bolts.P1, Pro.Bolts.P2, Pro.Bolts.P3, Pro.Bolts.P4]
	
	var bolt_index: int = 0
	for bolt in current_bolts_activated:
		bolt_index += 1
		var player_scene: PackedScene = Pro.default_player_profiles[bolt]["player_scene"]
		spawn_bolt(player_scene, bolt_spawn_position_nodes[bolt_index - 1], current_bolts_activated[bolt_index - 1], bolt_index)	
		
	if Ref.current_level.start_lights:
		Ref.current_level.start_lights.start_countdown()
		yield(Ref.current_level.start_lights, "countdown_finished") # sproži ga hud po slide-inu
	else:
		Ref.hud.start_countdown.start_countdown()
		yield(Ref.hud.start_countdown, "countdown_finished") # sproži ga hud po slide-inu
		
	start_game()


func start_game():
	
	Ref.sound_manager.play_music()
	
	for bolt in bolts_in_game:
#		bolt.set_physics_process(true)
		bolt.bolt_active = true
#		Ref.sound_manager.play_music("game_music")

	Ref.hud.on_game_start()
	
	if game_settings["spawn_pickables_mode"]:
		spawn_pickable()
		
	game_on = true
	
	# fast start
	fast_start_window = true	
	yield(get_tree().create_timer(0.32), "timeout") # za dojet
	fast_start_window = false	
		
		
func game_over(gameover_reason: int):

	if game_on == false: # preprečim double gameover
		return
	game_on = false

	yield(get_tree().create_timer(2), "timeout") # za dojet
	
	if gameover_reason == GameoverReason.SUCCES:
		printt("GO SUCCESS", bolts_across_finish_line.size())
		for bolt_across_finish_line in bolts_across_finish_line:
			printt("BOLT RANK", bolt_across_finish_line[0].bolt_id, bolt_across_finish_line[0].player_name, bolt_across_finish_line[1])
	elif gameover_reason == GameoverReason.FAIL:
		print("GO FAIL")
	elif gameover_reason == GameoverReason.FAIL:
		for bolt in bolts_in_game:
			bolt.bolt_active = false
		print("GO TIME")
	Ref.game_over.open_gameover(gameover_reason, bolts_across_finish_line, bolts_on_start)
	
	# stop elemenets
	Ref.hud.on_game_over()
	Ref.sound_manager.stop_music()
	Ref.current_camera.follow_target = null
	for bolt in bolts_in_game: # zazih ... načeloma bi moralo že veljati za vse
		bolt.bolt_active = false 
		
		
func check_for_game_over(): # za preverjanje pogojev za game over (vsakič ko bolt spreminja aktivnost)
	
	var active_bolts: Array
	
	for bolt in bolts_in_game:
		if bolt.bolt_active:
			active_bolts.append(bolt)
	
	# če so vsi neaktivni je GAME OVER:
	if active_bolts.empty():
		# preverjam uspeh
		if not bolts_across_finish_line.empty(): # lahko so vsi izven cilja
			for bolt_across_finish_line in bolts_across_finish_line: # če je vsaj en plejer bil čez ciljno črto
				if bolt_across_finish_line[0] is Player:
					game_over(GameoverReason.SUCCES)		
					return # dovolj je en uspeh
		# če ni uspeha
		game_over(GameoverReason.FAIL)	


# SPAWNING ---------------------------------------------------------------------------------------------


func spawn_bolt(NewBolt: PackedScene, spawn_position_node: Node2D, spawned_bolt_id: int, spawned_bolt_index: int):

	var new_bolt = NewBolt.instance()
	new_bolt.bolt_id = spawned_bolt_id
	# new_bolt.bolt_id = spawned_bolt_index
	new_bolt.global_position = spawn_position_node.global_position
	Ref.node_creation_parent.add_child(new_bolt)
	new_bolt.rotation_degrees = spawn_position_node.rotation_degrees - 90 # ob rotaciji 0 je default je obrnjen navzgor
	
	# new_bolt.look_at(Vector2(320,180)) # rotacija proti centru ekrana
	# new_bolt.set_physics_process(false)

	new_bolt.connect("bolt_activity_changed", self, "_on_Bolt_activity_changed")
	if new_bolt.is_in_group(Ref.group_enemies):
	# if new_bolt is Enemy: ..script error or cycling dependancy
		new_bolt.navigation_cells = navigation_area
		new_bolt.connect("path_changed", self, "_on_Enemy_path_changed") # samo za prikaz nav linije
		emit_signal("new_bolt_spawned", spawned_bolt_index, spawned_bolt_id) # pošljem na hud, da prižge stat line in ga napolne
	if new_bolt.is_in_group(Ref.group_players):
		new_bolt.connect("stat_changed", Ref.hud, "_on_stat_changed") # statistika med boltom in hudom
		emit_signal("new_bolt_spawned", spawned_bolt_index, spawned_bolt_id) # pošljem na hud, da prižge stat line in ga napolne
		# Ref.current_camera.follow_target = new_bolt
	
	bolts_on_start.append(new_bolt)

	Ref.current_camera.follow_target = new_bolt # začasen holder, ki se obdrži, če se ob štartu ne seta posebej (racing se ...) 


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
	

func spawn_level():
	
	var level_position: Position2D = $"../LevelPosition"
	var level_z_index: int # z index v node drevesu
	
	if not Ref.current_level == null: # če level že obstaja, ga najprej moram zbrisat
		#var level_to_load_path: String = level_settings["level_path"]
		level_z_index = Ref.current_level.z_index
		Ref.current_level.set_physics_process(false)
		Ref.current_level.free()
	else: # če je samo level marker
		level_z_index = level_position.z_index
		
	# spawn level
	# var Level = ResourceLoader.load(level_to_load_path)
	# var new_level = Level.instance()
	var new_level = NewLevel.instance()
	new_level.z_index = level_z_index
	new_level.connect( "level_is_set", self, "_on_level_is_set") # nujno pred add child, ker ga level sproži že na ready
	Ref.node_creation_parent.add_child(new_level)

		
# RANKING ---------------------------------------------------------------------------------------------

		
func on_bolt_across_finish_line(bolt_finished: KinematicBody2D): # sproži finish line
	
	var time_to_finish: float = 2 # čas za druge, da dosežejo cilj
	#	var current_race_time: float  = Ref.hud.game_timer.current_game_time # beleženje časa
	
	var current_race_time: float  = Ref.hud.game_timer.absolute_game_time # pozitiven game čas v sekundah
	
	# LAP
	if bolt_finished.checkpoints_reached.size() >= checkpoints_per_lap:
		bolt_finished.on_lap_finished(current_race_time, laps_limit)
	
	# FINISH
	# če je izpolnil število krogov, ga pripnem, ki tistim ki so končali 
	if bolt_finished.laps_finished >= laps_limit:
		# deaktiviram plejerja in zabležim statistiko 
		var race_finished_time: float = current_race_time
		if bolt_finished is Player:
			bolt_finished.bolt_active = false # enemy se disebla ko doseže target
			# če prvi med igralci, je konec igre
			if not bolts_across_finish_line.has(bolt_finished): # če ga še nima, je prvi med plejerji
				# timer postane limited in določim mu limit
				# GO timer se sproži ko je prvi čez
				Ref.hud.game_timer.limitless_mode = false
				Ref.hud.game_timer.game_time_limit = race_finished_time + time_to_finish
				printt ("GO TIME", Ref.hud.game_timer.game_time_limit, Ref.hud.game_timer.absolute_game_time)				
		elif bolt_finished is Enemy:
			bolt_finished.on_race_finished()
		bolts_across_finish_line.append([bolt_finished, race_finished_time]) # pripnem šele tukaj, da lahko prej čekiram, če je prvi plejer
			

func get_game_ranking():
	# najbližje točke vseh boltov primerjam (po indexu na vodilni racing liniji) 
	## problem ... trenutnega načina je da rangira plejerje glede na index točke znotraj njene linije
	## rad bi ... ko vodilni plejer zamenja linijo se le-ta zamenja
	## rešitev ... ko enkrat vem kdo je leading plejer, moram rangirat samo glede na njegovo linijo
	
	# vodilna racing linija
	if leading_racing_line == null:
		leading_racing_line = level_racing_lines[0] # na začetku je vedno ta glavna linija, kasneje se opredeli glede na vodilnega plejerja
	# debug
	#	for line in level_racing_lines: 
	#		if level_racing_lines.find(line) == level_racing_lines.find(leading_racing_line):
	#			line.modulate = Color.red
	#		else:
	#			line.modulate = Color.white
					
	# VSI BOLTI
	# sortam arraj po indexu pike na vodilni liniji ... 0 ... bolt, 1 ... closest_racing_line_point_index, 2 ...closest_racing_line_index
	var all_bolts_on_racing_line: Array = get_racing_line_bolts() # array ima bolta, index najbližje točke na svoji liniji, točko (global position) in index linije
	all_bolts_on_racing_line.sort_custom(self, "sort_bolts_by_point_index")
	# razvrstim po prevoženih krogih
	all_bolts_on_racing_line.sort_custom(self, "sort_bolts_by_laps")
	all_bolts_ranked = all_bolts_on_racing_line
	# vodilni bolt
	var leading_bolt_on_racing_line: Array = all_bolts_on_racing_line[0]
	var leading_racing_point_index: int = leading_bolt_on_racing_line[1]
	var leading_bolt: KinematicBody2D = leading_bolt_on_racing_line[0]
	# player ali enemy
	var players_on_racing_line: Array
	var enemies_on_racing_line: Array
	for bolt_on_racing_line in all_bolts_on_racing_line:
		# set bolt ranking
		bolt_on_racing_line[0].current_race_ranking = all_bolts_on_racing_line.find(bolt_on_racing_line) + 1
		# če je plejer ga dodam me plejerje
		if bolt_on_racing_line[0] is Player and bolt_on_racing_line[0].bolt_active:
			players_on_racing_line.append(bolt_on_racing_line)
		elif bolt_on_racing_line[0] is Enemy and bolt_on_racing_line[0].bolt_active:
			enemies_on_racing_line.append(bolt_on_racing_line)
			
	# ENEMIES ... setam nav target
	# če ni čekpointov
#	if checkpoints_per_lap == 0:
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
		
		
	# če so čekpointi
		
	# PLAYERS ... setam vodilnega, vodilno linijo in tarčo kamere
	if not players_on_racing_line.empty(): 
		var leading_player_on_racing_line: Array = players_on_racing_line[0] # players_on_racing_line so že rangirani zato je 0 prvi
		leading_player = leading_player_on_racing_line[0]
		leading_racing_line = level_racing_lines[leading_player_on_racing_line[2]]
		# debug ... indikator
#		if level_settings["level"] == Set.Levels.DEBUG_RACE:
		var leading_point_index: int = leading_player_on_racing_line[1]
		var leading_point: Vector2 = level_racing_points[leading_point_index]
		position_indikator.global_position = leading_point
		position_indikator.scale = Vector2(3,3)
		position_indikator.modulate = leading_player.bolt_color
		# camera follow
		if not Ref.current_camera.follow_target == leading_player: # da kamera ne reagira, če je že setan isti plejer
			Ref.current_camera.follow_target = leading_player
	# če so vsi neaktivni, lokacija kamere ostane ista
	else:
		Ref.current_camera.follow_target = null
	

func sort_bolts_by_laps(bolt_on_racing_line_1, bolt_on_racing_line_2): # ascending ... večji index je boljši
	
	if bolt_on_racing_line_1[0].laps_finished > bolt_on_racing_line_2[0].laps_finished:
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
		elif bolt is Enemy:	
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
		if bolt is Player:
			closest_racing_line_point_index = level_racing_points.find(closest_racing_line_point)
			closest_racing_line_index = level_racing_lines.find(closest_racing_line)
		elif bolt is Enemy:
			closest_racing_line_point_index = level_racing_lines[enemy_racing_line_index].get_points().find(closest_racing_line_point)
			closest_racing_line_index = enemy_racing_line_index
					
		var bolt_on_racing_line: Array = [bolt, closest_racing_line_point_index, closest_racing_line_index] # 0 ... bolt, 1 ... closest_racing_line_point_index, 2 ...closest_racing_line_index
		bolts_on_racing_line.append(bolt_on_racing_line)
	
	return bolts_on_racing_line

	
func get_bolt_pull_position(bolt_to_pull: KinematicBody2D):
	# na koncu izbrana pull pozicija:
	# - je na območju navigacije
	# - upošteva razdaljo do vodilnega
	# - se ne pokriva z drugim plejerjem	
	
	if game_on:
		
		# pull pozicija brez omejitev
		var pull_position_distance_from_leader: float = 10 # pull razdalja od vodilnega plejerja  
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
				# preverim, če je bližja od trenutno opredeljene
				if cell_position.distance_to(bolt_pull_position) < navigation_position_as_pull_position.distance_to(bolt_pull_position):
					# preverim, da je dovolj stran od vodilnega
					if cell_position.distance_to(leading_player.global_position) > pull_position_distance_from_leader:
						available_navigation_pull_positions.append(cell_position)
						# nazadnje preverim, da se ne pokriva z območjem drugega plejerja ... ne deluje ravno
						for area in bolt_areas:
							if not area.has_point(cell_position):
								navigation_position_as_pull_position = cell_position
								break # rabim samo eno pozicijo
		
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
		check_for_game_over()

	
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
	position_indikator = Met.spawn_indikator(bolt_spawn_position_nodes[1].global_position, 0)
	position_indikator.modulate.a = 0


# SIGNALI ----------------------------------------------------------------------------------------------------


func _on_Enemy_path_changed(path: Array) -> void:
	# ta funkcija je vezana na signal bolta
	# inline connect za primer, če je bolt spawnan
	# def signal connect za primer, če je bolt "in-tree" node
	
	navigation_line.points = path


func _on_ScreenArea_body_exited(body: Node) -> void:
	
	# player pull	
	if game_settings["race_mode"]:
		if body is Player:
			var bolt_pull_position = get_bolt_pull_position(body)
			body.call_deferred("pull_bolt_on_screen", bolt_pull_position)
	
	if body is Bolt:
		if not body.bolt_active:
			body.call_deferred("set_physics_process", false)
	elif body is Bullet:
		print("bull")
		body.on_out_of_screen() # ta funkcija zakasni učinek
	# elif body is Misile: ... ima timer in se sama kvefrija ... misila se lahko vrne v ekran (nitro)
		
