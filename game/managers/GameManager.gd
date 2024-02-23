extends Node


## ---------------------------------------------------------------------------------------------
## 
## KAJ DOGAJA
## - spawna plejerje in druge entitete v areni
## - spavna levele
## - uravnava potek igre (uvaljevlja pravila)
## - je centralna baza za vso statistiko igre
## - povezava med igro in HUDom
##
## KAJ NE ...
## - nima povezave z izgradnjo levela
## 
## ---------------------------------------------------------------------------------------------


signal stat_change_received (player_index, changed_stat, stat_new_value)
signal new_bolt_spawned # (name, ...)

# players
var player1_id = "P1"
var player2_id = "P2"
var player3_id = "P3"
var player4_id = "P4"
var enemy_id = "E1"
var bolts_in_game: Array
var spawned_bolt_index: int = 0

var pickables_in_game: Array
var available_pickable_positions: Array

onready var player1_profile = Pro.default_player_profiles[player1_id]
onready var player2_profile = Pro.default_player_profiles[player2_id]
onready var player3_profile = Pro.default_player_profiles[player3_id]
onready var player4_profile = Pro.default_player_profiles[player4_id]
onready var enemy_profile = Pro.default_player_profiles[enemy_id]

onready var tilemap_floor_cells: Array
onready var navigation_line: Line2D = $"../NavigationPath"
onready var enemy: KinematicBody2D = $"../Enemy"
#onready var enemy: KinematicBody2D = $"../Enemy"

onready var player_bolt = preload("res://game/player/Player.tscn")
onready var enemy_bolt = preload("res://game/enemies/Enemy.tscn")

# slovar vseh plejerjev
#var game_stats: Dictionary = {
#	"round": 0,
#	"winner_id": "NN",
#	"final_score": 0,
#}
var game_on: bool

func _input(event: InputEvent) -> void:

	if Input.is_action_just_pressed("x"):
		spawn_pickable()
	if Input.is_action_just_pressed("r"):
		game_over(0)
		
	if not game_on and bolts_in_game.size() <= 4:
		# P1
		if Input.is_key_pressed(KEY_1):
			set_game()
			spawn_bolt(player_bolt, Ref.current_level.spawn_position_1.global_position, player1_id, 1)
		# P2
		if Input.is_key_pressed(KEY_2):
			set_game()
			spawn_bolt(player_bolt, Ref.current_level.spawn_position_1.global_position, player1_id, 1)
			spawn_bolt(player_bolt, Ref.current_level.spawn_position_2.global_position, player2_id, 2)
#		# P3
		if Input.is_key_pressed(KEY_3):
			set_game()
			spawn_bolt(player_bolt, Ref.current_level.spawn_position_1.global_position, player1_id, 1)
			spawn_bolt(player_bolt, Ref.current_level.spawn_position_2.global_position, player2_id, 2)
			spawn_bolt(player_bolt, Ref.current_level.spawn_position_3.global_position, player3_id, 3)
#		# P4
		if Input.is_key_pressed(KEY_4):
			set_game()
			spawn_bolt(player_bolt, Ref.current_level.spawn_position_1.global_position, player1_id, 1)
			spawn_bolt(player_bolt, Ref.current_level.spawn_position_2.global_position, player2_id, 2)
			spawn_bolt(player_bolt, Ref.current_level.spawn_position_3.global_position, player3_id, 3)
			spawn_bolt(player_bolt, Ref.current_level.spawn_position_4.global_position, player4_id, 4)
#		# Enemi
		if Input.is_key_pressed(KEY_5):
			spawn_bolt(enemy_bolt, get_parent().get_global_mouse_position(), enemy_id, 5)



func _ready() -> void:
	
	Ref.game_manager = self	
	printt("Game Manager")
	yield(get_tree().create_timer(1), "timeout") # da se animacija plejerja konča	
	
	set_game()
	spawn_bolt(player_bolt, Ref.current_level.spawn_position_1.global_position, player1_id, 1)	

func _process(delta: float) -> void:
	bolts_in_game = get_tree().get_nodes_in_group(Ref.group_bolts)
	pickables_in_game = get_tree().get_nodes_in_group(Ref.group_pickups)	



func set_game(): 

	# kliče main.gd pred prikazom igre
	# set_tilemap()
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
#	yield(Global.start_countdown, "countdown_finished") # sproži ga hud po slide-inu

	start_game()
