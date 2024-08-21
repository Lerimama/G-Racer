extends Node2D


onready var playing_field: Node2D = $PlayingField # greba GM
onready var level_placeholder: Position2D = $LevelPosition # greba GM


func _ready() -> void:
	print("ARENA")
	
	# RFK NCP
	Ref.node_creation_parent = $NCP # rabim, da lahko hitro vse spucam in resetiram level
	Ref.game_arena = self
