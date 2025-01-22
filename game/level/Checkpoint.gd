extends Area2D


signal goal_reached


func _on_Checkpoint_body_entered(body: Node) -> void:

	if body.is_in_group(Rfs.group_bolts):
		emit_signal("goal_reached", self, body)
