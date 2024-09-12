extends Spatial


var target_origin_translation: Vector3
var target_offset: Vector2 = Vector2.ZERO
var follow_enabled: bool =  false # setget _on_folow_change
var follow_target: Node2D

onready var camera: Camera = $Camera
onready var interpolated_camera: InterpolatedCamera = $InterpolatedCamera
onready var target_follow: Spatial = $TargetFollow



func _ready() -> void:
	
	Ref.current_3Dworld = self
	
	

func _process(delta: float) -> void:
	
	if follow_target:
		print(follow_target)
		var factor = 0.0165
		target_follow.translation.z = follow_target.get_camera_screen_center().x - target_offset.x# - Ref.current_level.viewport_container.rec_position.x
		target_follow.translation.z *= -factor
		target_follow.translation.x = follow_target.get_camera_screen_center().y - target_offset.y# + Ref.current_level.viewport_container.rec_position.Y
		target_follow.translation.x *= factor
		

func change_follow_target(new_target: Node2D):
	
	new_target = Ref.current_camera
	var target_offset_from_zero: Vector2 = new_target.get_camera_screen_center()
	target_offset = target_offset_from_zero
	follow_target = Ref.current_camera
	
	
func _on_folow_change(is_following: bool):
	
#	follow_enabled = is_following
	pass
