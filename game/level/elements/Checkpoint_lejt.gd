extends Area2D


signal reached_by

var is_enabled: bool = false setget _change_enabled # is enabled se opredeli, če je povezan v level goals


func _change_enabled(new_enabled: bool):

	is_enabled = new_enabled

	if is_enabled:
		set_deferred("monitoring", true)
		show()
	else:
		set_deferred("monitoring", false)
		hide()


func _on_Checkpoint_body_entered(body: Node) -> void:

	if body.is_in_group(Refs.group_drivers):
		emit_signal("reached_by", self, body)
