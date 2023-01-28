extends Node2D

#export var st: Texture = $Bolt.texture

# shadows
#onready var st = $Player/Bolt.texture

# chat


func _ready() -> void:
	
	Global.node_creation_parent = self
	
#	var parent_node = get_node("Level_00")
##	var texture = parent_node.get_texture()
#	var render_target = $Level_00.get_render_target()
#	var texture = render_target.get_texture()

	
func _process(delta: float) -> void:
#	print (st)
	pass
