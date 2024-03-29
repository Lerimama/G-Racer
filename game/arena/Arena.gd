extends Node2D


func _ready() -> void:
	
	if not Set.debug_mode:
		$NavigationPath.hide()
		
	Ref.node_creation_parent = self
	print("ARENA")
