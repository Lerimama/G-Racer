extends Area2D


var level_area_key: int = Pro.LEVEL_AREA.AREA_NITRO

onready var engine_power_factor = Pro.level_areas_profiles[level_area_key]["engine_power_factor"]


func _on_AreaNitro_body_entered(body: Node2D) -> void:
	
	if body.is_in_group(Ref.group_bolts):
		if body.bolt_active: # če ni aktiven se sam od sebe ustavi
#			body.drag_div = nitro_drag_div
			pass
	elif body.is_in_group(Ref.group_thebolts):
		body.modulate = Color.yellow
		body.manipulate_engine_power(body.bolt_profile["max_engine_power"] * engine_power_factor)			
			
func _on_AreaNitro_body_exited(body: Node2D) -> void:
	
	if body.is_in_group(Ref.group_bolts):
#		body.drag_div = Pro.bolt_profiles[body.bolt_type]["drag_div"]
		pass
	elif body.is_in_group(Ref.group_thebolts):
		body.modulate = Color.white	
		body.manipulate_engine_power(body.bolt_profile["max_engine_power"])
