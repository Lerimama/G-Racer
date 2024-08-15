extends PathFollow2D


var follower_target: Object = null

func _physics_process(delta: float) -> void:
	
	if follower_target:
		var racing_curve: Curve2D = get_parent().get_curve()
		var target_offset: float = racing_curve.get_closest_offset(follower_target.global_position)
		offset = target_offset
