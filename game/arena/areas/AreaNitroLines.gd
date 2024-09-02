extends Area2D


var level_area_key: int = Pro.LevelAreas.AREA_NITRO

onready var nitro_drag_div = Pro.level_areas_profiles[level_area_key]["drag_div"]


func _on_AreaNitro_body_entered(body: Node) -> void:
	
	if body.is_in_group(Ref.group_bolts):
		if body.bolt_active: # če ni aktiven se sam od sebe ustavi
			body.drag_div = nitro_drag_div
	elif body.is_in_group(Ref.group_thebolts):
		body.modulate = Color.yellow	
			
			
func _on_AreaNitro_body_exited(body: Node) -> void:
	
	if body.is_in_group(Ref.group_bolts):
		body.drag_div = Pro.bolt_profiles[body.bolt_type]["drag_div"]
	elif body.is_in_group(Ref.group_thebolts):
		body.modulate = Color.white	
