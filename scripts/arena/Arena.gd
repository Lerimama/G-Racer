extends Node2D


var player1_player_name = "P1"
var player2_player_name = "P2"
var enemy1_player_name = "E1"
var bolts_in_game: Array

onready var player1_profile = Profiles.default_player_profiles[player1_player_name]
onready var player2_profile = Profiles.default_player_profiles[player2_player_name]
onready var enemy1_profile = Profiles.default_player_profiles[enemy1_player_name]

onready var spawn_position_1: Position2D = $Level_00/Positions/SpawnPosition1
onready var spawn_position_2: Position2D = $Level_00/Positions/SpawnPosition2
onready var spawn_position_3: Position2D = $Level_00/Positions/SpawnPosition3
onready var spawn_position_4: Position2D = $Level_00/Positions/SpawnPosition4

onready var tilemap_navigation_cells: Array
onready var navigation_line: Line2D = $NavigationPath
onready var enemy: KinematicBody2D = $Enemy

onready var player = preload("res://scenes/bolt/Player.tscn")
onready var enemy1 = preload("res://scenes/bolt/Enemy.tscn")


func _ready() -> void:
	
	Global.node_creation_parent = self
	
	$Enemy.connect("path_changed", self, "_on_Enemy_path_changed") # za prikaz linije, drugače ne rabiš
	

func _unhandled_key_input(event: InputEventKey) -> void:

	# P1, P2
	if Input.is_key_pressed(KEY_1):
		kill_all_players()
		yield(get_tree().create_timer(1), "timeout")
		spawn_players(player, spawn_position_1.global_position, player1_player_name)
		spawn_players(player, spawn_position_4.global_position, player2_player_name)
	# P1, E1
	if Input.is_key_pressed(KEY_2):
		kill_all_players()
		yield(get_tree().create_timer(1), "timeout")
		spawn_players(player, spawn_position_1.global_position, player1_player_name)
		spawn_players(enemy1, spawn_position_4.global_position, enemy1_player_name)
	# P1, P2 E1
	if Input.is_key_pressed(KEY_3):
		kill_all_players()
		yield(get_tree().create_timer(1), "timeout")
		spawn_players(player, spawn_position_1.global_position, player1_player_name)
		spawn_players(player, spawn_position_3.global_position, player2_player_name)
		spawn_players(enemy1, spawn_position_4.global_position, enemy1_player_name)
	# P1, P2, E1, E1
	if Input.is_key_pressed(KEY_4):
		kill_all_players()
		yield(get_tree().create_timer(1), "timeout")
		spawn_players(player, spawn_position_1.global_position, player1_player_name)
		spawn_players(player, spawn_position_3.global_position, player2_player_name)
		spawn_players(enemy1, spawn_position_2.global_position, enemy1_player_name)
		spawn_players(enemy1, spawn_position_4.global_position, enemy1_player_name)


func _process(delta: float) -> void:
	bolts_in_game = get_tree().get_nodes_in_group(Config.group_bolts)

	
func spawn_players(bolt, pos, spawned_player_name):
	
	var new_player = bolt.instance()
	new_player.global_position = pos
	new_player.player_name = spawned_player_name
	Global.node_creation_parent.add_child(new_player)
	
	# če je plejer komp mu pošljem nmavigation area
	if new_player.has_method("idle"):
		new_player.navigation_cells = tilemap_navigation_cells
	
	# štartna rotacija
	new_player.look_at(Vector2(320,180))
	
	# new_player.connect("path_changed", self, "_on_Enemy_path_changed") # za prikaz linije, drugače ne rabiš


func kill_all_players():
	
	# če v grupi bolts obstaja kakšen bolt
	if not bolts_in_game.empty():
		for bolt in bolts_in_game:
			if bolt.has_method("die"):
				bolt.die()


func _on_Enemy_path_changed(path) -> void:
# ta funkcija je vezana na signal bolta
# inline connect za primer, če je bolt spawnan
# def signal connect za primer, če je bolt "in-tree" node
	navigation_line.points = path


func _on_Edge_navigation_completed(tilemap_floor_cells) -> void:
	tilemap_navigation_cells = tilemap_floor_cells
	# tole je za nespawnanega enemija 
	call_deferred("pass_on", tilemap_floor_cells) # če ni te poti, pride do erorja pri nalaganju  ... vsami igri verjetno tega ne bo
	
	
func pass_on(floor_cells):
	enemy.navigation_cells = floor_cells
