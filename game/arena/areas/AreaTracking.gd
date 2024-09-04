extends Area2D


var level_area_key: int = Pro.LEVEL_AREA.AREA_TRACKING

onready var rear_ang_damp = Pro.level_areas_profiles[level_area_key]["rear_ang_damp"]


func _on_AreaTracking_body_entered(body: Node2D) -> void:
	
	if body.is_in_group(Ref.group_bolts):
		if body.bolt_active:
#			body.side_traction = area_tracking_value
			pass
	elif body.is_in_group(Ref.group_thebolts):
		body.modulate = Color.yellow	
		body.manipulate_tracking(rear_ang_damp)


func _on_AreaTracking_body_exited(body: Node2D) -> void:
	
	if body.is_in_group(Ref.group_bolts):
#		body.side_traction = Pro.bolt_profiles[body.bolt_type]["side_traction"]
		pass
	elif body.is_in_group(Ref.group_thebolts):
		body.modulate = Color.white	
		body.manipulate_tracking(body.bolt_profile["rear_lin_damp"])
