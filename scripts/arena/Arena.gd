extends Node2D


signal stat_change_received (player_index, changed_stat, stat_new_value)


var player1_id = "P1"
var player2_id = "P2"
var player3_id = "P3"
var player4_id = "P4"
var enemy_id = "E1"
var bolts_in_game: Array
var pickables_in_game: Array
var available_pickable_positions: Array

onready var player1_profile = Profiles.default_player_profiles[player1_id]
onready var player2_profile = Profiles.default_player_profiles[player2_id]
onready var player3_profile = Profiles.default_player_profiles[player3_id]
onready var player4_profile = Profiles.default_player_profiles[player4_id]
onready var enemy_profile = Profiles.default_player_profiles[enemy_id]

onready var spawn_position_1: Position2D = $Level_00/Positions/SpawnPosition1
onready var spawn_position_2: Position2D = $Level_00/Positions/SpawnPosition2
onready var spawn_position_3: Position2D = $Level_00/Positions/SpawnPosition3
onready var spawn_position_4: Position2D = $Level_00/Positions/SpawnPosition4

onready var tilemap_floor_cells: Array
onready var navigation_line: Line2D = $NavigationPath
onready var enemy: KinematicBody2D = $Enemy

onready var player_bolt = preload("res://scenes/bolt/Player.tscn")
onready var enemy_bolt = preload("res://scenes/bolt/Enemy.tscn")
onready var game_manager: Node = $GameManager


func _ready() -> void:
	
	Global.node_creation_parent = self
#	Global.game_manager = game_manager
#
	$Enemy.connect("path_changed", Global.game_manager, "_on_Enemy_path_changed") # za prikaz linije, drugače ne rabiš
	
