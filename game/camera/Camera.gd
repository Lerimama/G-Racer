extends Camera2D


var is_following: bool = true
var follow_target: Node

onready var test_ui = $TestUI

func _ready():
#	print("KAMERA")
	Ref.current_camera = self


func _process(delta: float) -> void:
	
	if follow_target:
		position = follow_target.global_position
	
	
func shake_camera(shake_power: float):
	# time, power in nivo popuščanja
	
	test_ui.add_trauma(shake_power)
	
#	offset.x = test_ui.noise.get_noise_3d(test_ui.time * test_ui.time_scale, 0, 0) * test_ui.max_horizontal * shake_power
#	offset.y = test_ui.noise.get_noise_3d(0, test_ui.time * test_ui.time_scale, 0) * test_ui.max_vertical * shake_power
#	rotation_degrees = test_ui.noise.get_noise_3d(0, 0, test_ui.time * test_ui.time_scale) * test_ui.max_rotation * shake_power	
