extends Node2D


#signal stat_change_received (player_index, changed_stat, stat_new_value)

#var player1_id = "P1"
#var player2_id = "P2"
#var player3_id = "P3"
#var player4_id = "P4"
#var enemy_id = "E1"
#var bolts_in_game: Array
#var pickables_in_game: Array
#var available_pickable_positions: Array
#
#onready var player1_profile = Profiles.default_player_profiles[player1_id]
#onready var player2_profile = Profiles.default_player_profiles[player2_id]
#onready var player3_profile = Profiles.default_player_profiles[player3_id]
#onready var player4_profile = Profiles.default_player_profiles[player4_id]
#onready var enemy_profile = Profiles.default_player_profiles[enemy_id]
#
#onready var spawn_position_1: Position2D = $Level_00/Positions/SpawnPosition1
#onready var spawn_position_2: Position2D = $Level_00/Positions/SpawnPosition2
#onready var spawn_position_3: Position2D = $Level_00/Positions/SpawnPosition3
#onready var spawn_position_4: Position2D = $Level_00/Positions/SpawnPosition4
#
#onready var tilemap_floor_cells: Array
#onready var navigation_line: Line2D = $NavigationPath
#onready var enemy: KinematicBody2D = $Enemy
#
#onready var player_bolt = preload("res://scenes/bolt/Player.tscn")
#onready var enemy_bolt = preload("res://scenes/bolt/Enemy.tscn")
#onready var game_manager: Node = $GameManager

# temp
#onready var back_btn: Button = $BackBtn
#onready var pause_ui: Control = $PauseUI

onready var d_kamera: Camera2D = $DKamera
onready var camera_follow_target: Bolt setget _set_camera_follow_target
onready var level_edge: TileMap = $Level_00/Edge

onready var player: KinematicBody2D = $Player

func _ready() -> void:
	
	camera_follow_target = player
	
	Global.node_creation_parent = self
	$Enemy.connect("path_changed", Global.game_manager, "_on_Enemy_path_changed") # za prikaz linije, drugače ne rabiš


func _process(delta: float) -> void:
	if not get_tree().get_nodes_in_group(Config.group_bolts).empty():
		d_kamera.position = camera_follow_target.global_position
	
func _set_camera_follow_target(player_to_follow):
	camera_follow_target = player_to_follow
	d_kamera.position = camera_follow_target.global_position
