extends Area2D


func _on_Checkpoint_body_entered(body: Node) -> void:
	
	if body.is_in_group(Ref.group_bolts):
		if body.bolt_active:
			body.on_checkpoint_reached(self)