#
#func _unhandled_key_input(event: InputEventKey) -> void:
#
#	# P1
#	if Input.is_key_pressed(KEY_1):
#		spawn_players(player_bolt, get_global_mouse_position(), player1_id)
##		spawn_players(player_bolt, spawn_position_1.global_position, player1_id)
#	# P2
#	if Input.is_key_pressed(KEY_2):
#		spawn_players(player_bolt, get_global_mouse_position(), player2_id)
##		spawn_players(player_bolt, spawn_position_4.global_position player2_id)
#	# P3
#	if Input.is_key_pressed(KEY_3):
#		spawn_players(player_bolt, get_global_mouse_position(), player3_id)
##		spawn_players(player_bolt, spawn_position_2.global_position, player3_id)
#	# P4
#	if Input.is_key_pressed(KEY_4):
#		spawn_players(player_bolt, get_global_mouse_position(), player4_id)
##		spawn_players(player_bolt, spawn_position_3.global_position, player4_id)
#	# Enemi
#	if Input.is_key_pressed(KEY_5):
#		spawn_players(enemy_bolt, get_global_mouse_position(), enemy_id)
#
#	if Input.is_action_just_pressed("x"):
#		spawn_pickable()
#
#	if Input.is_action_just_pressed("r"):
#		restart()
#
#
#
#func old_unhandled_key_input(event: InputEventKey) -> void:
#
##	# P1, P2
##	if Input.is_key_pressed(KEY_1):
##		kill_all()
##		yield(get_tree().create_timer(1), "timeout")
##		spawn_players(player, spawn_position_1.global_position, player1_player_name)
##		spawn_players(player, spawn_position_4.global_position, player2_player_name)
##	# P1, E1
##	if Input.is_key_pressed(KEY_2):
##		kill_all()
##		yield(get_tree().create_timer(1), "timeout")
##		spawn_players(player, spawn_position_1.global_position, player1_player_name)
##		spawn_players(enemy1, spawn_position_4.global_position, enemy1_player_name)
##	# P1, P2 E1
##	if Input.is_key_pressed(KEY_3):
##		kill_all()
##		yield(get_tree().create_timer(1), "timeout")
##		spawn_players(player, spawn_position_1.global_position, player1_player_name)
##		spawn_players(player, spawn_position_3.global_position, player2_player_name)
##		spawn_players(enemy1, spawn_position_4.global_position, enemy1_player_name)
##	# P1, P2, E1, E1
##	if Input.is_key_pressed(KEY_4):
##		kill_all()
##		yield(get_tree().create_timer(1), "timeout")
##		spawn_players(player, spawn_position_1.global_position, player1_player_name)
##		spawn_players(player, spawn_position_3.global_position, player2_player_name)
##		spawn_players(enemy1, spawn_position_2.global_position, enemy1_player_name)
##		spawn_players(enemy1, spawn_position_4.global_position, enemy1_player_name)
##
##	if Input.is_action_just_pressed("x"):
##		spawn_pickable()
#
#	pass
#
#
#func _process(delta: float) -> void:
#	bolts_in_game = get_tree().get_nodes_in_group(Config.group_bolts)
#	pickables_in_game = get_tree().get_nodes_in_group(Config.group_pickups)
#
#
#func spawn_pickable():
#
#
#	# uteži
#	if not available_pickable_positions.empty():
#		print(available_pickable_positions.size())
#
#		var pickables_array = Profiles.Pickables_names # samo za evidenco pri debugingu
#
#		# žrebanje tipa
#		var pickables_dict = Profiles.pickable_profiles
#		var selected_pickable_index: int = Global.get_random_member_index(pickables_dict)
#		var selected_pickable_name = Profiles.Pickables_names[selected_pickable_index]
#		var selected_pickable_path = pickables_dict[selected_pickable_index]["path"]
#
#		# žrebanje pozicije
#		var selected_cell_index: int = Global.get_random_member_index(tilemap_floor_cells)
#		var selected_cell_position = tilemap_floor_cells[selected_cell_index]
#
#		# spawn
#		var new_pickable = selected_pickable_path.instance()
#		new_pickable.global_position = selected_cell_position
#		add_child(new_pickable)
#		printt(selected_pickable_name, selected_cell_position, selected_pickable_path)
#
#		# odstranim celico iz arraya
#		available_pickable_positions.remove(selected_cell_index)
#
#
#func spawn_players(bolt, pos, spawned_player_name):
#
#	var new_player = bolt.instance()
#	new_player.global_position = pos
#	new_player.player_name = spawned_player_name
#	Global.node_creation_parent.add_child(new_player)
#
#	# če je plejer komp mu pošljem nmavigation area
#	if new_player.has_method("idle"):
#		new_player.navigation_cells = tilemap_floor_cells
#
#	# štartna rotacija
#	new_player.look_at(Vector2(320,180))
#
#	# new_player.connect("path_changed", self, "_on_Enemy_path_changed") # za prikaz linije, drugače ne rabiš
#	new_player.connect("stat_changed", self, "_on_Player_stat_changed") # za prikaz linije, drugače ne rabiš
#
#
#func restart():
#
#	# če v grupi bolts obstaja kakšen bolt
#	if not bolts_in_game.empty():
#		for bolt in bolts_in_game:
#			if bolt.has_method("die"):
#				bolt.die()
#	if not pickables_in_game.empty():
#		for p in pickables_in_game:
#			p.queue_free()
#
#
#func check_neighbour_cells(cell_grid_position, area_span):
#
#	var selected_cells: Array # = []
#	var neighbour_in_check: Vector2
#
#	# preveri vse celice v erase_area_span
#	for y in area_span:
#		for x in area_span:
#			neighbour_in_check = cell_grid_position + Vector2(x - 1, y - 1)
#			selected_cells.append(neighbour_in_check)
#	return selected_cells
#
#
#func _on_Enemy_path_changed(path: Array) -> void:
## ta funkcija je vezana na signal bolta
## inline connect za primer, če je bolt spawnan
## def signal connect za primer, če je bolt "in-tree" node
#	navigation_line.points = path
#
#
#func _on_Player_stat_changed(player_index, changed_stat, stat_new_value):
#
#	print("juhej")
#	emit_signal("stat_change_received", player_index, changed_stat, stat_new_value) # pošljemo signal, ki je že prikloplje na HUD
#
#
#func _on_Edge_navigation_completed(floor_cells:  Array) -> void:
#
#	available_pickable_positions = floor_cells # za spawnanje pickablov
#
#	tilemap_floor_cells = floor_cells # global cell positions
#	# tole je zaradi nespawnanega enemija 
#	call_deferred("pass_on", tilemap_floor_cells) # če ni te poti, pride do erorja pri nalaganju  ... vsami igri verjetno tega ne bo
#
#
#func pass_on(deferred_floor_cells: Array):
#	enemy.navigation_cells = deferred_floor_cells
