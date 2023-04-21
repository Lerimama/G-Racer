extends Node2D

#onready var enema = $LevelLayer_Z3/Level_00/enema
#onready var player1 = preload("res://scenes/bolt/Bolt.tscn")
#onready var player2 = preload("res://scenes/bolt/Bolt2.tscn")
onready var player = preload("res://scenes/bolt/Player.tscn")
onready var enemy1 = preload("res://scenes/bolt/Enemy.tscn")

var player1_player_name = "P1"
var player2_player_name = "P2"
var enemy1_player_name = "E1"
onready var player1_profile = Profiles.default_player_profiles[player1_player_name]
onready var player2_profile = Profiles.default_player_profiles[player2_player_name]
onready var enemy1_profile = Profiles.default_player_profiles[enemy1_player_name]

onready var enemy: KinematicBody2D = $Level_00/Enemy

onready var spawn_position_1: Position2D = $Level_00/SpawnPosition1
onready var spawn_position_2: Position2D = $Level_00/SpawnPosition2
onready var spawn_position_3: Position2D = $Level_00/SpawnPosition3
onready var spawn_position_4: Position2D = $Level_00/SpawnPosition4

#onready var player_in: KinematicBody2D = $Level_00/Player
onready var level: Node2D = $Level_00

var all_players: Array = []

onready var label_p1: Label = $Level_00/Label
onready var label_p2: Label = $Level_00/Label2
var key_pressed: bool

var p1_energy: float = 10
var p2_energy: float = 10

#var damage
#var shooter


func _ready() -> void:
	
	Config.game_manager = self
	
	print ("Arena (parent node)")

	all_players.append(enemy)
#	all_players.append(bolt)
#	all_players = [bolt, enemy]
	
#	player_in.player_name = "P2"
	
	$Level_00/FaktoriranEnemy.connect("path_changed_faktoriran", level, "_on_Enemy_path_changed_faktoriran")
	

func _unhandled_key_input(event: InputEventKey) -> void:

	# one player
	if Input.is_key_pressed(KEY_1):
		kill_all()
		yield(get_tree().create_timer(1), "timeout")
#		spawn_players(player, spawn_position_1.global_position, player1_player_name)
		spawn_players(enemy1, spawn_position_4.global_position, enemy1_player_name)
#		connecting_signals(enemy1)
			
	# two players
	if Input.is_key_pressed(KEY_2):
		kill_all()
		yield(get_tree().create_timer(1), "timeout")
		spawn_players(player, spawn_position_1.global_position, player1_player_name)
		spawn_players(player, spawn_position_4.global_position, player2_player_name)
	# player vs enemy
	if Input.is_key_pressed(KEY_3):
		kill_all()
		yield(get_tree().create_timer(1), "timeout")
		spawn_players(player, spawn_position_1.global_position, player1_player_name)
		spawn_players(enemy1, spawn_position_4.global_position, enemy1_player_name)
	# two players, two enemies
	if Input.is_key_pressed(KEY_4):
		kill_all()
		yield(get_tree().create_timer(1), "timeout")
		spawn_players(player, spawn_position_1.global_position, player1_player_name)
		spawn_players(player, spawn_position_3.global_position, player2_player_name)
		spawn_players(enemy1, spawn_position_2.global_position, enemy1_player_name)
		spawn_players(enemy1, spawn_position_4.global_position, enemy1_player_name)

func _process(delta: float) -> void:
	label_p1.text = str(p1_energy)
	label_p2.text = str(p2_energy)
	

#func connecting_signals(signal_node):
#	signal_node.connect("path_changed", level, "_on_Enemy_path_changed")
#	print("povezano")


func manage_player_stats(damage, bolt):
	print(bolt)
	p2_energy -= damage 
#	health -= damage
#	health_bar.scale.x = health/10
#	if health <= 0:
#		die()
	
	if p2_energy <= 0:
		bolt.die()
		


func spawn_players(bolt, pos, spawned_player_name):
	var new_player = bolt.instance()
	new_player.global_position = pos
	new_player.player_name = spawned_player_name
	Global.node_creation_parent.add_child(new_player)
	new_player.connect("path_changed", level, "_on_Enemy_path_changed")
	
	new_player.look_at(Vector2(320,180))
#	if new_player.player_name == 
	all_players.append(new_player)
	print("spawned player: " + spawned_player_name)


func kill_all():
	if not all_players.empty():

		for player in all_players:
			if player != null:
#			if all_players.has(player):
				if player.has_method("die"):
					player.die()
					player.queue_free()
	all_players = []

