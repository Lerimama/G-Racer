extends Node2D


#onready var camera: Camera2D = $Camera
#onready var camera_follow_target: Bolt setget _set_camera_follow_target


func _ready() -> void:
	
	Ref.node_creation_parent = self
	print("Arena, Z-index ", z_index)

	
#func _set_camera_follow_target(player_to_follow):
#
#	camera_follow_target = player_to_follow
#	camera.following_target = player_to_follow
##	camera.position = player_to_follow.global_position
