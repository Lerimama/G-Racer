extends Node2D


onready var enemy_navigation_line: Line2D = $NavigationPath
onready var camera_screen_area: Area2D = $ScreenArea
onready var level_placeholder: Position2D = $LevelPosition


func _ready() -> void:
	
	if not Set.debug_mode:
		enemy_navigation_line.hide()
		
	Ref.node_creation_parent = self
	print("ARENA")
