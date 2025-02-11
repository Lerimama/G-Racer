extends Area2D


signal reached_by


func _on_Checkpoint_body_entered(body: Node) -> void:

	if body.is_in_group(Rfs.group_agents):
		emit_signal("reached_by", self, body)
