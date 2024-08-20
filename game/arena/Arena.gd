extends Node2D


onready var camera_screen_area: Area2D = $ScreenArea # greba GM
onready var level_placeholder: Position2D = $LevelPosition # greba GM


func _ready() -> void:
	print("ARENA")
	
	# RFK NCP
	Ref.node_creation_parent = $NCP
#	Ref.node_creation_parent = self 
	Ref.game_arena = self
