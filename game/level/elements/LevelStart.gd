extends Node2D


signal reached_by

var is_enabled: bool = false setget _change_enabled

onready var start_lights: Node2D = $StartLights


func _ready() -> void:

	# hide
	$DriveInPosition.hide()
	self.is_enabled = is_enabled
	$StartPosition.hide()


func _change_enabled(new_enabled: bool):

	is_enabled = new_enabled

	if is_enabled:
		set_deferred("monitoring", true)
		show()
	else:
		set_deferred("monitoring", false)
		hide()
