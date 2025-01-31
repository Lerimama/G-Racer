extends Node2D


signal finish_reached


func _on_FinishLine_body_entered(body: Node) -> void:

	if body.is_in_group(Rfs.group_bolts):
		emit_signal("finish_reached", body)
