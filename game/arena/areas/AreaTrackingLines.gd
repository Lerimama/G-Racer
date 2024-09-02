extends Area2D


var level_area_key: int = Pro.LevelAreas.AREA_TRACKING

onready var area_tracking_value = Pro.level_areas_profiles[level_area_key]["area_tracking_value"]


func _on_AreaTracking_body_entered(body: Node) -> void:
	
	if body.is_in_group(Ref.group_bolts):
		if body.bolt_active:
			body.side_traction = area_tracking_value
	elif body.is_in_group(Ref.group_thebolts):
		body.modulate = Color.yellow	


func _on_AreaTracking_body_exited(body: Node) -> void:
	
	if body.is_in_group(Ref.group_bolts):
		body.side_traction = Pro.bolt_profiles[body.bolt_type]["side_traction"]
	elif body.is_in_group(Ref.group_thebolts):
		body.modulate = Color.white	
