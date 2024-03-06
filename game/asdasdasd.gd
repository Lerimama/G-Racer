extends Node


signal stat_change_received (player_index, changed_stat, stat_new_value)
signal new_bolt_spawned # (name, ...)

enum GameoverReason {SUCCES, FAIL} # ali kdo od plejerjev napreduje, ali pa ne

var game_on: bool

var level_positions: Array # dobi od tilemapa
var leading_player: KinematicBody2D # trenutno vodilni igralec
var bolts_in_game: Array
var pickables_in_game: Array
var bolts_on_start: Array # GO naredi poročilo o vseh, ki so bili na štaru
var bolts_across_finish_line: Array # array boltov skupaj s časom

# level
var navigation_area: Array # vsi navigation tileti
var navigation_positions: Array # pozicije vseh navigation tiletov
var current_racing_line: Array # linija za ranking (array točk oz. pozicij)
var available_pickable_positions: Array # za random spawn

onready var navigation_line: Line2D = $"../NavigationPath"
onready var level_settings: Dictionary = Set.current_level_settings # ga med igro ne spreminjaš
onready var game_settings: Dictionary = Set.current_game_settings # ga med igro ne spreminjaš
onready var player_bolt = preload("res://game/bolt/Player.tscn")
#onready var player_bolt = preload("res://game/bolt/Player_orig.tscn")
onready var enemy_bolt = load("res://game/bolt/Enemy.tscn")
#onready var enemy_bolt = preload("res://game/bolt/Enemy_orig.tscn")

# temp
var position_indikator: Node2D	# debug
onready var NewLevel: PackedScene = level_settings["level_scene"]


func _input(event: InputEvent) -> void:

	if Input.is_action_just_pressed("x"):
		spawn_pickable()
	if Input.is_action_just_released("r"):
		call_deferred("game_over", GameoverReason.SUCCES)	
	if Input.is_action_just_pressed("f") and not bolts_in_game.empty():
		pass
		
	if not game_on and bolts_in_game.size() <= 4:
		if Input.is_key_pressed(KEY_1):
			set_game()
			spawn_bolt(player_bolt, level_positions[1].global_position, Pro.Bolts.P1, 1)
		if Input.is_key_pressed(KEY_2):
			set_game()
			spawn_bolt(player_bolt, level_positions[1].global_position, Pro.Bolts.P1, 1)
			spawn_bolt(player_bolt, level_positions[2].global_position, Pro.Bolts.P2, 2)
		if Input.is_key_pressed(KEY_3):
			set_game()
			spawn_bolt(player_bolt, level_positions[1].global_position, Pro.Bolts.P1, 1)
			spawn_bolt(player_bolt, level_positions[2].global_position, Pro.Bolts.P2, 2)
			spawn_bolt(player_bolt, level_positions[3].global_position, Pro.Bolts.P3, 3)
		if Input.is_key_pressed(KEY_4):
			set_game()
			spawn_bolt(player_bolt, level_positions[1].global_position, Pro.Bolts.P1, 1)
			spawn_bolt(player_bolt, level_positions[2].global_position, Pro.Bolts.P2, 2)
			spawn_bolt(player_bolt, level_positions[3].global_position, Pro.Bolts.P3, 3)
			spawn_bolt(player_bolt, level_positions[4].global_position, Pro.Bolts.P4, 4)

#	if game_on and bolts_in_game.size() <= 4:
#		if Input.is_key_pressed(KEY_5):
#			spawn_bolt(enemy_bolt, level_positions[1].global_position, Pro.Bolts.ENEMY, 5)


func _ready() -> void:
	
	Ref.game_manager = self	
	Ref.current_level = null
	printt("GM")
	
	yield(get_tree().create_timer(1), "timeout") # da se drevo naloži in lahko spawna bolta	(level global position)
	set_game()
	spawn_bolt(player_bolt, level_positions[1], Pro.Bolts.P1, 1)	
	spawn_bolt(player_bolt, level_positions[2], Pro.Bolts.P2, 2)	
