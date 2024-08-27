extends Camera2D


var follow_target: Node = null setget _on_follow_target_change

var bolt_explosion_shake = 0
var bullet_hit_shake = 0.02
var misile_hit_shake = 0.05

onready var test_ui = $TestUI


func _ready():
	
	print("KAMERA")
	Ref.current_camera = self
#	position = Ref.game_manager.level_positions[0].global_position
#	zoom = Vector2.ONE * 0.5


func _process(delta: float) -> void:
	
	if follow_target:
		position = follow_target.global_position


func _on_follow_target_change(new_follow_target):
	
	set_follow_smoothing(3)
	follow_target = new_follow_target
	
	
func shake_camera(shake_power: float):
	print("shake izklopljen")
	# time, power in nivo popuščanja
	
	#	test_ui.shake_camera(shake_power) # debug
	pass
	

func set_camera_limits():
	
	var tilemap_edge: Rect2 = Ref.current_level.tilemap_edge.get_used_rect()
	
	var corner_TL: float
	var corner_TR: float
	var corner_BL: float
	var corner_BR: float
	var cell_size_x = Ref.current_level.tilemap_edge.cell_size.x
	
	# on edge tilemap
#	corner_TL = tilemap_edge.position.x * cell_size_x + cell_size_x # k mejam prištejem edge debelino
#	corner_TR = tilemap_edge.end.x * cell_size_x - cell_size_x
#	corner_BL = tilemap_edge.position.y * cell_size_x + cell_size_x
#	corner_BR = tilemap_edge.end.y * cell_size_x - cell_size_x	
	corner_TL = tilemap_edge.position.x * cell_size_x
	corner_TR = tilemap_edge.end.x * cell_size_x
	corner_BL = tilemap_edge.position.y * cell_size_x
	corner_BR = tilemap_edge.end.y * cell_size_x

	# on color square size
#	var camera_limits_rectangle: Control = Ref.current_level.camera_limits_rect
#	corner_TL = 0
#	corner_TR = camera_limits_rectangle.rect_size.x
#	corner_BL = camera_limits_rectangle.rect_size.y
#	corner_BR = camera_limits_rectangle.rect_size.y + camera_limits_rectangle.rect_size.x
	
	if limit_left <= corner_TL and limit_right <= corner_TR and limit_top <= corner_BL and limit_bottom <= corner_BR: # če so meje manjše od kamere
		return	

	limit_left = corner_TL
	limit_right = corner_TR
	limit_top = corner_BL
	limit_bottom = corner_BR
