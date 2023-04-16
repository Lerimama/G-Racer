extends Node2D

#onready var enema = $LevelLayer_Z3/Level_00/enema
onready var player1 = preload("res://scenes/bolt/Bolt.tscn")
onready var player2 = preload("res://scenes/bolt/Bolt2.tscn")
onready var enemy1 = preload("res://scenes/bolt/Enemy.tscn")
onready var enemy2 = preload("res://scenes/bolt/Enemy.tscn")

onready var enemy: KinematicBody2D = $Level_00/Enemy
onready var bolt: KinematicBody2D = $Level_00/Bolt

onready var spawn_position_1: Position2D = $Level_00/SpawnPosition1
onready var spawn_position_2: Position2D = $Level_00/SpawnPosition2
onready var spawn_position_3: Position2D = $Level_00/SpawnPosition3
onready var spawn_position_4: Position2D = $Level_00/SpawnPosition4

var all_players: Array = []

func _ready() -> void:
	print ("Arena (parent node)")
	
	all_players.append(enemy)
	all_players.append(bolt)
#	all_players = [bolt, enemy]
	
	
func _unhandled_key_input(event: InputEventKey) -> void:
	
	if Input.is_key_pressed(KEY_1):
		kill_all()
		spawn_players(player1, spawn_position_1.global_position, Config.color_blue)
			
	if Input.is_key_pressed(KEY_2):
		kill_all()
		spawn_players(player1, spawn_position_1.global_position, Config.color_blue)
		spawn_players(player2, spawn_position_4.global_position, Config.color_green)
			
	if Input.is_key_pressed(KEY_3):
		kill_all()
		spawn_players(player1, spawn_position_1.global_position, Config.color_blue)
		spawn_players(player2, spawn_position_3.global_position, Config.color_green)
		spawn_players(enemy1, spawn_position_2.global_position, Config.color_yellow)
		spawn_players(enemy1, spawn_position_4.global_position, Config.color_red)
			
	if Input.is_key_pressed(KEY_4):
		kill_all()
		spawn_players(player1, spawn_position_1.global_position, Config.color_blue)
		spawn_players(player2, spawn_position_3.global_position, Config.color_green)
		spawn_players(enemy1, spawn_position_2.global_position, Config.color_yellow)
		spawn_players(enemy1, spawn_position_4.global_position, Config.color_red)


func spawn_players(bolt, pos, color):
	var new_player = bolt.instance()
	new_player.global_position = pos
	new_player.modulate = color
	Global.node_creation_parent.add_child(new_player)
	new_player.look_at(Vector2(320,180))
	
	all_players.append(new_player)
	
	
func kill_all():
	if not all_players.empty():

		for player in all_players:
			if player:
				player.has_method("die")
				player.die()
#				player.queue_free()
	all_players = []
	
