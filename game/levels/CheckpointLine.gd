extends Area2D


func _on_Checkpoint_body_entered(body: Node) -> void:
	
	if body.is_in_group(Ref.group_bolts):
		if body.bolt_active:
			body.on_checkpoint_reached(self)
#		modulate = Color.green
#		yield(get_tree().create_timer(0.5), "timeout")
#		modulate = Color.white


func _on_Checkpoint_body_exited(body: Node) -> void:
	pass # Replace with function body.
