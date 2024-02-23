extends Camera2D


#var is_following: bool = true
var follow_target: Node

onready var test_ui = $TestUI

func _ready():
#	print("KAMERA")
	Ref.current_camera = self
	set_camera_limits()

func _process(delta: float) -> void:
	
	if follow_target:
		position = follow_target.global_position
	
	
func shake_camera(shake_power: float):
	# time, power in nivo popuščanja
	
	test_ui.add_trauma(shake_power)
	
#	offset.x = test_ui.noise.get_noise_3d(test_ui.time * test_ui.time_scale, 0, 0) * test_ui.max_horizontal * shake_power
#	offset.y = test_ui.noise.get_noise_3d(0, test_ui.time * test_ui.time_scale, 0) * test_ui.max_vertical * shake_power
#	rotation_degrees = test_ui.noise.get_noise_3d(0, 0, test_ui.time * test_ui.time_scale) * test_ui.max_rotation * shake_power	

# limits


func set_camera_limits():
	
#	var tilemap_edge: Rect2 = Ref.current_tilemap.get_used_rect()
	var tilemap_edge: Rect2 = Ref.current_level.tilemap_edge.get_used_rect()
	
	var corner_TL: float
	var corner_TR: float
	var corner_BL: float
	var corner_BR: float
	var cell_size_x = Ref.current_level.tilemap_edge.cell_size.x
	
	corner_TL = tilemap_edge.position.x * cell_size_x + cell_size_x # k mejam prištejem edge debelino
	corner_TR = tilemap_edge.end.x * cell_size_x - cell_size_x
	corner_BL = tilemap_edge.position.y * cell_size_x + cell_size_x
	corner_BR = tilemap_edge.end.y * cell_size_x - cell_size_x
	
	if limit_left <= corner_TL and limit_right <= corner_TR and limit_top <= corner_BL and limit_bottom <= corner_BR: # če so meje manjše od kamere
		return	

	# printt("edge tile", corner_TL, corner_TR, corner_BL, corner_BR)
	# printt("limit", limit_left, limit_right, limit_top, limit_bottom)
	limit_left = corner_TL
	limit_right = corner_TR
	limit_top = corner_BL
	limit_bottom = corner_BR
	
