extends Node2D


onready var playing_field: Node2D = $PlayingField # greba GM
onready var level_placeholder: Position2D = $LevelPosition # greba GM
onready var screen_area: Area2D = $PlayingField/ScreenArea
onready var screen_edge: StaticBody2D = $PlayingField/ScreenEdge


func _ready() -> void:
#	print("ARENA")

	# RFK NCP
	Rfs.node_creation_parent = $NCP # rabim, da lahko hitro vse spucam in resetiram level
	Rfs.game_arena = self

	# debug
	$__Label.hide()