#	spawn_bolt(player_bolt,level_positions[3], Pro.Bolts.P3, 3)	
#	spawn_bolt(player_bolt, level_positions[4], Pro.Bolts.P4, 4)	
#	spawn_bolt(enemy_bolt, level_positions[2], Pro.Bolts.ENEMY, 2)


func _process(delta: float) -> void:
	
	bolts_in_game = get_tree().get_nodes_in_group(Ref.group_bolts)
	pickables_in_game = get_tree().get_nodes_in_group(Ref.group_pickups)	

	if game_on and game_settings["race_mode"]:
		get_ingame_ranking()
	
	
func set_level(): # kliče main.gd pred fajdinom igre
	
	print("set level")
	if Ref.current_level == null:
		pass
	else:
		var level_to_release: Node2D = Ref.current_level # trenutno naložen v areni (holder)
		var level_to_load_path: String = level_settings["level_path"]
		var level_z_index: int = Ref.current_level.z_index
		
		# release default level	
		level_to_release.set_physics_process(false)
		level_to_release.free()

	# spawn new level
	# var Level = ResourceLoader.load(level_to_load_path)
	# var new_level = Level.instance()
	var new_level = NewLevel.instance()
	# new_level.z_index = level_z_index
	new_level.connect( "level_is_set", self, "_on_level_is_set")
	
	Ref.node_creation_parent.add_child(new_level)
	Ref.current_camera.set_camera_limits()
	available_pickable_positions = navigation_area.duplicate()
	
	
func set_game(): # kliče main.gd pred fejdin igre
	print("set game")
	
	# set_game_view()
	# set_players() # da je plejer viden že na fejdin
	
#	Global.hud.fade_splitscreen_popup()
#	yield(Global.hud, "players_ready")

	# player intro animacija
#	var signaling_player: KinematicBody2D
#	for player in get_tree().get_nodes_in_group(Global.group_players):
#		player.animation_player.play("lose_white_on_start")
#		signaling_player = player # da se zgodi na obeh plejerjih istočasno
#
#	yield(signaling_player, "player_pixel_set") # javi player na koncu intro animacije
#
#	if game_data["game"] == Profiles.Games.TUTORIAL: 
#		yield(get_tree().create_timer(1), "timeout") # da se animacija plejerja konča	
#	else:
#		set_strays()
#		yield(get_tree().create_timer(1), "timeout") # da si plejer ogleda	
#
#	Global.hud.slide_in(start_players_count)
	
	if Ref.hud: # debug
		Ref.hud.start_countdown.start_countdown()
		yield(Ref.hud.start_countdown, "countdown_finished") # sproži ga hud po slide-inu
	start_game()


func start_game():
	print("start game")
	
	for bolt in bolts_in_game:
		bolt.set_physics_process(true)
		bolt.bolt_active = true
#		Ref.sound_manager.play_music("game_music")

	if Ref.hud: # debug
		Ref.hud.on_game_start()
	game_on = true
		
		
func game_over(gameover_reason: int):

	if game_on == false: # preprečim double gameover
		return
	game_on = false

	yield(get_tree().create_timer(2), "timeout") # za dojet
	if Ref.hud: # debug
		Ref.hud.on_game_over()
	
	for bolt in bolts_in_game:
		bolt.bolt_active = false # načeloma bi moralo že veljati za vse ... zazih
	
	if gameover_reason == GameoverReason.SUCCES:
		printt("SUCCESS", bolts_across_finish_line.size())
		for bolt_across_finish_line in bolts_across_finish_line:
			printt("BOLT RANK", bolt_across_finish_line[0].bolt_id, bolt_across_finish_line[0].player_name, bolt_across_finish_line[1])
	elif gameover_reason == GameoverReason.FAIL:
		print("FAIL")
		
#	stop_game_elements()
	Ref.game_over.open_gameover(gameover_reason, bolts_across_finish_line, bolts_on_start)
	
	Ref.current_camera.follow_target = null

	
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


