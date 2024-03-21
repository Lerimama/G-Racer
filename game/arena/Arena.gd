extends Node2D


func _ready() -> void:
	
#	$NavigationPath.hide()
	Ref.node_creation_parent = self
	print("ARENA")
