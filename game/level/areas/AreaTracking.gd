extends Area2D


var level_area_key: int = Pro.LEVEL_AREA.AREA_TRACKING

onready var rear_ang_damp = Pro.level_areas_profiles[level_area_key]["rear_ang_damp"]


func _on_AreaTracking_body_entered(body: Node) -> void:
	
	if body.is_in_group(Ref.group_bolts):
		body.manipulate_tracking(rear_ang_damp)


func _on_AreaTracking_body_exited(body: Node) -> void:
	
	if body.is_in_group(Ref.group_bolts):
		body.manipulate_tracking(body.bolt_profile["drive_lin_damp_rear"])
