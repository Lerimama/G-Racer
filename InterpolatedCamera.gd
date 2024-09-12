extends InterpolatedCamera

var follow_target: Node2D setget _on_follow_target_change



func _ready() -> void:
	
	print("3D KAMERA")
	Ref.current_3Dcamera = self


func _process(delta: float) -> void:
	
	pass
#	if follow_target:
#		interpolated_camera.set_target(target_follow)
##		camera.translation = Vector3(Ref.current_camera.follow_target.position.x - 200- 8.226, Ref.current_camera.follow_target.position.y - 250 +34, 7)
#
#		if interpolated_camera.get_target_path() == "":
#			print("je", interpolated_camera.target)
#	else:
#		if not interpolated_camera.get_target_path().is_empty():
#			interpolated_camera.set_target(null)
#		interpolated_camera


func _on_follow_target_change(new_target: Node2D):
	
	set_target(new_target)
	