#
#
func start_game():

#		for player in get_tree().get_nodes_in_group(Global.group_players):
#			player.set_physics_process(true)
#		Ref.sound_manager.play_music("game_music")
		if Ref.hud:
			Ref.hud.on_game_start()
		game_on = true
		
		
func game_over(gameover_reason: int):
	print("NO GO")
	

	if game_on == false: # preprečim double gameover
		return
	game_on = false

#	Global.hud.game_timer.stop_timer()
#
#	if gameover_reason == GameoverReason.CLEANED:
#		all_strays_died_alowed = true
#		yield(self, "all_strays_died")
#		var signaling_player: KinematicBody2D
#		for player in get_tree().get_nodes_in_group(Global.group_players):
#			player.all_cleaned()
#			signaling_player = player # da se zgodi na obeh plejerjih istočasno
#		yield(signaling_player, "rewarded_on_game_over") # počakam, da je nagrajen
#
#	get_tree().call_group(Global.group_players, "set_physics_process", false)
#
#	yield(get_tree().create_timer(1), "timeout") # za dojet
#
#	stop_game_elements()
#	Global.gameover_menu.open_gameover(gameover_reason)
	print("GO")
	
#	if Ref.game_hud != null:
	if Ref.hud:
		Ref.hud.on_game_over()
	
	# če v grupi bolts obstaja kakšen bolt
	if not bolts_in_game.empty():
		for bolt in bolts_in_game:
			bolt
			bolt.queue_free()
	if not pickables_in_game.empty():
		for p in pickables_in_game:
			p.queue_free()
#	$"../UI/HUD".hide_player_stats()
	spawned_bolt_index = 0
	Ref.current_camera.follow_target = null



func spawn_bolt(bolt, spawned_position, spawned_player_id, bolt_index):

	spawned_bolt_index += 1

	var new_bolt = bolt.instance()
	new_bolt.bolt_owner = spawned_player_id
	new_bolt.global_position = spawned_position
	Ref.node_creation_parent.add_child(new_bolt)

	new_bolt.look_at(Vector2(320,180)) # rotacija proti centru ekrana

	# če je plejer komp mu pošljem navigation area
	if new_bolt == enemy_bolt:
		new_bolt.navigation_cells = tilemap_floor_cells
		# prikaz nav linije
		# new_bolt.connect("path_changed", self, "_on_Enemy_path_changed")
	else:
		Ref.current_camera.follow_target = new_bolt
	
	# statistika med boltom in hudom
	new_bolt.connect("stat_changed", Ref.hud, "_on_stat_changed") # za prikaz linije, drugače ne rabiš
	
	printt("new_bolt_spawned", spawned_bolt_index, spawned_player_id)
	emit_signal("new_bolt_spawned", spawned_bolt_index, spawned_player_id) # pošljem na hud, da prižge stat line in ga napolne


func spawn_pickable():


	# uteži
	if not available_pickable_positions.empty():

		var pickables_array = Pro.Pickables_names # samo za evidenco pri debugingu

		# žrebanje tipa
		var pickables_dict = Pro.pickable_profiles
		var selected_pickable_index: int = Met.get_random_member_index(pickables_dict)
		var selected_pickable_name = Pro.Pickables_names[selected_pickable_index]
		var selected_pickable_path = pickables_dict[selected_pickable_index]["path"]

		# žrebanje pozicije
		var selected_cell_index: int = Met.get_random_member_index(tilemap_floor_cells)
		var selected_cell_position = tilemap_floor_cells[selected_cell_index]

		# spawn
		var new_pickable = selected_pickable_path.instance()
		new_pickable.global_position = selected_cell_position
		add_child(new_pickable)

		# odstranim celico iz arraya
		available_pickable_positions.remove(selected_cell_index)		



func check_neighbour_cells(cell_grid_position, area_span):

	var selected_cells: Array # = []
	var neighbour_in_check: Vector2

	# preveri vse celice v erase_area_span
	for y in area_span:
		for x in area_span:
			neighbour_in_check = cell_grid_position + Vector2(x - 1, y - 1)
			selected_cells.append(neighbour_in_check)
	return selected_cells


func _on_Enemy_path_changed(path: Array) -> void:
	# ta funkcija je vezana na signal bolta
	# inline connect za primer, če je bolt spawnan
	# def signal connect za primer, če je bolt "in-tree" node
	
	navigation_line.points = path
