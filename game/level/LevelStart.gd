extends Node2D


signal reached_by

export var is_active: bool = true setget _change_activity

onready var drive_in_position_node: Position2D = $DriveInPosition
onready var camera_position_node: Position2D = $CameraPosition
onready var start_positions_holder: Node2D = $StartPositions
onready var start_lights: Node2D = $StartLights


func _ready() -> void:

	# hide
	camera_position_node.hide()
	drive_in_position_node.hide()
	for child in start_positions_holder.get_children():
		child.hide()

	self.is_active = is_active


func _change_activity(new_acive: bool):

	is_active = new_acive

	if is_active:
		set_deferred("monitoring", true)
		show()
	else:
		set_deferred("monitoring", false)
		hide()
