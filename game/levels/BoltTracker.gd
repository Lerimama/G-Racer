extends PathFollow2D


var tracking_target: Object = null


func _physics_process(delta: float) -> void:

	if tracking_target:
		if Set.kamera_frcera:
			printt("FPS", Engine.get_physics_frames(), self.name) # _temp	
		var racing_curve: Curve2D = get_parent().get_curve()
		var target_offset: float = racing_curve.get_closest_offset(tracking_target.global_position)
		offset = target_offset

	