func spawn_bolt(NewBolt: PackedScene, spawn_position_node: Node2D, spawned_bolt_id: int, spawned_bolt_index: int):

	var new_bolt = NewBolt.instance()
	new_bolt.bolt_id = spawned_bolt_id
	new_bolt.global_position = spawn_position_node.global_position
	Ref.node_creation_parent.add_child(new_bolt)
	new_bolt.rotation_degrees = spawn_position_node.rotation_degrees - 90 # ob rotaciji 0 je default je obrnjen navzgor
	
	# new_bolt.look_at(Vector2(320,180)) # rotacija proti centru ekrana
	
	new_bolt.set_physics_process(false)
	new_bolt.connect("bolt_activity_changed", self, "_on_Bolt_activity_changed")
	if new_bolt is Enemy:
		new_bolt.navigation_cells = navigation_area
		new_bolt.connect("path_changed", self, "_on_Enemy_path_changed") # samo za prikaz nav linije
	elif new_bolt is Player:
		new_bolt.connect("stat_changed", Ref.hud, "_on_stat_changed") # statistika med boltom in hudom
		emit_signal("new_bolt_spawned", spawned_bolt_index, spawned_bolt_id) # pošljem na hud, da prižge stat line in ga napolne
		# Ref.current_camera.follow_target = new_bolt
	
	bolts_on_start.append(new_bolt)


func spawn_pickable():
	
	if not available_pickable_positions.empty():

		# žrebanje tipa
		var pickables_dict = Pro.pickable_profiles
		var random_pickables_key: String = Met.get_random_member(pickables_dict.keys())
		var random_pickable_path = pickables_dict[random_pickables_key]["scene_path"]
		print(random_pickables_key)

		# žrebanje pozicije
		var random_cell_position: Vector2 = Met.get_random_member(navigation_positions)

		# spawn
		var new_pickable = random_pickable_path.instance()
		new_pickable.global_position = random_cell_position
		add_child(new_pickable)

		# odstranim celico iz arraya tistih na voljo
		var random_cell_position_index: int = available_pickable_positions.find(random_cell_position)
		available_pickable_positions.remove(random_cell_position_index)		

		
# RANKING ---------------------------------------------------------------------------------------------


func on_bolt_across_finish_line(bolt_finished: KinematicBody2D): # sproži finish line
	
#	bolts_across_finish_line.append(bolt_finished)
	printt ("GO TIME", Ref.hud.game_timer.time_since_start)
	
	var bolt_time: float = Ref.hud.game_timer.time_since_start
	bolts_across_finish_line.append([bolt_finished, bolt_time])
	bolt_finished.bolt_active = false

	
func get_ingame_ranking():
	# najbližje točke vseh boltov primerjam (po indexu v racing liniji) 
	
	# vsi bolti
	var all_bolts_on_racing_line: Array = get_racing_line_bolts() # array ima bolta, index racing line točke in njeno lokacijo 
	all_bolts_on_racing_line.sort_custom(self, "sort_ascending")
	var leading_bolt_on_racing_line: Array = all_bolts_on_racing_line[0]
	var leading_racing_point_index: int = leading_bolt_on_racing_line[1]
	var leading_bolt: KinematicBody2D = leading_bolt_on_racing_line[0]
	
	# samo plejerji
	var players_on_racing_line: Array
	for bolt_on_racing_line in all_bolts_on_racing_line:
		if bolt_on_racing_line[0] is Player and bolt_on_racing_line[0].bolt_active:
			players_on_racing_line.append(bolt_on_racing_line)
	
	# če je še kakšen aktiven player
	if not players_on_racing_line.empty():
		var leading_player_on_racing_line: Array = players_on_racing_line[0] # players_on_racing_line so že rangirani zato je 0 prvi
		leading_player = leading_player_on_racing_line[0]
		var leading_player_racing_point_index: int = leading_player_on_racing_line[1]
		if not Ref.current_camera.follow_target == leading_player: # da kamera ne reagira, če je že setan isti plejer
			Ref.current_camera.follow_target = leading_player
		# posledice	
#		position_indikator.scale = Vector2(3,3)
#		position_indikator.global_position = current_racing_line[leading_player_racing_point_index]
#		position_indikator.modulate = leading_player.bolt_color
	# če so vsi neaktivni, lokacija kamere ostane ista
	else:
		Ref.current_camera.follow_target = null


func sort_ascending(array_1, array_2):
	
	if array_1[1] > array_2[1]:
	    return true
	return false

