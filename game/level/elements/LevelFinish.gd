extends Node2D


signal reached_by

var is_enabled: bool = false setget _change_enabled

onready var drive_out_position_2d: Position2D = $DriveOutPosition


func _ready() -> void:

	drive_out_position_2d.hide()
	self.is_enabled = is_enabled
#	if is_enabled:
#		$FinishArea.set_deferred("monitoring", true)
#		show()
#	else:
#		$FinishArea.set_deferred("monitoring", false)
#		hide()


func _change_enabled(new_enabled: bool):

	is_enabled = new_enabled

	if is_enabled:
		$FinishArea.set_deferred("monitoring", true)
		show()
	else:
		$FinishArea.set_deferred("monitoring", false)
		hide()


func _on_FinishLine_body_entered(body: Node) -> void:

	if body.is_in_group(Refs.group_drivers):
		emit_signal("reached_by", body)
