extends Area2D


var level_area_key: int = Pro.LEVEL_AREA.AREA_GRAVEL

onready var engine_power_factor = Pro.level_areas_profiles[level_area_key]["engine_power_factor"]


func _on_AreaGravel_body_entered(body: Node) -> void:
	
	if body.is_in_group(Ref.group_bolts):
		body.manipulate_engine_power(body.bolt_profile["max_engine_power"] * engine_power_factor)


func _on_AreaGravel_body_exited(body: Node) -> void:
	
	if body.is_in_group(Ref.group_bolts):
		body.manipulate_engine_power(body.bolt_profile["max_engine_power"])
