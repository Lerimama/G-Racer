extends Node2D


signal reached_by

export var is_enabled: bool = true setget _change_enabled

onready var drive_in_position_node: Position2D = $DriveInPosition
onready var start_positions_holder: Node2D = $StartPositions
onready var start_lights: Node2D = $StartLights


func _ready() -> void:

	# hide
	drive_in_position_node.hide()
	for child in start_positions_holder.get_children():
		child.hide()

	self.is_enabled = is_enabled


func _change_enabled(new_enabled: bool):

	is_enabled = new_enabled

	if is_enabled:
		set_deferred("monitoring", true)
		show()
	else:
		set_deferred("monitoring", false)
		hide()
