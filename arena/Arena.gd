extends Node

#export var st: Texture = $Bolt.texture

# shadows
#onready var st = $Player/Bolt.texture

func _ready() -> void:
	
	Global.node_creation_parent = self
	pass
	
func _process(delta: float) -> void:
#	print (st)
	pass
