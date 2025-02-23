extends Area2D


signal reached_by

export var is_active: bool = true setget _change_activity


func _change_activity(new_acive: bool):

	is_active = new_acive

	if is_active:
		set_deferred("monitoring", true)
		show()
	else:
		set_deferred("monitoring", false)
		hide()


func _on_Checkpoint_body_entered(body: Node) -> void:

	if body.is_in_group(Rfs.group_drivers):
		emit_signal("reached_by", self, body)
