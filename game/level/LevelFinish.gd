extends Node2D


signal reached_by

export var is_active: bool = false setget _change_activity

onready var finish_line: Area2D = $FinishLine
onready var drive_out_position_node: Position2D = $DriveOutPosition


func _ready() -> void:

	drive_out_position_node.hide()
	self.is_active = is_active


func _change_activity(new_acive: bool):

	is_active = new_acive

	if is_active:
		finish_line.set_deferred("monitoring", true)
		show()
	else:
		finish_line.set_deferred("monitoring", false)
		hide()


func _on_FinishLine_body_entered(body: Node) -> void:

	if body.is_in_group(Rfs.group_drivers):
		emit_signal("reached_by", body)
